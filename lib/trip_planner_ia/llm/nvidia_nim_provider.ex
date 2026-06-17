defmodule TripPlannerIa.Llm.NvidiaNimProvider do
  @moduledoc false

  alias TripPlannerIa.AiConfig

  @nim_chat_completions_url "https://integrate.api.nvidia.com/v1/chat/completions"
  @nim_request_timeout_ms 22_000
  @nim_json_max_tokens 4096

  defstruct [:api_key, :model, :req_options]

  @type t :: %__MODULE__{
          api_key: String.t(),
          model: String.t(),
          req_options: keyword()
        }

  @type request :: %{
          required(:system) => String.t(),
          required(:prompt) => String.t(),
          optional(:temperature) => number()
        }

  @spec create(String.t(), String.t(), keyword()) :: map()
  def create(api_key, model, opts \\ []) do
    provider = %__MODULE__{
      api_key: api_key,
      model: model,
      req_options: Keyword.get(opts, :req_options, [])
    }

    %{
      id: "nvidia-nim",
      display_name: "NVIDIA NIM",
      model: model,
      capabilities: %{structured_json: true, web_grounding: false},
      generate_json: fn request -> generate_json(provider, request) end,
      generate_text: fn request -> generate_text(provider, request) end,
      generate_grounded_text: nil
    }
  end

  @spec generate_json(t(), request()) :: String.t()
  def generate_json(%__MODULE__{} = provider, request) do
    call_chat_completions(provider, %{
      "model" => provider.model,
      "max_tokens" => @nim_json_max_tokens,
      "temperature" => Map.get(request, :temperature, 0.8),
      "response_format" => %{"type" => "json_object"},
      "messages" => chat_messages(request)
    })
  end

  @spec generate_text(t(), request()) :: String.t()
  def generate_text(%__MODULE__{} = provider, request) do
    call_chat_completions(provider, %{
      "model" => provider.model,
      "temperature" => Map.get(request, :temperature, 0.5),
      "messages" => chat_messages(request)
    })
  end

  defp chat_messages(request) do
    [
      %{"role" => "system", "content" => request.system},
      %{"role" => "user", "content" => request.prompt}
    ]
  end

  defp call_chat_completions(
         %__MODULE__{api_key: api_key, model: model, req_options: req_options},
         body
       ) do
    unless AiConfig.nvidia_model_hosted?(model) do
      raise "Model \"#{model}\" is not available on the hosted NVIDIA NIM API. Choose a supported model from the list."
    end

    options =
      [
        url: @nim_chat_completions_url,
        json: body,
        auth: {:bearer, api_key},
        receive_timeout: @nim_request_timeout_ms
      ] ++ req_options

    case Req.post(options) do
      {:ok,
       %{status: status, body: %{"choices" => [%{"message" => %{"content" => content}} | _]}}}
      when status in 200..299 and is_binary(content) and content != "" ->
        content

      {:ok, %{status: 404}} ->
        raise "NVIDIA NIM request failed (404): Model \"#{model}\" is not available on the hosted API. Choose another model."

      {:ok, %{status: status, body: body}} ->
        raise "NVIDIA NIM request failed (#{status}): #{format_error_body(body)}"

      {:error, %Req.TransportError{reason: :timeout}} ->
        raise "NVIDIA NIM request timed out after #{div(@nim_request_timeout_ms, 1000)}s. Use Google Gemini or a smaller NVIDIA model (e.g. Nemotron Nano 9B)."

      {:error, reason} ->
        raise "NVIDIA NIM request failed: #{inspect(reason)}"
    end
  end

  defp format_error_body(body) when is_binary(body), do: body
  defp format_error_body(body), do: Jason.encode!(body)
end
