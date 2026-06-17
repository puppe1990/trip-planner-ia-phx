defmodule TripPlannerIa.TripGeneration do
  @moduledoc false

  @spec run_trip_generation(map()) :: map()
  def run_trip_generation(%{is_multi_step_enabled: is_multi_step_enabled} = deps)
      when is_function(is_multi_step_enabled, 0) do
    params = Map.fetch!(deps, :params)
    locale = Map.fetch!(deps, :locale)
    on_progress = Map.get(deps, :on_progress)

    if is_multi_step_enabled.() do
      run_multi_step(deps, params, locale, on_progress)
    else
      deps.generate_single_shot.(params, locale)
    end
  end

  defp run_multi_step(deps, params, locale, on_progress) do
    duration = Map.fetch!(params, :duration)

    notify(on_progress, %{phase: "outline"})
    outline = deps.generate_outline.(params, locale)

    days =
      Enum.map(1..duration, fn day_number ->
        notify(on_progress, %{
          phase: "day",
          day_number: day_number,
          total_days: duration
        })

        deps.generate_day.(params, locale, day_number, outline)
      end)

    notify(on_progress, %{phase: "tips"})
    tips = deps.generate_tips.(params, locale, outline, days)

    notify(on_progress, %{phase: "saving"})
    deps.persist_assembled.(params, outline, days, tips)
  end

  defp notify(nil, _progress), do: :ok
  defp notify(callback, progress) when is_function(callback, 1), do: callback.(progress)
end
