defmodule TripPlannerIa.PlannerSchemaTest do
  use ExUnit.Case, async: true

  alias TripPlannerIa.PlannerSchema

  @valid_planner_result %{
    "destination" => "Tokyo, Japan",
    "durationDays" => 5,
    "tagline" => "Future meets tradition",
    "summary" => "Amazing trip",
    "budgetEstimate" => %{
      "totalCostEstimate" => "$2000",
      "hotelAverageNight" => "$100",
      "foodAverageDay" => "$50",
      "transportAverageDay" => "$20"
    },
    "packingEssentials" => ["Comfortable shoes"],
    "weatherExpected" => "Mild spring",
    "days" => [
      %{
        "dayNumber" => 1,
        "theme" => "Arrival",
        "morning" => %{"title" => "A", "description" => "B", "cost" => "C", "duration" => "D"},
        "afternoon" => %{"title" => "A", "description" => "B", "cost" => "C", "duration" => "D"},
        "evening" => %{"title" => "A", "description" => "B", "cost" => "C", "duration" => "D"},
        "diningSpot" => %{
          "name" => "N",
          "type" => "T",
          "priceLevel" => "$$",
          "description" => "D"
        }
      }
    ],
    "tips" => [%{"category" => "Transport", "text" => "Get a metro pass"}]
  }

  describe "parse_result/2" do
    test "accepts a valid planner JSON payload" do
      result = PlannerSchema.parse_result(Jason.encode!(@valid_planner_result))

      assert result.destination == "Tokyo, Japan"
      assert result.duration_days == 5
      assert length(result.days) == 1
      assert hd(result.days).day_number == 1
      assert hd(result.days).dining_spot.price_level == "$$"
    end

    test "fills missing destination and duration from context" do
      incomplete = Map.drop(@valid_planner_result, ["destination", "durationDays"])

      result =
        PlannerSchema.parse_result(Jason.encode!(incomplete), %{
          destination: "Paris, France",
          duration_days: 4
        })

      assert result.destination == "Paris, France"
      assert result.duration_days == 4
    end

    test "parses JSON wrapped in markdown fences" do
      fenced = """
      ```json
      #{Jason.encode!(@valid_planner_result)}
      ```
      """

      assert PlannerSchema.extract_json_payload(fenced) == @valid_planner_result
    end

    test "unwraps nested trip payloads" do
      wrapped = %{
        "trip" => Map.drop(@valid_planner_result, ["destination", "durationDays"])
      }

      normalized =
        PlannerSchema.normalize_planner_payload(wrapped, %{
          destination: "Lisbon, Portugal",
          duration_days: 3
        })

      assert normalized["destination"] == "Lisbon, Portugal"
      assert normalized["durationDays"] == 3
    end

    test "rejects incomplete planner JSON with a descriptive error" do
      incomplete = %{"destination" => "Paris"}

      assert_raise RuntimeError, ~r/Invalid planner JSON/i, fn ->
        PlannerSchema.parse_result(Jason.encode!(incomplete))
      end
    end
  end

  describe "parse_outline/2" do
    test "parses outline fields with snake_case atoms" do
      outline_payload = Map.drop(@valid_planner_result, ["days", "tips"])
      outline = PlannerSchema.parse_outline(Jason.encode!(outline_payload))

      assert outline.budget_estimate.total_cost_estimate == "$2000"
      assert outline.packing_essentials == ["Comfortable shoes"]
      assert outline.weather_expected == "Mild spring"
    end
  end

  describe "parse_day/2" do
    test "parses a single day and validates day number" do
      day_payload = hd(@valid_planner_result["days"])
      day = PlannerSchema.parse_day(Jason.encode!(day_payload), 1)

      assert day.theme == "Arrival"
      assert day.morning.title == "A"
    end

    test "raises when day number does not match" do
      day_payload = hd(@valid_planner_result["days"])

      assert_raise RuntimeError, ~r/expected 2, received 1/, fn ->
        PlannerSchema.parse_day(Jason.encode!(day_payload), 2)
      end
    end
  end

  describe "parse_tips/1" do
    test "parses tips array" do
      tips = PlannerSchema.parse_tips(Jason.encode!(%{"tips" => @valid_planner_result["tips"]}))

      assert tips == [%{category: "Transport", text: "Get a metro pass"}]
    end
  end
end