defmodule TripPlannerIa.Transit do
  @moduledoc false

  @transit_section_headers %{
    "en" => [
      "### Ride Apps & Taxis",
      "### Routes & Local Navigation",
      "### Metro, Train & Rail",
      "### Buses & Local Transport",
      "### Fares & Payment",
      "### General Mobility Tips"
    ],
    "pt-BR" => [
      "### Apps de Corrida e Táxis",
      "### Rotas e Navegação Local",
      "### Metrô, Trem e Trens",
      "### Ônibus e Transporte Local",
      "### Tarifas e Pagamento",
      "### Dicas Gerais de Mobilidade"
    ]
  }

  @spec build_transit_prompt(String.t(), String.t()) :: String.t()
  def build_transit_prompt(destination, locale \\ "pt-BR") do
    lang = gemini_language(locale)
    lang_instruction = lang_instruction_for(lang)
    section_headers = Map.fetch!(@transit_section_headers, lang) |> Enum.join("\n")

    """
    You are a global urban mobility expert. Search in real time with Google Search for updated transport options in "#{destination}".
    #{lang_instruction}
    Return topics exactly in the format below (with titles marked by '###'):

    #{section_headers}

    Be direct and friendly. No generic introductions.
    Use plain-text bullet lists starting with "-". Do not use markdown symbols like **bold** or *italic*.
    """
  end

  @spec search_transit(map(), String.t(), String.t()) :: %{
          raw_text: String.t(),
          sources: [%{title: String.t(), url: String.t()}]
        }
  def search_transit(provider, destination, locale \\ "pt-BR") do
    destination = destination |> to_string() |> String.trim()

    if destination == "" do
      raise ArgumentError, "Destination is required for transit search."
    end

    prompt = build_transit_prompt(destination, locale)

    case Map.get(provider, :generate_grounded_text) do
      fun when is_function(fun, 1) ->
        grounded = fun.(%{prompt: prompt, temperature: 0.5})

        %{
          raw_text: grounded.text,
          sources: Map.get(grounded, :sources, [])
        }

      _ ->
        generate_text = Map.fetch!(provider, :generate_text)

        text =
          generate_text.(%{
            system: "You are a global urban mobility expert.",
            prompt: prompt,
            temperature: 0.5
          })

        %{raw_text: text, sources: []}
    end
  end

  defp gemini_language(locale) when is_binary(locale) do
    if String.starts_with?(locale, "en"), do: "en", else: "pt-BR"
  end

  defp lang_instruction_for("en"),
    do: "Structure your response EXCLUSIVELY in English."

  defp lang_instruction_for(_),
    do: "Estruture sua resposta EXCLUSIVAMENTE em Português do Brasil (pt-BR)."
end
