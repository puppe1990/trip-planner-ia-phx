defmodule TripPlannerIaWeb.LocaleController do
  use TripPlannerIaWeb, :controller

  alias TripPlannerIaWeb.Plugs.SetLocale

  def set(conn, %{"locale" => locale} = params) do
    locale = SetLocale.normalize_locale(locale)
    return_to = Map.get(params, "return_to", "/")

    conn
    |> put_resp_cookie("locale", locale,
      max_age: 365 * 24 * 60 * 60,
      same_site: "Lax"
    )
    |> redirect(to: safe_return_to(return_to))
  end

  defp safe_return_to(path) when is_binary(path) do
    if String.starts_with?(path, "/") and not String.starts_with?(path, "//") do
      path
    else
      "/"
    end
  end

  defp safe_return_to(_), do: "/"
end