defmodule TripPlannerIa.Llm.GeminiProvider do
  @moduledoc false

  @gemini_base_url "https://generativelanguage.googleapis.com/v1beta/models"

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

  @type grounded_request :: %{
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
      id: "gemini",
      display_name: "Google Gemini",
      model: model,
      capabilities: %{structured_json: true, web_grounding: true},
      generate_json: fn request -> generate_json(provider, request) end,
      generate_text: fn request -> generate_text(provider, request) end,
      generate_grounded_text: fn request -> generate_grounded_text(provider, request) end
    }
  end

  @spec generate_json(t(), request()) :: String.t()
  def generate_json(%__MODULE__{} = provider, request) do
    body =
      build_body(request, %{
        "responseMimeType" => "application/json",
        "temperature" => Map.get(request, :temperature, 0.8)
      })

    provider
    |> post_generate_content(body)
    |> extract_text()
  end

  @spec generate_text(t(), request()) :: String.t()
  def generate_text(%__MODULE__{} = provider, request) do
    body =
      build_body(request, %{
        "temperature" => Map.get(request, :temperature, 0.5)
      })

    provider
    |> post_generate_content(body)
    |> extract_text()
  end

  @spec generate_grounded_text(t(), grounded_request()) :: %{text: String.t(), sources: list()}
  def generate_grounded_text(%__MODULE__{} = provider, request) do
    body = %{
      "contents" => [%{"parts" => [%{"text" => request.prompt}]}],
      "tools" => [%{"googleSearch" => %{}}],
      "generationConfig" => %{
        "temperature" => Map.get(request, :temperature, 0.5)
      }
    }

    response = post_generate_content(provider, body)

    %{
      text: extract_text(response),
      sources: extract_grounding_sources(response)
    }
  end

  defp build_body(request, generation_config) do
    %{
      "contents" => [%{"parts" => [%{"text" => request.prompt}]}],
      "systemInstruction" => %{"parts" => [%{"text" => request.system}]},
      "generationConfig" => generation_config
    }
  end

  defp post_generate_content(
         %__MODULE__{api_key: api_key, model: model, req_options: req_options},
         body
       ) do
    url = "#{@gemini_base_url}/#{model}:generateContent"

    case Req.post(url, [params: [key: api_key], json: body] ++ req_options) do
      {:ok, %{status: status, body: body}} when status in 200..299 ->
        body

      {:ok, %{status: status, body: body}} ->
        raise "Gemini request failed (#{status}): #{format_error_body(body)}"

      {:error, %Req.TransportError{reason: :timeout}} ->
        raise "Gemini request timed out."

      {:error, reason} ->
        raise "Gemini request failed: #{inspect(reason)}"
    end
  end

  defp extract_text(%{
         "candidates" => [%{"content" => %{"parts" => [%{"text" => text} | _]}} | _]
       })
       when is_binary(text) do
    text
  end

  defp extract_text(_response) do
    raise "No content returned by Gemini model."
  end

  defp extract_grounding_sources(%{"candidates" => [candidate | _]}) do
    chunks =
      candidate
      |> get_in(["groundingMetadata", "groundingChunks"])
      |> List.wrap()

    chunks
    |> Enum.reduce({[], MapSet.new()}, fn
      %{"web" => %{"uri" => uri} = web}, {sources, seen} when is_binary(uri) ->
        if MapSet.member?(seen, uri) do
          {sources, seen}
        else
          source = %{
            title: Map.get(web, "title", "Search Source"),
            url: uri
          }

          {[source | sources], MapSet.put(seen, uri)}
        end

      _chunk, acc ->
        acc
    end)
    |> elem(0)
    |> Enum.reverse()
  end

  defp extract_grounding_sources(_response), do: []

  defp format_error_body(body) when is_binary(body), do: body
  defp format_error_body(body), do: Jason.encode!(body)
end
