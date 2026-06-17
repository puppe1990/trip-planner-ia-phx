defmodule TripPlannerIa.TripsTest do
  use TripPlannerIa.DataCase

  alias TripPlannerIa.Trips
  alias TripPlannerIa.Fixtures

  import TripPlannerIa.AccountsFixtures

  defp sample_plan(id, destination, days \\ 3) do
    Fixtures.sample_trip_plan(%{
      id: id,
      destination: destination,
      duration_days: days,
      tagline: "Test",
      summary: "Summary"
    })
  end

  defp sample_search_params(destination, days) do
    %{
      destination: destination,
      duration: days,
      budget: "Médio",
      style: "Cultural",
      companion: "Amigos",
      season: "Verão",
      extra_notes: ""
    }
  end

  describe "upsert_trip/3" do
    test "saves a newly generated plan" do
      user = unconfirmed_user_fixture()
      plan = sample_plan("trip_new", "Barcelona, Espanha", 5)
      search_params = sample_search_params("Barcelona, Espanha", 5)

      persisted = Trips.upsert_trip(user.id, search_params, plan)
      trips = Trips.list_trips_for_user(user.id)

      assert length(trips) == 1
      assert persisted["id"] == "trip_new"
      assert hd(trips)["destination"] == "Barcelona, Espanha"
    end

    test "replaces an existing plan for the same destination and duration" do
      user = unconfirmed_user_fixture()
      Trips.upsert_trip(user.id, %{}, sample_plan("trip_old", "Roma, Itália", 4))

      updated_plan =
        sample_plan("trip_new", "Roma, Itália", 4)
        |> Map.merge(%{tagline: "Nova versão do roteiro", summary: "Atualizado pela IA"})

      persisted = Trips.upsert_trip(user.id, %{}, updated_plan)
      trips = Trips.list_trips_for_user(user.id)

      assert length(trips) == 1
      assert persisted["id"] == "trip_old"
      assert hd(trips)["tagline"] == "Nova versão do roteiro"
      assert hd(trips)["summary"] == "Atualizado pela IA"
    end
  end

  describe "list_trips_for_user/1" do
    test "returns trips for a user" do
      user = unconfirmed_user_fixture()
      plan = sample_plan("trip_1", "Paris, França")
      Trips.upsert_trip(user.id, %{}, plan)

      trips = Trips.list_trips_for_user(user.id)

      assert length(trips) == 1
      assert hd(trips)["destination"] == "Paris, França"
    end

    test "isolates trips between users" do
      user_a = unconfirmed_user_fixture()
      user_b = unconfirmed_user_fixture()

      Trips.upsert_trip(user_a.id, %{}, sample_plan("trip_a", "Lisboa"))
      Trips.upsert_trip(user_b.id, %{}, sample_plan("trip_b", "Madrid"))

      assert length(Trips.list_trips_for_user(user_a.id)) == 1
      assert length(Trips.list_trips_for_user(user_b.id)) == 1
    end
  end

  describe "delete_trip/2" do
    test "deletes trip by id for owner only" do
      user_a = unconfirmed_user_fixture()
      user_b = unconfirmed_user_fixture()
      plan = sample_plan("trip_del", "Berlim")

      Trips.upsert_trip(user_a.id, %{}, plan)

      assert Trips.delete_trip(user_a.id, "trip_del") == true
      assert Trips.list_trips_for_user(user_a.id) == []
      assert Trips.delete_trip(user_b.id, "trip_del") == false
    end
  end
end