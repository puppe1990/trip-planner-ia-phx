defmodule TripPlannerIa.Trips do
  @moduledoc """
  The Trips context.
  """

  import Ecto.Query, warn: false

  alias TripPlannerIa.Repo
  alias TripPlannerIa.Trips.SavedTrip

  @doc """
  Lists saved trip plans for a user, ordered by most recently updated first.
  """
  def list_trips_for_user(user_id) do
    SavedTrip
    |> where([t], t.user_id == ^user_id)
    |> order_by([t], desc: t.inserted_at)
    |> Repo.all()
    |> Enum.map(& &1.plan_json)
  end

  @doc """
  Inserts or updates a saved trip for a user, keyed by destination and duration.

  When a matching trip already exists, its id is preserved and the plan is replaced.
  """
  def upsert_trip(user_id, search_params, plan) when is_map(search_params) and is_map(plan) do
    destination = plan["destination"] || plan[:destination]
    duration_days = plan["duration_days"] || plan[:duration_days]

    case find_trip(user_id, destination, duration_days) do
      nil ->
        insert_trip(user_id, search_params, plan)

      %SavedTrip{id: existing_id} ->
        update_trip(existing_id, user_id, search_params, plan)
    end
  end

  @doc """
  Deletes a saved trip for the given user.

  Returns `true` when a trip was deleted, otherwise `false`.
  """
  def delete_trip(user_id, trip_id) do
    case Repo.delete_all(
           from(t in SavedTrip, where: t.id == ^trip_id and t.user_id == ^user_id)
         ) do
      {1, _} -> true
      _ -> false
    end
  end

  defp find_trip(user_id, destination, duration_days) do
    Repo.one(
      from(t in SavedTrip,
        where:
          t.user_id == ^user_id and t.destination == ^destination and
            t.duration_days == ^duration_days,
        limit: 1
      )
    )
  end

  defp insert_trip(user_id, search_params, plan) do
    trip_id = plan["id"] || plan[:id] || Ecto.UUID.generate()
    persisted_plan = plan |> stringify_keys() |> Map.put("id", trip_id)

    %SavedTrip{id: trip_id, user_id: user_id}
    |> SavedTrip.changeset(%{
      destination: persisted_plan["destination"],
      duration_days: persisted_plan["duration_days"],
      tagline: persisted_plan["tagline"],
      plan_json: persisted_plan,
      search_params_json: normalize_search_params(search_params)
    })
    |> Repo.insert!()

    persisted_plan
  end

  defp update_trip(existing_id, user_id, search_params, plan) do
    persisted_plan = plan |> stringify_keys() |> Map.put("id", existing_id)
    now = DateTime.utc_now(:second)

    %SavedTrip{id: existing_id, user_id: user_id}
    |> SavedTrip.changeset(%{
      destination: persisted_plan["destination"],
      duration_days: persisted_plan["duration_days"],
      tagline: persisted_plan["tagline"],
      plan_json: persisted_plan,
      search_params_json: normalize_search_params(search_params),
      inserted_at: now
    })
    |> Repo.update!()

    persisted_plan
  end

  defp normalize_search_params(nil), do: nil
  defp normalize_search_params(%{} = params) when map_size(params) == 0, do: nil
  defp normalize_search_params(%{} = params), do: params

  defp stringify_keys(map) when is_map(map) do
    Map.new(map, fn
      {key, value} when is_atom(key) -> {Atom.to_string(key), stringify_keys(value)}
      {key, value} -> {key, stringify_keys(value)}
    end)
  end

  defp stringify_keys(value), do: value
end