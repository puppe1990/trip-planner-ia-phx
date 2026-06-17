defmodule TripPlannerIa.BudgetTest do
  use ExUnit.Case, async: true

  alias TripPlannerIa.Budget
  alias TripPlannerIa.Fixtures

  describe "parse_cost/1" do
    test "extracts numeric value from Brazilian currency string" do
      assert Budget.parse_cost("R$ 1.500") == 1500
    end

    test "returns 0 for empty string" do
      assert Budget.parse_cost("") == 0
    end

    test "extracts first number from free text" do
      assert Budget.parse_cost("Grátis ou R$ 80") == 80
    end
  end

  describe "calculate_group_budget/2" do
    test "calculates group totals for multiple travelers" do
      plan = Fixtures.budget_trip_plan()
      result = Budget.calculate_group_budget(plan, 3)

      assert result.double_rooms == 2
      assert result.hotel_group == 300 * 2 * 4
      assert result.food_group == 150 * 3 * 4
      assert result.transport_group == 50 * 3 * 4
      assert result.total == result.hotel_group + result.food_group + result.transport_group
    end

    test "uses one double room for solo traveler" do
      plan = Fixtures.budget_trip_plan()
      result = Budget.calculate_group_budget(plan, 1)

      assert result.double_rooms == 1
      assert result.hotel_group == 300 * 4
    end
  end
end
