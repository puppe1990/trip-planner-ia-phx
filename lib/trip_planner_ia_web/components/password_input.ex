defmodule TripPlannerIaWeb.Components.PasswordInput do
  @moduledoc false
  use TripPlannerIaWeb, :html

  attr :id, :string, required: true
  attr :name, :string, required: true
  attr :value, :string, default: nil
  attr :locale, :string, default: "pt-BR"
  attr :required, :boolean, default: false
  attr :minlength, :integer, default: nil
  attr :autocomplete, :string, default: "current-password"
  attr :class, :string, default: nil

  def password_input(assigns) do
    input_class =
      assigns.class ||
        "w-full px-4 py-3 pr-11 rounded-xl border border-slate-200 focus:border-indigo-500 focus:ring-2 focus:ring-indigo-100 transition-all"

    assigns =
      assigns
      |> assign(:input_class, input_class)
      |> assign(:show_label, TripPlannerIaWeb.I18n.t(assigns.locale, "auth.show_password"))
      |> assign(:hide_label, TripPlannerIaWeb.I18n.t(assigns.locale, "auth.hide_password"))

    ~H"""
    <div class="relative">
      <input
        id={@id}
        name={@name}
        type="password"
        value={@value}
        required={@required}
        minlength={@minlength}
        autocomplete={@autocomplete}
        spellcheck="false"
        class={@input_class}
      />
      <button
        type="button"
        class="absolute inset-y-0 right-0 flex items-center px-3 text-slate-400 hover:text-slate-600 transition-colors"
        aria-label={@show_label}
        onclick={"const input = document.getElementById('#{@id}'); const visible = input.type === 'text'; input.type = visible ? 'password' : 'text'; this.setAttribute('aria-label', visible ? '#{@show_label}' : '#{@hide_label}');"}
      >
        <.icon name="hero-eye" class="size-4" />
      </button>
    </div>
    """
  end
end
