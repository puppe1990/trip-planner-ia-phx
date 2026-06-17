defmodule TripPlannerIa.DataCase do
  @moduledoc """
  Data layer test setup for LibSQL/SQLite (no SQL Sandbox — nested transactions unsupported).
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      alias TripPlannerIa.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import TripPlannerIa.DataCase
    end
  end

  setup _tags do
    cleanup_db()
    :ok
  end

  def cleanup_db do
    alias TripPlannerIa.Repo

    Repo.delete_all(TripPlannerIa.Trips.SavedTrip)
    Repo.delete_all(TripPlannerIa.Accounts.UserToken)
    Repo.delete_all(TripPlannerIa.Accounts.User)
  end

  def errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
