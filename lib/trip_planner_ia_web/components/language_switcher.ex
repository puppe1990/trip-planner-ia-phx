defmodule TripPlannerIaWeb.Components.LanguageSwitcher do
  @moduledoc false
  use TripPlannerIaWeb, :html

  attr :locale, :string, required: true
  attr :return_to, :string, default: "/"

  def language_switcher(assigns) do
    ~H"""
    <div class="flex items-center gap-1 bg-slate-50 border border-slate-100 rounded-xl p-1">
      <.icon name="hero-globe-alt" class="size-3.5 text-slate-400 ml-1.5" />
      <.locale_link locale="pt-BR" current={@locale} return_to={@return_to} label="PT" />
      <.locale_link locale="en" current={@locale} return_to={@return_to} label="EN" />
    </div>
    """
  end

  attr :locale, :string, required: true
  attr :current, :string, required: true
  attr :return_to, :string, required: true
  attr :label, :string, required: true

  defp locale_link(assigns) do
    ~H"""
    <.link
      href={~p"/locale/#{@locale}?return_to=#{@return_to}"}
      class={[
        "px-2.5 py-1 rounded-lg text-[10px] font-bold transition-all",
        @current == @locale && "bg-indigo-600 text-white shadow-sm",
        @current != @locale && "text-slate-500 hover:text-slate-700 hover:bg-white"
      ]}
    >
      {@label}
    </.link>
    """
  end
end