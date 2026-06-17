defmodule TripPlannerIa.TripPlannerConfigTest do
  use ExUnit.Case, async: true

  alias TripPlannerIa.TripPlannerConfig

  setup do
    on_exit(fn ->
      System.delete_env("TRIP_PLANNER_MULTI_STEP")
    end)

    :ok
  end

  test "defaults to true when TRIP_PLANNER_MULTI_STEP is unset" do
    System.delete_env("TRIP_PLANNER_MULTI_STEP")
    assert TripPlannerConfig.multi_step_enabled?() == true
  end

  test "returns true when TRIP_PLANNER_MULTI_STEP is true" do
    System.put_env("TRIP_PLANNER_MULTI_STEP", "true")
    assert TripPlannerConfig.multi_step_enabled?() == true
  end

  test "returns false when TRIP_PLANNER_MULTI_STEP is false" do
    System.put_env("TRIP_PLANNER_MULTI_STEP", "false")
    assert TripPlannerConfig.multi_step_enabled?() == false
  end
end
