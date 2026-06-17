defmodule TripPlannerIa.TransitParseTest do
  use ExUnit.Case, async: true

  alias TripPlannerIa.TransitParse

  describe "parse_transit_sections/1" do
    test "parses ### sections from raw text" do
      raw = """
      Intro ignored
      ### Ride Apps & Taxis
      Uber and Bolt are available.
      - Easy to get rides

      ### Metro, Train & Rail
      There is a metro system.
      Line 1 covers downtown
      """

      sections = TransitParse.parse_transit_sections(raw)

      assert length(sections) == 2

      [ride_apps, metro] = sections

      assert ride_apps.key == :ride_apps
      assert ride_apps.icon == "Car"
      assert metro.key == :metro
      assert metro.icon == "Train"
      assert String.contains?(ride_apps.content, "Uber")
    end
  end
end