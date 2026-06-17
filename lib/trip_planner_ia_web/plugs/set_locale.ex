defmodule TripPlannerIaWeb.Plugs.SetLocale do
  @moduledoc false
  import Plug.Conn

  @default_locale "pt-BR"
  @supported_locales ~w(pt-BR en)

  def init(opts), do: opts

  def call(conn, _opts) do
    locale =
      conn.cookies["locale"]
      |> normalize_locale()

    Gettext.put_locale(TripPlannerIaWeb.Gettext, gettext_locale(locale))

    conn
    |> assign(:locale, locale)
  end

  def normalize_locale(nil), do: @default_locale

  def normalize_locale(locale) when locale in @supported_locales, do: locale
  def normalize_locale(_), do: @default_locale

  def gettext_locale("pt-BR"), do: "pt_BR"
  def gettext_locale("en"), do: "en"
  def gettext_locale(_), do: "pt_BR"
end