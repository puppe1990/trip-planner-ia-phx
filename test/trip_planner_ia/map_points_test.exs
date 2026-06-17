defmodule TripPlannerIa.MapPointsTest do
  use ExUnit.Case, async: true

  alias TripPlannerIa.Fixtures
  alias TripPlannerIa.MapPoints

  test "generates deterministic hash for same input" do
    assert MapPoints.deterministic_hash("test") == MapPoints.deterministic_hash("test")
    assert MapPoints.deterministic_hash("a") != MapPoints.deterministic_hash("b")
  end

  test "builds projected map points for all days and slots" do
    points = MapPoints.build_map_points(Fixtures.map_trip_plan())

    assert length(points) == 8
    assert Enum.all?(points, fn p -> p.x > 0 and p.y > 0 end)
  end

  test "sorts points chronologically and builds route path" do
    points = MapPoints.build_map_points(Fixtures.map_trip_plan())
    day1 = Enum.filter(points, &(&1.day_number == 1))
    sorted = MapPoints.sort_points_chronologically(day1)

    assert hd(sorted).time_slot == "Manhã"
    assert List.last(sorted).time_slot == "Noite"

    path = MapPoints.build_routes_path(day1)
    assert String.starts_with?(path, "M ")
    assert String.contains?(path, "C ")
  end
end
