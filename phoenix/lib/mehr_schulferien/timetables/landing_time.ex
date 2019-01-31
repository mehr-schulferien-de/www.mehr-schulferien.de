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

  def list_week_of_year(start_day, end_day) do
    start_year = start_day.year
    end_year = end_day.year
    list_week = list_week(start_day, end_day)

    if start_year == end_year do
      year_string = start_year |> Integer.to_string
      for week <- list_week do
        week_string = week |> Integer.to_string
        year_string<>"-"<>week_string
      end     
    else
      start_year_string = start_year |> Integer.to_string
      end_year_string = end_year |> Integer.to_string
      for week <- list_week do
        if week >= 26 do
          week_string1 = week |> Integer.to_string
          start_year_string<>"-"<>week_string1
        else
          week_string2 = week |> Integer.to_string
          end_year_string<>"-"<>week_string2
        end  
      end  
    end
    #IO.puts("start_year_string = #{start_year_string}, end_year_string = #{end_year_string}")

  end

  def date_week(one_day) do
    {:ok, new_year} = Date.new(one_day.year, 1, 1)
    new_year
    |> Date.diff(one_day)
    |> div(7)
    |> abs
    |> Kernel.+(1)
  end

  def list_week(start_day, end_day) do
    start_week = date_week(start_day)
    end_week = date_week(end_day)
    case start_week <= end_week do
      true ->
        Enum.to_list(start_week..end_week)
      false ->
        Enum.to_list(start_week..52) ++ Enum.to_list(1..end_week)
    end 
  end

  def best_bridge_week_list(best_bridge_days) do
    for best_bridge_day <- best_bridge_days do
      start_day = List.first(best_bridge_day[:bridge_days])
      end_day = Date.add(start_day, best_bridge_day[:bridge_day_vacation_length])
      list_week_of_year(start_day, end_day)
    end
  end

end
