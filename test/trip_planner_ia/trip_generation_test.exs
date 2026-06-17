defmodule TripPlannerIa.TripGenerationTest do
  use ExUnit.Case, async: true

  alias TripPlannerIa.TripGeneration

  @params %{
    destination: "Lisbon, Portugal",
    duration: 2,
    budget: "Médio",
    style: "Cultural",
    companion: "Solo",
    season: "Spring",
    extra_notes: ""
  }

  @outline %{
    destination: "Lisbon, Portugal",
    duration_days: 2,
    tagline: "Tiles and tramways",
    summary: "A cultural weekend",
    budget_estimate: %{
      total_cost_estimate: "$800",
      hotel_average_night: "$100",
      food_average_day: "$40",
      transport_average_day: "$15"
    },
    packing_essentials: ["Comfortable shoes"],
    weather_expected: "Mild spring"
  }

  defp day_plan(day_number) do
    %{
      day_number: day_number,
      theme: "Day #{day_number}",
      morning: %{title: "M", description: "MD", cost: "$", duration: "2h"},
      afternoon: %{title: "A", description: "AD", cost: "$", duration: "3h"},
      evening: %{title: "E", description: "ED", cost: "$", duration: "2h"},
      dining_spot: %{name: "Tasca", type: "Local", price_level: "$$", description: "Cozy"}
    }
  end

  defp assembled_plan do
    Map.merge(@outline, %{
      id: "trip_test",
      created_at: "2026-01-01T00:00:00.000Z",
      days: [day_plan(1), day_plan(2)],
      tips: [%{category: "Transport", text: "Get a Viva Viagem card"}],
      budget_preference: @params.budget,
      style_preference: @params.style,
      companion_preference: @params.companion
    })
  end

  describe "run_trip_generation/1" do
    test "uses single-shot generation when multi-step is disabled" do
      params = @params
      plan = assembled_plan()
      generate_single_shot = fn ^params, "en" -> plan end
      generate_outline = fn _, _ -> flunk("generate_outline should not be called") end
      generate_day = fn _, _, _, _ -> flunk("generate_day should not be called") end
      generate_tips = fn _, _, _, _ -> flunk("generate_tips should not be called") end
      persist_assembled = fn _, _, _, _ -> flunk("persist_assembled should not be called") end

      result =
        TripGeneration.run_trip_generation(%{
          params: @params,
          locale: "en",
          is_multi_step_enabled: fn -> false end,
          generate_single_shot: generate_single_shot,
          generate_outline: generate_outline,
          generate_day: generate_day,
          generate_tips: generate_tips,
          persist_assembled: persist_assembled
        })

      assert result == plan
    end

    test "runs outline, each day, tips and persist when multi-step is enabled" do
      params = @params
      outline = @outline
      progress_calls = :ets.new(:progress_calls, [:set, :private])

      on_progress = fn progress ->
        :ets.insert(progress_calls, {length(:ets.tab2list(progress_calls)) + 1, progress})
      end

      generate_single_shot = fn _, _ -> flunk("generate_single_shot should not be called") end

      generate_outline = fn ^params, "pt-BR" -> outline end

      generate_day = fn
        ^params, "pt-BR", 1, ^outline -> day_plan(1)
        ^params, "pt-BR", 2, ^outline -> day_plan(2)
      end

      generate_tips = fn ^params, "pt-BR", ^outline, days ->
        assert days == [day_plan(1), day_plan(2)]
        [%{category: "Transport", text: "Get a Viva Viagem card"}]
      end

      persist_assembled = fn ^params, ^outline, days, tips ->
        assert days == [day_plan(1), day_plan(2)]

        assert tips == [
                 %{category: "Transport", text: "Get a Viva Viagem card"}
               ]

        assembled_plan()
      end

      result =
        TripGeneration.run_trip_generation(%{
          params: @params,
          locale: "pt-BR",
          is_multi_step_enabled: fn -> true end,
          generate_single_shot: generate_single_shot,
          generate_outline: generate_outline,
          generate_day: generate_day,
          generate_tips: generate_tips,
          persist_assembled: persist_assembled,
          on_progress: on_progress
        })

      assert result == assembled_plan()

      progress =
        :ets.tab2list(progress_calls)
        |> Enum.sort_by(fn {index, _} -> index end)
        |> Enum.map(&elem(&1, 1))

      assert progress == [
               %{phase: "outline"},
               %{phase: "day", day_number: 1, total_days: 2},
               %{phase: "day", day_number: 2, total_days: 2},
               %{phase: "tips"},
               %{phase: "saving"}
             ]
    end
  end
end
