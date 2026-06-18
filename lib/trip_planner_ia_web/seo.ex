defmodule TripPlannerIaWeb.Seo do
  @moduledoc false
  use TripPlannerIaWeb, :html

  alias TripPlannerIaWeb.I18n

  @og_image_type "image/jpeg"
  @og_image_width 1200
  @og_image_height 630

  def meta(assigns) do
    locale = assigns[:locale] || "pt-BR"
    page_title = assigns[:page_title]
    app_name = I18n.t(locale, "app_name")
    title = page_title_title(page_title, app_name)
    description = I18n.t(locale, "seo.description")
    image_url = url(~p"/images/og-preview.jpg")
    page_url = url(~p"/")

    assigns =
      assigns
      |> Map.put(:seo_title, title)
      |> Map.put(:seo_description, description)
      |> Map.put(:seo_image_url, image_url)
      |> Map.put(:seo_page_url, page_url)
      |> Map.put(:seo_image_type, @og_image_type)
      |> Map.put(:seo_image_width, @og_image_width)
      |> Map.put(:seo_image_height, @og_image_height)
      |> Map.put(:seo_locale, og_locale(locale))

    ~H"""
    <meta name="description" content={@seo_description} />
    <link rel="canonical" href={@seo_page_url} />

    <meta property="og:type" content="website" />
    <meta property="og:site_name" content="TripPlanner" />
    <meta property="og:title" content={@seo_title} />
    <meta property="og:description" content={@seo_description} />
    <meta property="og:url" content={@seo_page_url} />
    <meta property="og:locale" content={@seo_locale} />
    <meta property="og:image" content={@seo_image_url} />
    <meta property="og:image:type" content={@seo_image_type} />
    <meta property="og:image:width" content={to_string(@seo_image_width)} />
    <meta property="og:image:height" content={to_string(@seo_image_height)} />
    <meta property="og:image:alt" content={@seo_description} />

    <meta name="twitter:card" content="summary_large_image" />
    <meta name="twitter:title" content={@seo_title} />
    <meta name="twitter:description" content={@seo_description} />
    <meta name="twitter:image" content={@seo_image_url} />
    <meta name="twitter:image:alt" content={@seo_description} />
    """
  end

  defp page_title_title(nil, app_name), do: "#{app_name} · IA"
  defp page_title_title("", app_name), do: "#{app_name} · IA"
  defp page_title_title(page_title, _app_name), do: "#{page_title} · IA"

  defp og_locale("en"), do: "en_US"
  defp og_locale(_), do: "pt_BR"
end
