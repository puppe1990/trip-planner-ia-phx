defmodule TripPlannerIa.Config.EnvLoader do
  @moduledoc false

  def load_dotenv(path \\ nil) do
    path = path || Path.expand(".env", File.cwd!())

    if File.exists?(path) do
      path
      |> File.read!()
      |> parse_and_put_env()
    end

    :ok
  end

  defp parse_and_put_env(contents) do
    contents
    |> String.split("\n", trim: true)
    |> Enum.each(&parse_line/1)
  end

  defp parse_line("#" <> _), do: :ok
  defp parse_line(""), do: :ok

  defp parse_line(line) do
    case String.split(line, "=", parts: 2) do
      [key, value] ->
        key = String.trim(key)

        if key != "" and env_blank?(System.get_env(key)) do
          System.put_env(key, unquote_value(String.trim(value)))
        end

        :ok

      _ ->
        :ok
    end
  end

  defp env_blank?(nil), do: true
  defp env_blank?(value), do: String.trim(value) == ""

  defp unquote_value(value) do
    value
    |> String.trim_leading("\"")
    |> String.trim_trailing("\"")
    |> String.trim_leading("'")
    |> String.trim_trailing("'")
  end
end
