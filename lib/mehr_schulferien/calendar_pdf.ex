defmodule MehrSchulferien.CalendarPdf do
  @moduledoc """
  Printable year calendars as PDF files, for a federal state or a school.

  A calendar is rendered to LaTeX on every request, which is cheap. The file
  name carries a hash of that source, so a stored PDF is served as long as the
  dates, the address and the template are unchanged, and pdflatex only runs
  when one of them moved. State calendars are generated ahead of time by
  `MehrSchulferien.CalendarPdf.Warmer`, school calendars on their first
  request.

  A scope is `{:federal_state, %{country: _, federal_state: _}}` or
  `{:school, %{country: _, federal_state: _, county: _, city: _, school: _}}`.
  """

  import Ecto.Query, only: [from: 2]

  require Logger

  alias MehrSchulferien.Blacklist
  alias MehrSchulferien.CalendarPdf.{Generator, Latex, Store}
  alias MehrSchulferien.Locations.Location
  alias MehrSchulferien.{Periods, Repo, UrlBuilder}

  @formats ~w(a3 a4 a5 karte)

  # How far ahead calendars are offered, counted from the current year.
  @years_ahead 2

  # From this month on people print next year's calendar.
  @next_year_from_month 10

  defstruct [
    :year,
    :title,
    :subtitle,
    :url,
    :homepage,
    address_lines: [],
    vacations: [],
    holidays: [],
    flexible_days: [],
    days: %{}
  ]

  @doc "The downloadable formats, as they appear in the URL."
  def formats, do: @formats

  @doc """
  Whether calendars of `year` are offered on `today`: the current year and
  the two after it. Whether one exists is then a matter of the data, see
  `build/2`.
  """
  def offered_year?(year, %Date{year: current_year}) do
    year in current_year..(current_year + @years_ahead)
  end

  @doc """
  Narrows the years in which school vacations start to the ones a calendar is
  offered for. Pages that already know those years link with this.
  """
  def offered_years(vacation_years, %Date{} = today) do
    vacation_years |> Enum.filter(&offered_year?(&1, today)) |> Enum.uniq() |> Enum.sort()
  end

  @doc """
  The year out of `offered` to show first. A calendar is printed for the year
  ahead: from October on that is the next year, before it the running one.
  """
  def suggested_year(offered, %Date{year: current_year, month: month}) do
    if month >= @next_year_from_month and (current_year + 1) in offered do
      current_year + 1
    else
      List.first(offered)
    end
  end

  @doc "The years a calendar is offered for, read from the database."
  def years(scope, %Date{year: current_year} = today) do
    scope
    |> location_ids()
    |> Periods.list_school_vacation_periods(
      Date.new!(current_year, 1, 1),
      Date.new!(current_year + @years_ahead, 12, 31)
    )
    |> Enum.map(& &1.starts_on.year)
    |> offered_years(today)
  end

  @doc """
  Collects what the calendar of `year` shows. Returns `{:ok, calendar}`, or
  `{:error, :no_data}` when no school vacation starts in that year.
  """
  def build(scope, year) when is_integer(year) do
    first = Date.new!(year, 1, 1)
    last = Date.new!(year, 12, 31)
    location_ids = location_ids(scope)

    flexible_periods = flexible_periods(scope, first, last)
    flexible_ids = MapSet.new(flexible_periods, & &1.id)

    vacation_periods =
      location_ids
      |> Periods.list_school_vacation_periods(first, last)
      |> Enum.reject(&(&1.id in flexible_ids))

    if Enum.any?(vacation_periods, &(&1.starts_on.year == year)) do
      vacations = entries(vacation_periods)
      holidays = location_ids |> Periods.list_public_periods(first, last) |> entries()
      flexible_days = entries(flexible_periods)

      calendar =
        scope
        |> describe(year)
        |> Map.merge(%{
          year: year,
          vacations: vacations,
          holidays: holidays,
          flexible_days: flexible_days,
          days: days(first, last, vacations, holidays, flexible_days)
        })

      {:ok, calendar}
    else
      {:error, :no_data}
    end
  end

  @doc """
  Returns the path of the stored PDF, generating it first if it is missing.

  Errors: `:unknown_format`, `:no_data`, `:busy` when too many PDFs are
  waiting to be generated, or the reason pdflatex failed with.
  """
  def fetch(scope, year, format) do
    with {:ok, path, _status} <- fetch_with_status(scope, year, format, :shed) do
      {:ok, path}
    end
  end

  @doc """
  Generates every missing state calendar and returns how many were written.

  Safe to call at any time and to interrupt: what exists is skipped, so the
  next run picks up where a killed one stopped. It also clears out the store:
  calendars of past years and what a killed generator left behind.
  """
  def warm(%Date{} = today) do
    Store.sweep(today.year)

    if Generator.compiler().available?() do
      for scope <- federal_state_scopes(),
          year <- years(scope, today),
          format <- @formats,
          reduce: 0 do
        generated -> generated + warm_one(scope, year, format)
      end
    else
      0
    end
  end

  defp warm_one(scope, year, format) do
    case fetch_with_status(scope, year, format, :wait) do
      {:ok, _path, :generated} ->
        1

      {:ok, _path, :stored} ->
        0

      {:error, reason} ->
        Logger.error(
          "Calendar PDF #{scope_key(scope)} #{year} #{format} failed: #{inspect(reason)}"
        )

        0
    end
  end

  defp fetch_with_status(scope, year, format, queueing) do
    with :ok <- check_format(format),
         {:ok, calendar} <- build(scope, year) do
      latex = Latex.render(calendar, format)
      path = Store.path(scope_key(scope), year, format, latex)

      if File.exists?(path) do
        {:ok, path, :stored}
      else
        Generator.generate(path, latex, queueing)
      end
    end
  end

  defp check_format(format) when format in @formats, do: :ok
  defp check_format(_format), do: {:error, :unknown_format}

  defp federal_state_scopes do
    Repo.all(
      from state in Location,
        join: country in Location,
        on: state.parent_location_id == country.id,
        where: state.is_federal_state == true and country.is_country == true,
        order_by: state.slug,
        select: {country, state}
    )
    |> Enum.map(fn {country, state} ->
      {:federal_state, %{country: country, federal_state: state}}
    end)
  end

  defp location_ids({:federal_state, %{country: country, federal_state: federal_state}}) do
    [country.id, federal_state.id]
  end

  defp location_ids({:school, locations}) do
    Enum.map([:country, :federal_state, :county, :city, :school], &Map.fetch!(locations, &1).id)
  end

  defp scope_key({:federal_state, %{federal_state: federal_state}}) do
    "bundesland-#{federal_state.slug}"
  end

  defp scope_key({:school, %{school: school}}), do: "schule-#{school.slug}"

  defp flexible_periods({:school, %{school: school}}, first, last) do
    Periods.list_bewegliche_ferientage_for_school_in_range(school.id, first, last)
  end

  defp flexible_periods(_scope, _first, _last), do: []

  defp describe({:federal_state, %{country: country, federal_state: federal_state}}, year) do
    %__MODULE__{
      title: "Schulferien #{federal_state.name} #{year}",
      url: UrlBuilder.federal_state_url(country.slug, federal_state, year)
    }
  end

  defp describe({:school, %{country: country, school: school}}, year) do
    %__MODULE__{
      title: "Schulferien #{year}",
      subtitle: school.name,
      url: UrlBuilder.school_url(country.slug, school)
    }
    |> Map.merge(contact(school))
  end

  # Street, town and the school's own website, minus what is blacklisted.
  defp contact(%{address: %{} = address}) do
    address = Blacklist.filter_address(address)

    %{
      address_lines:
        present([address.street, Enum.join(present([address.zip_code, address.city]), " ")]),
      homepage: address.homepage_url
    }
  end

  defp contact(_school), do: %{}

  defp present(values), do: Enum.reject(values, &(&1 in [nil, ""]))

  defp entries(periods) do
    periods
    |> Enum.map(fn period ->
      type = period.holiday_or_vacation_type
      %{name: type.colloquial || type.name, starts_on: period.starts_on, ends_on: period.ends_on}
    end)
    |> Enum.sort_by(&{Date.to_erl(&1.starts_on), &1.name})
  end

  # One entry per day of the year. A public holiday wins over a beweglicher
  # Ferientag, that over a vacation, that over the weekend.
  defp days(first, last, vacations, holidays, flexible_days) do
    lookup =
      %{}
      |> put_days(vacations, :vacation, first, last)
      |> put_days(flexible_days, :flexible, first, last)
      |> put_days(holidays, :holiday, first, last)

    Map.new(Date.range(first, last), fn date ->
      {date, Map.get_lazy(lookup, date, fn -> plain_day(date) end)}
    end)
  end

  defp put_days(lookup, entries, kind, first, last) do
    for entry <- entries, reduce: lookup do
      lookup ->
        starts_on = Enum.max([entry.starts_on, first], Date)
        ends_on = Enum.min([entry.ends_on, last], Date)

        for date <- Date.range(starts_on, ends_on), reduce: lookup do
          lookup ->
            Map.put(lookup, date, %{kind: kind, label: label(kind, entry, date, starts_on)})
        end
    end
  end

  # A vacation is named on its first day and again at the top of each month.
  defp label(:vacation, entry, date, starts_on) do
    if date == starts_on or date.day == 1, do: entry.name
  end

  defp label(_kind, entry, _date, _starts_on), do: entry.name

  defp plain_day(date) do
    kind = if Date.day_of_week(date) > 5, do: :weekend, else: :school
    %{kind: kind, label: nil}
  end
end
