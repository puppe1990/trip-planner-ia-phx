defmodule TripPlannerIa.Trips.SavedTrip do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: false}
  @foreign_key_type :binary_id

  schema "saved_trips" do
    field :destination, :string
    field :duration_days, :integer
    field :tagline, :string
    field :plan_json, :map
    field :search_params_json, :map

    belongs_to :user, TripPlannerIa.Accounts.User, type: :id

    timestamps(type: :utc_datetime)
  end

  def changeset(saved_trip, attrs) do
    saved_trip
    |> cast(attrs, [:destination, :duration_days, :tagline, :plan_json, :search_params_json, :inserted_at])
    |> validate_required([:destination, :duration_days, :plan_json, :user_id])
    |> unique_constraint([:user_id, :destination, :duration_days],
      name: :saved_trips_user_dest_duration
    )
  end
end