defmodule TripPlannerIa.PlannerSchema do
  @moduledoc false

  @type parse_context :: %{
          optional(:destination) => String.t(),
          optional(:duration_days) => integer()
        }

  @spec extract_json_payload(String.t()) :: term()
  def extract_json_payload(raw) when is_binary(raw) do
    trimmed = String.trim(raw)

    candidate =
      case Regex.run(~r/^```(?:json)?\s*([\s\S]*?)\s*```$/i, trimmed) do
        [_, fenced] -> String.trim(fenced)
        _ -> trimmed
      end

    Jason.decode!(candidate)
  end

  @spec normalize_planner_payload(term(), parse_context() | nil) :: term()
  def normalize_planner_payload(parsed, context \\ nil)

  def normalize_planner_payload(parsed, context) when is_map(parsed) do
    normalized =
      cond do
        missing_destination?(parsed) and is_map(parsed["trip"]) ->
          normalize_planner_payload(parsed["trip"], context)

        missing_destination?(parsed) and is_map(parsed[:trip]) ->
          normalize_planner_payload(parsed[:trip], context)

        missing_destination?(parsed) and is_map(parsed["plan"]) ->
          normalize_planner_payload(parsed["plan"], context)

        missing_destination?(parsed) and is_map(parsed[:plan]) ->
          normalize_planner_payload(parsed[:plan], context)

        true ->
          parsed
      end

    normalized = apply_context(normalized, context)
    normalized
  end

  def normalize_planner_payload(parsed, _context), do: parsed

  @spec parse_outline(String.t(), parse_context() | nil) :: map()
  def parse_outline(raw_json, context \\ nil) do
    raw_json
    |> parse_payload(context)
    |> validate_outline()
  end

  @spec parse_day(String.t(), integer()) :: map()
  def parse_day(raw_json, day_number) do
    parsed = parse_payload(raw_json)

    case validate_day(parsed) do
      {:ok, day} ->
        if day.day_number == day_number do
          day
        else
          raise "Invalid planner JSON at day_number: expected #{day_number}, received #{day.day_number}"
        end

      {:error, path, message} ->
        raise validation_error_message(path, message)
    end
  end

  @spec parse_tips(String.t()) :: [map()]
  def parse_tips(raw_json) do
    raw_json
    |> parse_payload()
    |> validate_tips()
  end

  @spec parse_result(String.t(), parse_context() | nil) :: map()
  def parse_result(raw_json, context \\ nil) do
    raw_json
    |> parse_payload(context)
    |> validate_result()
  end

  defp parse_payload(raw_json, context \\ nil) do
    parsed =
      try do
        extract_json_payload(raw_json)
      rescue
        _exception ->
          reraise "Planner response is not valid JSON.", __STACKTRACE__
      end

    normalize_planner_payload(parsed, context)
  end

  defp validate_outline(data) do
    with {:ok, destination} <- require_string(data, "destination"),
         {:ok, duration_days} <- require_integer(data, "durationDays"),
         {:ok, tagline} <- require_string(data, "tagline"),
         {:ok, summary} <- require_string(data, "summary"),
         {:ok, budget_estimate} <- parse_budget_estimate(data),
         {:ok, packing_essentials} <- require_string_list(data, "packingEssentials"),
         {:ok, weather_expected} <- require_string(data, "weatherExpected") do
      %{
        destination: destination,
        duration_days: duration_days,
        tagline: tagline,
        summary: summary,
        budget_estimate: budget_estimate,
        packing_essentials: packing_essentials,
        weather_expected: weather_expected
      }
    else
      {:error, path, message} -> raise validation_error_message(path, message)
    end
  end

  defp validate_result(data) do
    outline = validate_outline(data)

    with {:ok, days} <- parse_days(data),
         {:ok, tips} <- validate_tip_list(data, "tips") do
      Map.merge(outline, %{days: days, tips: tips})
    else
      {:error, path, message} -> raise validation_error_message(path, message)
    end
  end

  defp validate_day(data) do
    with {:ok, day_number} <- require_integer(data, "dayNumber"),
         {:ok, theme} <- require_string(data, "theme"),
         {:ok, morning} <- parse_activity(data, "morning"),
         {:ok, afternoon} <- parse_activity(data, "afternoon"),
         {:ok, evening} <- parse_activity(data, "evening"),
         {:ok, dining_spot} <- parse_dining_spot(data) do
      {:ok,
       %{
         day_number: day_number,
         theme: theme,
         morning: morning,
         afternoon: afternoon,
         evening: evening,
         dining_spot: dining_spot
       }}
    end
  end

  defp validate_tips(data) do
    case validate_tip_list(data, "tips") do
      {:ok, tips} -> tips
      {:error, path, message} -> raise validation_error_message(path, message)
    end
  end

  defp parse_days(data) do
    case Map.get(data, "days") do
      days when is_list(days) and days != [] ->
        days
        |> Enum.with_index()
        |> Enum.reduce_while({:ok, []}, fn {day, index}, {:ok, acc} ->
          case validate_day(day) do
            {:ok, parsed} -> {:cont, {:ok, acc ++ [parsed]}}
            {:error, path, message} -> {:halt, {:error, "days[#{index}].#{path}", message}}
          end
        end)

      _ ->
        {:error, "days", "validation failed"}
    end
  end

  defp parse_budget_estimate(data) do
    case Map.get(data, "budgetEstimate") do
      %{} = budget ->
        with {:ok, total_cost_estimate} <- require_string(budget, "totalCostEstimate"),
             {:ok, hotel_average_night} <- require_string(budget, "hotelAverageNight"),
             {:ok, food_average_day} <- require_string(budget, "foodAverageDay"),
             {:ok, transport_average_day} <- require_string(budget, "transportAverageDay") do
          {:ok,
           %{
             total_cost_estimate: total_cost_estimate,
             hotel_average_night: hotel_average_night,
             food_average_day: food_average_day,
             transport_average_day: transport_average_day
           }}
        end

      _ ->
        {:error, "budgetEstimate", "validation failed"}
    end
  end

  defp parse_activity(data, key) do
    case Map.get(data, key) do
      %{} = activity ->
        with {:ok, title} <- require_string(activity, "title"),
             {:ok, description} <- require_string(activity, "description"),
             {:ok, cost} <- require_string(activity, "cost"),
             {:ok, duration} <- require_string(activity, "duration") do
          {:ok, %{title: title, description: description, cost: cost, duration: duration}}
        else
          {:error, path, message} -> {:error, "#{key}.#{path}", message}
        end

      _ ->
        {:error, key, "validation failed"}
    end
  end

  defp parse_dining_spot(data) do
    case Map.get(data, "diningSpot") do
      %{} = dining ->
        with {:ok, name} <- require_string(dining, "name"),
             {:ok, type} <- require_string(dining, "type"),
             {:ok, price_level} <- require_string(dining, "priceLevel"),
             {:ok, description} <- require_string(dining, "description") do
          {:ok, %{name: name, type: type, price_level: price_level, description: description}}
        else
          {:error, path, message} -> {:error, "diningSpot.#{path}", message}
        end

      _ ->
        {:error, "diningSpot", "validation failed"}
    end
  end

  defp validate_tip_list(data, key) do
    case Map.get(data, key) do
      tips when is_list(tips) and tips != [] ->
        tips
        |> Enum.with_index()
        |> Enum.reduce_while({:ok, []}, fn {tip, index}, {:ok, acc} ->
          with {:ok, category} <- require_string(tip, "category"),
               {:ok, text} <- require_string(tip, "text") do
            {:cont, {:ok, acc ++ [%{category: category, text: text}]}}
          else
            {:error, path, message} -> {:halt, {:error, "#{key}[#{index}].#{path}", message}}
          end
        end)

      _ ->
        {:error, key, "validation failed"}
    end
  end

  defp require_string(data, key) do
    case Map.get(data, key) do
      value when is_binary(value) and value != "" -> {:ok, value}
      _ -> {:error, key, "validation failed"}
    end
  end

  defp require_integer(data, key) do
    case Map.get(data, key) do
      value when is_integer(value) -> {:ok, value}
      value when is_float(value) -> {:ok, trunc(value)}
      _ -> {:error, key, "validation failed"}
    end
  end

  defp require_string_list(data, key) do
    case Map.get(data, key) do
      values when is_list(values) and values != [] ->
        values
        |> Enum.with_index()
        |> Enum.reduce_while({:ok, []}, fn {value, index}, {:ok, acc} ->
          if is_binary(value) and value != "" do
            {:cont, {:ok, acc ++ [value]}}
          else
            {:halt, {:error, "#{key}[#{index}]", "validation failed"}}
          end
        end)

      _ ->
        {:error, key, "validation failed"}
    end
  end

  defp missing_destination?(parsed) do
    destination = Map.get(parsed, "destination") || Map.get(parsed, :destination)
    destination in [nil, ""]
  end

  defp apply_context(parsed, nil), do: parsed

  defp apply_context(parsed, context) when is_map(parsed) do
    parsed
    |> maybe_put_context("destination", Map.get(context, :destination))
    |> maybe_put_context("durationDays", Map.get(context, :duration_days))
  end

  defp apply_context(parsed, _context), do: parsed

  defp maybe_put_context(parsed, _key, nil), do: parsed

  defp maybe_put_context(parsed, key, value) do
    current = Map.get(parsed, key) || Map.get(parsed, String.to_atom(key))

    if current in [nil, ""] do
      Map.put(parsed, key, value)
    else
      parsed
    end
  end

  defp validation_error_message(path, message) do
    "Invalid planner JSON at #{path}: #{message || "validation failed"}"
  end
end
