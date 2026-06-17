defmodule TripPlannerIaWeb.Plugs.SetLocale do
  @moduledoc false
  import Plug.Conn

  @default_locale "pt-BR"
  @supported_locales ~w(pt-BR en)

  def init(opts), do: opts

  def call(conn, _opts) do
    conn = fetch_cookies(conn)
    locale = fetch_locale(conn)

    Gettext.put_locale(TripPlannerIaWeb.Gettext, gettext_locale(locale))

    conn
    |> assign(:locale, locale)
  end

  def fetch_locale(conn) do
    conn
    |> get_session(:locale)
    |> locale_or(cookie_locale(conn))
    |> normalize_locale()
  end

  defp cookie_locale(%Plug.Conn{cookies: %Plug.Conn.Unfetched{}}), do: nil

  defp cookie_locale(%Plug.Conn{cookies: cookies}), do: cookies["locale"]

  defp locale_or(nil, cookie), do: cookie
  defp locale_or(locale, _cookie), do: locale

  def normalize_locale(nil), do: @default_locale

  def normalize_locale(locale) when locale in @supported_locales, do: locale
  def normalize_locale(_), do: @default_locale

  def gettext_locale("pt-BR"), do: "pt_BR"
  def gettext_locale("en"), do: "en"
  def gettext_locale(_), do: "pt_BR"
end
