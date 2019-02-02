defmodule MehrSchulferien.Timetables.LandingTime do
    
  def landing_start_date do
    {date_erl, {_, _, _}} = :calendar.local_time()
    {:ok, date_now} = Date.from_erl(date_erl)

    {:ok, landing_date} = Date.to_iso8601(date_now) 
    |> String.split("-")
    |> List.replace_at(2, "01")
    |> Enum.join("-")

    |> Date.from_iso8601

    landing_date
  end

  def landing_end_date do
    landing_date = MehrSchulferien.Timetables.LandingTime.landing_start_date
    cond do
      rem((landing_date.year),4) == 0 and (landing_date.month < 3) ->
        Date.add(landing_date, 365)
      rem((landing_date.year+1),4) == 0 and (landing_date.month >= 3) ->
        Date.add(landing_date, 365)
      true ->
        Date.add(landing_date, 364)
    end 
  end

end
