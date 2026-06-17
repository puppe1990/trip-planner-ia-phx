defmodule TripPlannerIa.MapPoints do
  @moduledoc false

  @slot_order %{"Manhã" => 1, "Tarde" => 2, "Gastronomia" => 3, "Noite" => 4}

  def deterministic_hash(str) when is_binary(str) do
    str
    |> String.to_charlist()
    |> Enum.reduce(0, fn char, hash ->
      abs(char + Bitwise.bsl(hash, 5) - hash)
    end)
  end

  def build_map_points(trip_plan) do
    dest_hash = deterministic_hash(trip_plan.destination)
    base_lat = -12.0 + rem(dest_hash, 30)
    base_lng = -48.0 + rem(Bitwise.bsr(dest_hash, 3), 40)

    points =
      Enum.flat_map(trip_plan.days, fn day ->
        slots = [
          {day.morning, "Manhã", 0, 0},
          {day.afternoon, "Tarde", 0.015, -0.012},
          {day.evening, "Noite", -0.018, 0.022},
          {dining_slot(day.dining_spot), "Gastronomia", 0.005, 0.005}
        ]

        Enum.map(slots, fn {activity, slot, lat_off, lng_off} ->
          h = deterministic_hash(activity.title)

          %{
            id: "day-#{day.day_number}-#{String.downcase(slot)}",
            day_number: day.day_number,
            time_slot: slot,
            title: activity.title,
            description: activity.description,
            lat: base_lat + 0.045 * (day.day_number - 1) + lat_off + (rem(h, 100) - 50) / 1500,
            lng:
              base_lng + 0.055 * (day.day_number - 1) + lng_off +
                (rem(Bitwise.bsr(h, 2), 100) - 50) / 1500,
            x: 0,
            y: 0,
            cost: activity.cost,
            duration: activity.duration
          }
        end)
      end)

    project_points(points)
  end

  def sort_points_chronologically(points) do
    Enum.sort_by(points, fn p ->
      {p.day_number, Map.get(@slot_order, p.time_slot, 99)}
    end)
  end

  def build_routes_path(points) when length(points) < 2, do: ""

  def build_routes_path(points) do
    sorted = sort_points_chronologically(points)

    {path, _} =
      Enum.reduce(Enum.with_index(sorted), {"", nil}, fn {point, index}, {acc, prev} ->
        cond do
          index == 0 ->
            {"M #{point.x} #{point.y}", point}

          true ->
            cx1 = prev.x + (point.x - prev.x) / 2
            cy1 = prev.y
            cx2 = prev.x + (point.x - prev.x) / 2
            cy2 = point.y

            segment = " C #{cx1} #{cy1}, #{cx2} #{cy2}, #{point.x} #{point.y}"
            {acc <> segment, point}
        end
      end)

    path
  end

  defp dining_slot(dining) do
    %{
      title: dining.name,
      description: "#{dining.type} - #{dining.description}",
      cost: dining.price_level,
      duration: "1-2 horas"
    }
  end

  defp project_points(points) do
    min_lat = points |> Enum.map(& &1.lat) |> Enum.min()
    max_lat = points |> Enum.map(& &1.lat) |> Enum.max()
    min_lng = points |> Enum.map(& &1.lng) |> Enum.min()
    max_lng = points |> Enum.map(& &1.lng) |> Enum.max()

    {min_lat, max_lat} =
      if min_lat == max_lat, do: {min_lat - 0.01, max_lat + 0.01}, else: {min_lat, max_lat}

    {min_lng, max_lng} =
      if min_lng == max_lng, do: {min_lng - 0.01, max_lng + 0.01}, else: {min_lng, max_lng}

    width = 700
    height = 450
    padding = 60

    Enum.map(points, fn p ->
      x_norm = (p.lng - min_lng) / (max_lng - min_lng)
      y_norm = (p.lat - min_lat) / (max_lat - min_lat)

      %{
        p
        | x: padding + x_norm * (width - 2 * padding),
          y: height - (padding + y_norm * (height - 2 * padding))
      }
    end)
  end
end
