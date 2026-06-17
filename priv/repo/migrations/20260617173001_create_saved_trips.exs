defmodule TripPlannerIa.Repo.Migrations.CreateSavedTrips do
  use Ecto.Migration

  def change do
    create table(:saved_trips, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :id, on_delete: :delete_all), null: false
      add :destination, :string, null: false
      add :duration_days, :integer, null: false
      add :tagline, :string
      add :plan_json, :map, null: false
      add :search_params_json, :map

      timestamps(type: :utc_datetime)
    end

    create unique_index(:saved_trips, [:user_id, :destination, :duration_days],
             name: :saved_trips_user_dest_duration
           )

    create index(:saved_trips, [:user_id])
  end
end