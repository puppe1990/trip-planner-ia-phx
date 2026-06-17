defmodule TripPlannerIa.AiPreferences do
  @moduledoc false

  import Ecto.Query, warn: false

  alias TripPlannerIa.AiConfig
  alias TripPlannerIa.Accounts.User
  alias TripPlannerIa.Repo

  def get_user_ai_preferences(user_id) do
    case Repo.one(
           from u in User,
             where: u.id == ^user_id,
             select: %{ai_provider_id: u.ai_provider_id, ai_model: u.ai_model}
         ) do
      nil ->
        nil

      %{ai_provider_id: provider_id} when provider_id in [nil, ""] ->
        nil

      %{ai_provider_id: provider_id, ai_model: model} ->
        %{
          provider_id: AiConfig.parse_provider_id(provider_id),
          model: model
        }
    end
  end

  def set_user_ai_preferences(user_id, %{provider_id: provider_id} = preferences) do
    model =
      preferences
      |> Map.get(:model)
      |> normalize_model()

    user = Repo.get!(User, user_id)

    user
    |> User.ai_preferences_changeset(%{ai_provider_id: provider_id, ai_model: model})
    |> Repo.update()
  end

  defp normalize_model(nil), do: nil

  defp normalize_model(model) when is_binary(model) do
    case String.trim(model) do
      "" -> nil
      trimmed -> trimmed
    end
  end

  defp normalize_model(_), do: nil
end
