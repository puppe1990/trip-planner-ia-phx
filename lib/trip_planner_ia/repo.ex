defmodule TripPlannerIa.Repo do
  use Ecto.Repo,
    otp_app: :trip_planner_ia,
    adapter: Ecto.Adapters.LibSql
end
