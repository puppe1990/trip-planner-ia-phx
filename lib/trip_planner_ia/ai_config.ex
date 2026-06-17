defmodule TripPlannerIa.AiConfig do
  @moduledoc false

  defmodule InvalidAiProviderError do
    defexception [:message]

    @impl true
    def exception(provider) do
      %__MODULE__{
        message: ~s(Invalid AI_PROVIDER "#{provider}". Expected "gemini" or "nvidia-nim".)
      }
    end
  end

  @nvidia_nim_hosted_model_ids [
    "meta/llama-3.3-70b-instruct",
    "meta/llama-3.1-70b-instruct",
    "mistralai/mixtral-8x7b-instruct-v0.1",
    "nvidia/nvidia-nemotron-nano-9b-v2",
    "meta/llama-3.1-8b-instruct",
    "nvidia/nemotron-mini-4b-instruct"
  ]

  @gemini_models [
    %{id: "gemini-3.5-flash", label: "Gemini 3.5 Flash"},
    %{id: "gemini-2.5-flash", label: "Gemini 2.5 Flash"},
    %{id: "gemini-2.5-pro", label: "Gemini 2.5 Pro"},
    %{id: "gemini-2.0-flash", label: "Gemini 2.0 Flash"}
  ]

  @nvidia_models_catalog [
    %{id: "nvidia/nvidia-nemotron-nano-9b-v2", label: "Nemotron Nano 9B v2 (rápido)"},
    %{id: "meta/llama-3.1-8b-instruct", label: "Llama 3.1 8B Instruct (rápido)"},
    %{id: "nvidia/nemotron-mini-4b-instruct", label: "Nemotron Mini 4B Instruct (rápido)"},
    %{id: "meta/llama-3.3-70b-instruct", label: "Llama 3.3 70B Instruct"},
    %{id: "meta/llama-3.1-70b-instruct", label: "Llama 3.1 70B Instruct"},
    %{id: "mistralai/mixtral-8x7b-instruct-v0.1", label: "Mixtral 8x7B Instruct"}
  ]

  @provider_defaults %{
    "gemini" => %{
      display_name: "Google Gemini",
      model: "gemini-3.5-flash",
      capabilities: %{structured_json: true, web_grounding: true}
    },
    "nvidia-nim" => %{
      display_name: "NVIDIA NIM",
      model: "nvidia/nvidia-nemotron-nano-9b-v2",
      capabilities: %{structured_json: true, web_grounding: false}
    }
  }

  @provider_ids Map.keys(@provider_defaults)

  def parse_provider_id("gemini"), do: "gemini"
  def parse_provider_id("nvidia-nim"), do: "nvidia-nim"

  def parse_provider_id(provider) do
    raise InvalidAiProviderError, provider
  end

  def provider_models do
    %{
      "gemini" => @gemini_models,
      "nvidia-nim" => filter_hosted_nvidia_models(@nvidia_models_catalog)
    }
  end

  def get_models_for_provider(provider_id, current_model \\ nil) do
    models = Map.fetch!(provider_models(), provider_id)
    trimmed = current_model |> maybe_trim()

    cond do
      is_nil(trimmed) ->
        models

      known_model?(models, trimmed) ->
        models

      provider_id == "nvidia-nim" and not nvidia_model_hosted?(trimmed) ->
        models

      true ->
        [%{id: trimmed, label: trimmed} | models]
    end
  end

  def provider_configured?("gemini"), do: env_present?("GEMINI_API_KEY")
  def provider_configured?("nvidia-nim"), do: env_present?("NVIDIA_API_KEY")
  def provider_configured?(_), do: false

  def get_provider_id do
    env_raw = System.get_env("AI_PROVIDER") |> maybe_trim()

    if env_raw do
      env_provider = parse_provider_id(env_raw)

      if provider_configured?(env_provider) do
        env_provider
      else
        resolve_provider_id()
      end
    else
      resolve_provider_id()
    end
  end

  def get_ai_config do
    provider_id = get_provider_id()
    defaults = Map.fetch!(@provider_defaults, provider_id)
    model = resolve_env("AI_MODEL", defaults.model)
    build_ai_config(provider_id, model)
  end

  def resolve_ai_config(nil), do: get_ai_config()
  def resolve_ai_config(%{provider_id: nil}), do: get_ai_config()
  def resolve_ai_config(%{provider_id: ""}), do: get_ai_config()

  def resolve_ai_config(%{provider_id: provider_id} = preferences) do
    provider_id =
      if provider_configured?(provider_id),
        do: provider_id,
        else: get_provider_id()

    defaults = Map.fetch!(@provider_defaults, provider_id)
    saved_model = preferences |> Map.get(:model) |> maybe_trim()

    model =
      if saved_model && (provider_id != "nvidia-nim" || nvidia_model_hosted?(saved_model)) do
        saved_model
      else
        defaults.model
      end

    build_ai_config(provider_id, model)
  end

  def resolve_ai_config(_), do: get_ai_config()

  def list_provider_options do
    Enum.map(@provider_ids, fn id ->
      defaults = Map.fetch!(@provider_defaults, id)

      %{
        id: id,
        display_name: defaults.display_name,
        default_model: defaults.model,
        models: Map.fetch!(provider_models(), id),
        capabilities: defaults.capabilities,
        configured: provider_configured?(id)
      }
    end)
  end

  def get_provider_api_key_error("gemini") do
    if provider_configured?("gemini"),
      do: nil,
      else: "GEMINI_API_KEY not found in environment variables."
  end

  def get_provider_api_key_error("nvidia-nim") do
    if provider_configured?("nvidia-nim"),
      do: nil,
      else: "NVIDIA_API_KEY not found in environment variables."
  end

  def nvidia_model_hosted?(model_id) when is_binary(model_id) do
    model_id in @nvidia_nim_hosted_model_ids
  end

  def nvidia_model_hosted?(_), do: false

  defp build_ai_config(provider_id, model) do
    defaults = Map.fetch!(@provider_defaults, provider_id)

    %{
      provider_id: provider_id,
      provider: defaults.display_name,
      model: model,
      capabilities: defaults.capabilities
    }
  end

  defp resolve_provider_id do
    case configured_provider_ids() do
      [provider_id | _] ->
        provider_id

      [] ->
        parse_provider_id(resolve_env("AI_PROVIDER", "gemini"))
    end
  end

  defp configured_provider_ids do
    Enum.filter(@provider_ids, &provider_configured?/1)
  end

  defp filter_hosted_nvidia_models(catalog) do
    Enum.filter(catalog, fn %{id: id} -> nvidia_model_hosted?(id) end)
  end

  defp known_model?(models, model_id) do
    Enum.any?(models, fn %{id: id} -> id == model_id end)
  end

  defp resolve_env(key, fallback) do
    case System.get_env(key) |> maybe_trim() do
      nil -> fallback
      value -> value
    end
  end

  defp env_present?(key) do
    case System.get_env(key) |> maybe_trim() do
      nil -> false
      _ -> true
    end
  end

  defp maybe_trim(nil), do: nil

  defp maybe_trim(value) do
    trimmed = String.trim(value)
    if trimmed == "", do: nil, else: trimmed
  end
end
