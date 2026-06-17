defmodule TripPlannerIa.IcsExport do
  @moduledoc false

  def generate(trip_plan, start_date) when is_binary(start_date) do
    case Date.from_iso8601(start_date) do
      {:ok, base_date} -> build_ics(trip_plan, base_date)
      _ -> nil
    end
  end

  defp build_ics(trip_plan, base_date) do
    now_string =
      DateTime.utc_now()
      |> DateTime.to_iso8601()
      |> String.replace(~r/[-:]/, "")
      |> String.split(".")
      |> hd()
      |> Kernel.<>("Z")

    trip_id = Map.get(trip_plan, :id, "temp")

    header = [
      "BEGIN:VCALENDAR",
      "VERSION:2.0",
      "PRODID:-//AI Trip Planner//Roteiro de Viagem//PT",
      "CALSCALE:GREGORIAN",
      "METHOD:PUBLISH"
    ]

    events =
      Enum.flat_map(Enum.with_index(trip_plan.days), fn {day, index} ->
        event_date = Date.add(base_date, index)

        [
          {day.morning, {9, 0}, {12, 0}, "Manhã"},
          {dining_activity(day.dining_spot), {13, 0}, {14, 30}, "Almoço"},
          {day.afternoon, {15, 0}, {18, 0}, "Tarde"},
          {day.evening, {20, 0}, {23, 0}, "Noite"}
        ]
        |> Enum.map(fn {activity, start_t, end_t, label} ->
          [
            "BEGIN:VEVENT",
            "UID:trip-#{trip_id}-day-#{day.day_number}-#{label_slug(label)}@trip-planner",
            "DTSTAMP:#{now_string}",
            "DTSTART:#{format_time(event_date, start_t)}",
            "DTEND:#{format_time(event_date, end_t)}",
            "SUMMARY:#{escape_text("[Dia #{day.day_number}] #{day.theme} - #{label}: #{activity.title}")}",
            "DESCRIPTION:#{escape_text(activity.description)}",
            "LOCATION:#{escape_text(trip_plan.destination)}",
            "END:VEVENT"
          ]
        end)
      end)

    (header ++ List.flatten(events) ++ ["END:VCALENDAR"])
    |> Enum.join("\r\n")
  end

  defp dining_activity(dining) do
    %{
      title: dining.name,
      description: dining.description,
      cost: dining.price_level,
      duration: ""
    }
  end

  defp label_slug("Manhã"), do: "morning"
  defp label_slug("Almoço"), do: "dine"
  defp label_slug("Tarde"), do: "afternoon"
  defp label_slug("Noite"), do: "evening"

  defp format_time(date, {h, m}) do
    y = date.year
    mo = date.month |> Integer.to_string() |> String.pad_leading(2, "0")
    d = date.day |> Integer.to_string() |> String.pad_leading(2, "0")
    hh = h |> Integer.to_string() |> String.pad_leading(2, "0")
    mm = m |> Integer.to_string() |> String.pad_leading(2, "0")
    "#{y}#{mo}#{d}T#{hh}#{mm}00"
  end

  defp escape_text(str) when is_binary(str) do
    str
    |> String.replace("\\", "\\\\")
    |> String.replace(";", "\\;")
    |> String.replace(",", "\\,")
    |> String.replace("\n", "\\n")
    |> String.replace("\r", "")
  end

  defp escape_text(_), do: ""
end