defmodule TripPlannerIa.Llm.Factory do
  @moduledoc false

  alias TripPlannerIa.AiConfig
  alias TripPlannerIa.Llm.GeminiProvider
  alias TripPlannerIa.Llm.NvidiaNimProvider

  @spec create_provider(map()) :: map()
  def create_provider(%{provider_id: "gemini", model: model}) do
    api_key = fetch_api_key!("GEMINI_API_KEY", "gemini")
    GeminiProvider.create(api_key, model)
  end

  def create_provider(%{provider_id: "nvidia-nim", model: model}) do
    api_key = fetch_api_key!("NVIDIA_API_KEY", "nvidia-nim")
    NvidiaNimProvider.create(api_key, model)
  end

  def create_provider(%{provider_id: provider_id}) do
    raise AiConfig.InvalidAiProviderError, provider_id
  end

  defp fetch_api_key!(env_key, provider_id) do
    case System.get_env(env_key) |> maybe_trim() do
      nil ->
        case AiConfig.get_provider_api_key_error(provider_id) do
          nil -> ""
          message -> raise message
        end

      value ->
        value
    end
  end

  defp maybe_trim(nil), do: nil

  defp maybe_trim(value) do
    trimmed = String.trim(value)
    if trimmed == "", do: nil, else: trimmed
  end
end
