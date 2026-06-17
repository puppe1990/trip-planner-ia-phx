defmodule TripPlannerIaWeb.Components.LanguageSwitcher do
  @moduledoc false
  use TripPlannerIaWeb, :html

  attr :locale, :string, required: true
  attr :return_to, :string, default: "/"
  attr :live, :boolean, default: false

  def language_switcher(assigns) do
    ~H"""
    <div class="flex items-center gap-1 bg-slate-50 border border-slate-100 rounded-xl p-1">
      <.icon name="hero-globe-alt" class="size-3.5 text-slate-400 ml-1.5" />
      <.locale_link locale="pt-BR" current={@locale} return_to={@return_to} live={@live} label="PT" />
      <.locale_link locale="en" current={@locale} return_to={@return_to} live={@live} label="EN" />
    </div>
    """
  end

  attr :locale, :string, required: true
  attr :current, :string, required: true
  attr :return_to, :string, required: true
  attr :live, :boolean, required: true
  attr :label, :string, required: true

  defp locale_link(assigns) do
    ~H"""
    <button
      :if={@live}
      type="button"
      phx-click="set_locale"
      phx-value-locale={@locale}
      disabled={@current == @locale}
      class={locale_class(@current, @locale)}
      aria-label={@label}
      aria-pressed={to_string(@current == @locale)}
    >
      {@label}
    </button>
    <.link
      :if={!@live}
      href={locale_href(@locale, @return_to)}
      class={locale_class(@current, @locale)}
      aria-label={@label}
    >
      {@label}
    </.link>
    """
  end

  defp locale_class(current, locale) do
    [
      "px-2.5 py-1 rounded-lg text-[10px] font-bold transition-all",
      current == locale && "bg-indigo-600 text-white shadow-sm",
      current != locale && "text-slate-500 hover:text-slate-700 hover:bg-white"
    ]
  end

  defp locale_href(locale, return_to) do
    "/locale/#{locale}?#{URI.encode_query(%{return_to: return_to})}"
  end
end
