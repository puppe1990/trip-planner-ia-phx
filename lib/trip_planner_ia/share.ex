defmodule TripPlannerIa.Share do
  @moduledoc false

  def encode_trip_plan(trip_plan) do
    trip_plan
    |> Jason.encode!()
    |> :base64.encode()
    |> to_string()
  end

  def decode_shared_trip_plan(base64_data) when is_binary(base64_data) do
    with {:ok, json} <- Base.decode64(base64_data),
         {:ok, parsed} <- Jason.decode(json),
         true <- valid_plan?(parsed) do
      atomize_keys(parsed)
    else
      _ -> nil
    end
  end

  def build_share_url(trip_plan, origin, pathname) do
    b64 = encode_trip_plan(trip_plan)
    origin <> pathname <> "#share=" <> b64
  end

  def parse_share_hash("#share=" <> base64_data) when byte_size(base64_data) > 0 do
    decode_shared_trip_plan(base64_data)
  end

  def parse_share_hash(_), do: nil

  defp valid_plan?(%{"destination" => dest, "days" => days})
       when is_binary(dest) and is_list(days),
       do: true

  defp valid_plan?(_), do: false

  defp atomize_keys(map) when is_map(map) do
    Map.new(map, fn
      {k, v} when is_binary(k) -> {String.to_existing_atom(k), atomize_value(v)}
      {k, v} -> {k, atomize_value(v)}
    end)
  rescue
    ArgumentError ->
      Map.new(map, fn {k, v} -> {k, atomize_value(v)} end)
  end

  defp atomize_value(list) when is_list(list), do: Enum.map(list, &atomize_value/1)
  defp atomize_value(map) when is_map(map), do: atomize_keys(map)
  defp atomize_value(value), do: value
end
