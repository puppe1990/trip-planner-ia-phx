defmodule TripPlannerIa.ClimateTest do
  use ExUnit.Case, async: true

  alias TripPlannerIa.Climate

  describe "get_destination_climate/1" do
    test "returns tropical profile for Rio de Janeiro" do
      profile = Climate.get_destination_climate("Rio de Janeiro")

      assert profile.climate_type == "Tropical Marítimo / Quente"
      assert length(profile.months) == 12
      assert Enum.at(profile.months, 0).temp_max > 28
      assert Enum.at(profile.months, 6).temp_min < 22
    end

    test "returns alpine profile for Switzerland" do
      profile = Climate.get_destination_climate("Switzerland")

      assert profile.climate_type == "Alpino / Frio de Montanha"
      assert length(profile.months) == 12
      assert Enum.at(profile.months, 0).temp_min < 0
      assert Enum.at(profile.months, 6).temp_max > 20
    end

    test "returns southern hemisphere temperate profile for São Paulo" do
      profile = Climate.get_destination_climate("São Paulo")

      assert profile.climate_type == "Temperado Subtropical / Sul"
      assert length(profile.months) == 12

      jan = Enum.at(profile.months, 0)
      jul = Enum.at(profile.months, 6)

      assert jan.temp_max > jul.temp_max
      assert jan.month == "Jan"
      assert jul.month == "Jul"
    end
  end
end
