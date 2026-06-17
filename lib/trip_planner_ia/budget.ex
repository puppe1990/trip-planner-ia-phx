defmodule TripPlannerIa.Budget do
  @moduledoc false

  def parse_cost(cost_str) when cost_str in [nil, ""], do: 0

  def parse_cost(cost_str) do
    cost_str
    |> String.replace(".", "")
    |> then(fn s ->
      case Regex.run(~r/\d+/, s) do
        [num] -> String.to_integer(num)
        _ -> 0
      end
    end)
  end

  def calculate_group_budget(trip_plan, travelers_count) do
    budget = trip_plan.budget_estimate

    hotel_base = parse_cost(budget.hotel_average_night)
    food_base = parse_cost(budget.food_average_day)
    transport_base = parse_cost(budget.transport_average_day)
    double_rooms = ceil(travelers_count / 2)
    duration = trip_plan.duration_days

    hotel_group = hotel_base * double_rooms * duration
    food_group = food_base * travelers_count * duration
    transport_group = transport_base * travelers_count * duration

    %{
      hotel_group: hotel_group,
      food_group: food_group,
      transport_group: transport_group,
      total: hotel_group + food_group + transport_group,
      double_rooms: double_rooms
    }
  end
end