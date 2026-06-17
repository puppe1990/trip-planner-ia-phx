defmodule TripPlannerIa.Repo.Migrations.AddAiPreferencesToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :ai_provider_id, :string
      add :ai_model, :string
    end
  end
end
