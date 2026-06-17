defmodule TripPlannerIa.TripPlannerConfig do
  @moduledoc false

  def multi_step_enabled? do
    case System.get_env("TRIP_PLANNER_MULTI_STEP") |> maybe_trim() do
      nil -> true
      "" -> true
      "false" -> false
      _ -> true
    end
  end

  defp maybe_trim(nil), do: nil

  defp maybe_trim(value) do
    value |> String.trim() |> String.downcase()
  end
end
