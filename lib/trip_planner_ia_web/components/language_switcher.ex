defmodule TripPlannerIaWeb.Components.LanguageSwitcher do
  @moduledoc false
  use TripPlannerIaWeb, :html

  attr :locale, :string, required: true
  attr :return_to, :string, default: "/"
  attr :live, :boolean, default: false
  attr :compact, :boolean, default: false

  def language_switcher(assigns) do
    ~H"""
    <div class={[
      "flex items-center gap-0.5 bg-slate-50 border border-slate-100 rounded-xl",
      @compact && "p-0.5",
      !@compact && "gap-1 p-1"
    ]}>
      <.icon
        :if={!@compact}
        name="hero-globe-alt"
        class="size-3.5 text-slate-400 ml-1.5"
      />
      <.locale_link
        locale="pt-BR"
        current={@locale}
        return_to={@return_to}
        live={@live}
        label="PT"
        compact={@compact}
      />
      <.locale_link
        locale="en"
        current={@locale}
        return_to={@return_to}
        live={@live}
        label="EN"
        compact={@compact}
      />
    </div>
    """
  end

  attr :locale, :string, required: true
  attr :current, :string, required: true
  attr :return_to, :string, required: true
  attr :live, :boolean, required: true
  attr :label, :string, required: true
  attr :compact, :boolean, default: false

  defp locale_link(assigns) do
    ~H"""
    <button
      :if={@live}
      type="button"
      phx-click="set_locale"
      phx-value-locale={@locale}
      disabled={@current == @locale}
      class={locale_class(@current, @locale, @compact)}
      aria-label={@label}
      aria-pressed={to_string(@current == @locale)}
    >
      {@label}
    </button>
    <.link
      :if={!@live}
      href={locale_href(@locale, @return_to)}
      class={locale_class(@current, @locale, @compact)}
      aria-label={@label}
    >
      {@label}
    </.link>
    """
  end

  defp locale_class(current, locale, compact) do
    [
      "rounded-lg font-bold transition-all",
      compact && "px-2 py-0.5 text-[9px]",
      !compact && "px-2.5 py-1 text-[10px]",
      current == locale && "bg-indigo-600 text-white shadow-sm",
      current != locale && "text-slate-500 hover:text-slate-700 hover:bg-white"
    ]
  end

  defp locale_href(locale, return_to) do
    "/locale/#{locale}?#{URI.encode_query(%{return_to: return_to})}"
  end
end
