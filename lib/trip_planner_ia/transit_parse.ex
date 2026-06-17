defmodule TripPlannerIa.TransitParse do
  @moduledoc false

  @type section_key ::
          :ride_apps
          | :routes
          | :metro
          | :buses
          | :fares
          | :tips
          | :other

  @type transit_section :: %{
          key: section_key(),
          title: String.t(),
          icon: String.t(),
          content: String.t()
        }

  @emoji_regex ~r/[\x{2011}-\x{26FF}]|[\x{E000}-\x{F8FF}]|[\x{1F300}-\x{1FAFF}]/u

  @spec parse_transit_sections(String.t()) :: [transit_section()]
  def parse_transit_sections(raw_text) when is_binary(raw_text) do
    raw_text
    |> String.split("###")
    |> Enum.drop(1)
    |> Enum.reduce([], fn segment, acc ->
      segment = String.trim(segment)

      if segment == "" do
        acc
      else
        [build_section(segment) | acc]
      end
    end)
    |> Enum.reverse()
  end

  defp build_section(segment) do
    [title_line | content_lines] = String.split(segment, "\n", parts: 2)
    title_line = String.trim(title_line)

    content =
      case content_lines do
        [rest] -> String.trim(rest)
        _ -> ""
      end

    lowered_title = String.downcase(title_line)
    key = detect_section_key(lowered_title)
    icon = icon_for_key(key)

    clean_title =
      title_line
      |> String.replace(@emoji_regex, "")
      |> String.trim()

    %{
      key: key,
      title: if(clean_title == "", do: title_line, else: clean_title),
      icon: icon,
      content: content
    }
  end

  defp detect_section_key(lowered_title) do
    cond do
      String.contains?(lowered_title, "corrida") or
          String.contains?(lowered_title, "táxi") or
          String.contains?(lowered_title, "taxi") or
          String.contains?(lowered_title, "car") or
          String.contains?(lowered_title, "ride") ->
        :ride_apps

      String.contains?(lowered_title, "rota") or
          String.contains?(lowered_title, "navegação") or
          String.contains?(lowered_title, "navigation") or
          String.contains?(lowered_title, "map") or
          String.contains?(lowered_title, "route") ->
        :routes

      String.contains?(lowered_title, "metrô") or
          String.contains?(lowered_title, "metro") or
          String.contains?(lowered_title, "trem") or
          String.contains?(lowered_title, "train") or
          String.contains?(lowered_title, "rail") ->
        :metro

      String.contains?(lowered_title, "ônibus") or
          String.contains?(lowered_title, "onibus") or
          String.contains?(lowered_title, "bus") or
          String.contains?(lowered_title, "barco") or
          String.contains?(lowered_title, "ferry") ->
        :buses

      String.contains?(lowered_title, "tarifa") or
          String.contains?(lowered_title, "pagamento") or
          String.contains?(lowered_title, "fare") or
          String.contains?(lowered_title, "payment") or
          String.contains?(lowered_title, "card") ->
        :fares

      String.contains?(lowered_title, "dica") or
          String.contains?(lowered_title, "conselho") or
          String.contains?(lowered_title, "tip") or
          String.contains?(lowered_title, "general") or
          String.contains?(lowered_title, "mobilidade") ->
        :tips

      true ->
        :other
    end
  end

  defp icon_for_key(:ride_apps), do: "Car"
  defp icon_for_key(:routes), do: "Smartphone"
  defp icon_for_key(:metro), do: "Train"
  defp icon_for_key(:buses), do: "Bus"
  defp icon_for_key(:fares), do: "CreditCard"
  defp icon_for_key(:tips), do: "Lightbulb"
  defp icon_for_key(:other), do: "Bus"
end