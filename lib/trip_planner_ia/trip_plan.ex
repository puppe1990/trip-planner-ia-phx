defmodule TripPlannerIa.TripPlan do
  @moduledoc false

  @string_to_atom %{
    "id" => :id,
    "destination" => :destination,
    "duration_days" => :duration_days,
    "tagline" => :tagline,
    "summary" => :summary,
    "budget_estimate" => :budget_estimate,
    "packing_essentials" => :packing_essentials,
    "weather_expected" => :weather_expected,
    "days" => :days,
    "tips" => :tips,
    "created_at" => :created_at,
    "budget_preference" => :budget_preference,
    "style_preference" => :style_preference,
    "companion_preference" => :companion_preference,
    "day_number" => :day_number,
    "theme" => :theme,
    "morning" => :morning,
    "afternoon" => :afternoon,
    "evening" => :evening,
    "dining_spot" => :dining_spot,
    "title" => :title,
    "description" => :description,
    "cost" => :cost,
    "duration" => :duration,
    "name" => :name,
    "type" => :type,
    "price_level" => :price_level,
    "category" => :category,
    "text" => :text,
    "total_cost_estimate" => :total_cost_estimate,
    "hotel_average_night" => :hotel_average_night,
    "food_average_day" => :food_average_day,
    "transport_average_day" => :transport_average_day
  }

  def to_atoms(plan) when is_map(plan) do
    plan
    |> stringify_keys()
    |> deep_atomize()
  end

  def from_atoms(plan) when is_map(plan) do
    plan
    |> deep_stringify()
  end

  defp deep_atomize(map) when is_map(map) do
    Map.new(map, fn {key, value} ->
      atom_key = Map.get(@string_to_atom, to_string(key), safe_atom(key))
      {atom_key, deep_atomize_value(value)}
    end)
  end

  defp deep_atomize_value(list) when is_list(list), do: Enum.map(list, &deep_atomize_value/1)
  defp deep_atomize_value(map) when is_map(map), do: deep_atomize(map)
  defp deep_atomize_value(value), do: value

  defp deep_stringify(map) when is_map(map) do
    Map.new(map, fn {key, value} ->
      {Atom.to_string(key), deep_stringify_value(value)}
    end)
  end

  defp deep_stringify_value(list) when is_list(list), do: Enum.map(list, &deep_stringify_value/1)
  defp deep_stringify_value(map) when is_map(map), do: deep_stringify(map)
  defp deep_stringify_value(value), do: value

  defp stringify_keys(map) when is_map(map) do
    Map.new(map, fn
      {key, value} when is_atom(key) -> {Atom.to_string(key), stringify_keys(value)}
      {key, value} -> {key, stringify_keys(value)}
    end)
  end

  defp stringify_keys(value), do: value

  defp safe_atom(key) when is_atom(key), do: key

  defp safe_atom(key) do
    String.to_existing_atom(key)
  rescue
    ArgumentError -> String.to_atom(key)
  end
end
