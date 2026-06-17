defmodule TripPlannerIa.QuickDestinationsTest do
  use ExUnit.Case, async: true

  alias TripPlannerIa.QuickDestinations

  @regions [:brazil, :europe, :asia, :americas, :africa, :oceania]

  describe "regions/0" do
    test "lists all six regions" do
      region_ids = Enum.map(QuickDestinations.regions(), & &1.id)
      assert region_ids == @regions
    end
  end

  describe "destinations_for_region/1" do
    test "each region has exactly four destinations" do
      for region <- @regions do
        destinations = QuickDestinations.destinations_for_region(region)
        assert length(destinations) == 4
      end
    end

    test "each destination has required fields" do
      for region <- @regions,
          dest <- QuickDestinations.destinations_for_region(region) do
        assert is_binary(dest.key)
        assert is_binary(dest.emoji)
        assert is_binary(dest.bg_gradient)
        assert is_binary(dest.name_pt)
        assert is_binary(dest.name_en)
        assert is_binary(dest.tagline_pt)
        assert is_binary(dest.tagline_en)
        assert is_map(dest.params)
        assert is_binary(dest.params.destination)
      end
    end

    test "returns empty list for unknown region string" do
      assert QuickDestinations.destinations_for_region("unknown") == []
    end
  end
end
