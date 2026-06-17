defmodule TripPlannerIa.Planner do
  @moduledoc false

  alias TripPlannerIa.PlannerJsonInstructions
  alias TripPlannerIa.PlannerSchema

  defmodule ValidationError do
    defexception [:message]

    @impl true
    def exception(message) do
      %__MODULE__{message: message}
    end
  end

  @type provider :: %{
          required(:generate_json) => (map() -> String.t())
        }

  @type search_params :: %{
          required(:destination) => String.t(),
          required(:duration) => integer(),
          optional(:budget) => String.t(),
          optional(:style) => String.t(),
          optional(:companion) => String.t(),
          optional(:season) => String.t(),
          optional(:extra_notes) => String.t()
        }

  @spec validate_search_params(search_params()) :: :ok
  def validate_search_params(params) do
    destination = params |> Map.get(:destination, "") |> String.trim()
    duration = Map.get(params, :duration)

    if destination == "" or duration in [nil, 0] do
      raise ValidationError, "Destination and duration are required."
    end

    :ok
  end

  @spec build_planner_prompt(search_params(), String.t()) :: String.t()
  def build_planner_prompt(params, locale \\ "pt-BR") do
    lang = gemini_language(locale)

    language_instruction =
      if lang == "en" do
        "Write ALL content strictly in English."
      else
        "Escreva TODO o conteúdo estritamente em Português do Brasil (pt-BR)."
      end

    """
    Create a complete, personalized and detailed trip plan for the destination: "#{params.destination}".
    Context for personalization:
    - Trip duration: #{params.duration} days
    - Budget level: #{Map.get(params, :budget, "Médio")}
    - Travel style: #{Map.get(params, :style, "Equilibrado")}
    - Companions: #{Map.get(params, :companion, "Solo")}
    - Season/climate: #{Map.get(params, :season, "Any season")}
    - Additional notes: #{Map.get(params, :extra_notes, "None")}

    #{language_instruction} Organize activities realistically with morning, afternoon and evening plans coherent with travel distances and times.
    """
    |> String.trim()
  end

  @spec assemble_result(map(), [map()], [map()]) :: map()
  def assemble_result(outline, days, tips) do
    Map.merge(outline, %{days: days, tips: tips})
  end

  @spec generate_outline(provider(), search_params(), String.t()) :: map()
  def generate_outline(provider, params, locale \\ "pt-BR") do
    validate_search_params(params)

    schema_instruction = PlannerJsonInstructions.build_planner_outline_schema_instruction()

    prompt =
      """
      #{build_planner_prompt(params, locale)}

      Create only the trip overview: tagline, summary, budgetEstimate, packingEssentials and weatherExpected.
      """
      |> String.trim()

    with_generation_retries(fn ->
      response_text = request_planner_json(provider, locale, schema_instruction, prompt)

      PlannerSchema.parse_outline(response_text, %{
        destination: String.trim(params.destination),
        duration_days: params.duration
      })
    end)
  end

  @spec generate_day(provider(), search_params(), String.t(), integer(), map()) :: map()
  def generate_day(provider, params, locale, day_number, outline) do
    schema_instruction = PlannerJsonInstructions.build_planner_day_schema_instruction()

    prompt =
      """
      #{build_planner_prompt(params, locale)}

      Trip overview:
      - Tagline: #{outline.tagline}
      - Summary: #{outline.summary}

      Create ONLY day #{day_number} of #{params.duration}. Keep activities realistic for the destination and coherent with the overview.
      """
      |> String.trim()

    with_generation_retries(fn ->
      response_text = request_planner_json(provider, locale, schema_instruction, prompt)
      PlannerSchema.parse_day(response_text, day_number)
    end)
  end

  @spec generate_tips(provider(), search_params(), String.t(), map(), [map()]) :: [map()]
  def generate_tips(provider, params, locale, outline, days) do
    schema_instruction = PlannerJsonInstructions.build_planner_tips_schema_instruction()

    day_themes =
      days
      |> Enum.map(fn day -> "Day #{day.day_number}: #{day.theme}" end)
      |> Enum.join("\n")

    prompt =
      """
      #{build_planner_prompt(params, locale)}

      Trip overview:
      - Summary: #{outline.summary}
      - Weather: #{outline.weather_expected}

      Day themes:
      #{day_themes}

      Create practical travel tips for this itinerary.
      """
      |> String.trim()

    with_generation_retries(fn ->
      response_text = request_planner_json(provider, locale, schema_instruction, prompt)
      PlannerSchema.parse_tips(response_text)
    end)
  end

  @spec generate_plan(provider(), search_params(), String.t()) :: map()
  def generate_plan(provider, params, locale \\ "pt-BR") do
    validate_search_params(params)

    schema_instruction = PlannerJsonInstructions.build_planner_json_schema_instruction()
    prompt = build_planner_prompt(params, locale)

    with_generation_retries(fn ->
      response_text = request_planner_json(provider, locale, schema_instruction, prompt)

      PlannerSchema.parse_result(response_text, %{
        destination: String.trim(params.destination),
        duration_days: params.duration
      })
    end)
  end

  @spec build_trip_plan(map(), search_params(), String.t() | nil) :: map()
  def build_trip_plan(generated, params, id \\ nil) do
    trip_id = id || "trip_#{System.system_time(:millisecond)}"

    Map.merge(generated, %{
      id: trip_id,
      created_at: DateTime.utc_now() |> DateTime.to_iso8601(),
      budget_preference: Map.get(params, :budget),
      style_preference: Map.get(params, :style),
      companion_preference: Map.get(params, :companion)
    })
  end

  defp request_planner_json(provider, locale, schema_instruction, prompt) do
    system = "#{planner_system_instruction(locale)}\n\n#{schema_instruction}"

    response_text =
      provider.generate_json.(%{
        system: system,
        prompt: "#{prompt}\n\n#{schema_instruction}",
        temperature: 0.8
      })

    if is_binary(response_text) and response_text != "" do
      response_text
    else
      raise "No content returned by model."
    end
  end

  defp planner_system_instruction(locale) do
    if gemini_language(locale) == "en" do
      "You are a professional travel guide. Create logical, detailed itineraries with authentic local experiences. Respond strictly in the provided JSON schema and in English."
    else
      "Você é um guia turístico profissional. Crie itinerários lógicos e detalhados com experiências locais autênticas. Responda estritamente no schema JSON fornecido e em Português (pt-BR)."
    end
  end

  defp gemini_language(locale) when is_binary(locale) do
    if String.starts_with?(locale, "en"), do: "en", else: "pt-BR"
  end

  defp with_generation_retries(fun) do
    do_with_retries(fun, 1, 1500)
  end

  defp do_with_retries(fun, attempt, delay) when attempt <= 3 do
    fun.()
  rescue
    error ->
      if attempt == 3 do
        reraise error, __STACKTRACE__
      else
        Process.sleep(delay)
        do_with_retries(fun, attempt + 1, delay * 2)
      end
  end
end