defmodule TripPlannerIaWeb.Components.AiSettingsModal do
  @moduledoc false
  use TripPlannerIaWeb, :html

  alias TripPlannerIa.AiConfig
  alias TripPlannerIaWeb.I18n

  attr :open, :boolean, default: false
  attr :locale, :string, required: true
  attr :providers, :list, default: []
  attr :provider_id, :string, default: nil
  attr :model, :string, default: nil
  attr :open_select, :string, default: nil
  attr :error, :string, default: nil
  attr :saving, :boolean, default: false

  def ai_settings_trigger(assigns) do
    ~H"""
    <button
      type="button"
      phx-click="open_ai_settings"
      class="p-2 rounded-xl text-slate-500 hover:text-indigo-600 hover:bg-indigo-50 transition-colors cursor-pointer"
      aria-label={I18n.t(@locale, "aiSettings.open")}
      title={I18n.t(@locale, "aiSettings.open")}
    >
      <.icon name="hero-cog-6-tooth" class="size-4" />
    </button>
    """
  end

  def ai_settings_dialog(assigns) do
    selected_provider =
      Enum.find(assigns.providers, &(&1.id == assigns.provider_id))

    model_options =
      if assigns.provider_id do
        AiConfig.get_models_for_provider(assigns.provider_id, assigns.model)
      else
        []
      end

    provider_label =
      case selected_provider do
        %{display_name: name, configured: false} ->
          "#{name} (#{I18n.t(assigns.locale, "aiSettings.unavailable")})"

        %{display_name: name} ->
          name

        _ ->
          I18n.t(assigns.locale, "aiSettings.provider")
      end

    model_label =
      model_options
      |> Enum.find_value(assigns.model, fn %{id: id, label: label} ->
        if id == assigns.model, do: label
      end)
      |> case do
        nil -> assigns.model || I18n.t(assigns.locale, "aiSettings.model")
        label -> label
      end

    assigns =
      assigns
      |> assign(:selected_provider, selected_provider)
      |> assign(:model_options, model_options)
      |> assign(:provider_label, provider_label)
      |> assign(:model_label, model_label)

    ~H"""
    <div :if={@open} class="fixed inset-0 z-[100]" id="ai-settings-modal">
      <div
        class="fixed inset-0 bg-slate-950/40 backdrop-blur-sm"
        phx-click="close_ai_settings"
      />

      <div class="fixed inset-0 overflow-y-auto">
        <div class="flex min-h-full items-center justify-center p-4">
          <div
            role="dialog"
            aria-modal="true"
            aria-labelledby="ai-settings-title"
            class="relative w-full max-w-md overflow-visible bg-white border border-slate-100 rounded-3xl shadow-2xl shadow-slate-200/60 p-6 z-10"
            phx-click-away={JS.push("close_ai_select")}
          >
            <div class="flex items-start justify-between gap-4 mb-6">
              <div class="flex items-center gap-3">
                <div class="w-10 h-10 rounded-2xl bg-indigo-600 flex items-center justify-center text-white shadow-md shadow-indigo-600/20">
                  <.icon name="hero-sparkles" class="size-5" />
                </div>
                <div>
                  <h2 id="ai-settings-title" class="text-lg font-bold text-slate-900">
                    {I18n.t(@locale, "aiSettings.title")}
                  </h2>
                  <p class="text-xs text-slate-500">{I18n.t(@locale, "aiSettings.subtitle")}</p>
                </div>
              </div>
              <button
                type="button"
                phx-click="close_ai_settings"
                class="p-1.5 rounded-lg text-slate-400 hover:text-slate-600 hover:bg-slate-100 transition-colors cursor-pointer"
                aria-label={I18n.t(@locale, "common.cancel")}
              >
                <.icon name="hero-x-mark" class="size-4" />
              </button>
            </div>

            <p
              :if={@error}
              class="mb-4 rounded-xl border border-rose-100 bg-rose-50 px-3 py-2 text-xs text-rose-700"
            >
              {@error}
            </p>

            <div class="space-y-3">
              <div class="rounded-2xl border border-slate-100 bg-slate-50/70 p-4 overflow-visible">
                <p class="text-[10px] font-bold uppercase tracking-wider text-slate-400 mb-2">
                  {I18n.t(@locale, "aiSettings.provider")}
                </p>
                <.settings_menu
                  id="ai-provider"
                  field="provider"
                  open_select={@open_select}
                  label={@provider_label}
                  aria_label={I18n.t(@locale, "aiSettings.provider")}
                >
                  <:option
                    :for={provider <- @providers}
                    value={provider.id}
                    label={
                      provider.display_name <>
                        if(!provider.configured,
                          do: " (#{I18n.t(@locale, "aiSettings.unavailable")})",
                          else: ""
                        )
                    }
                    selected={provider.id == @provider_id}
                    disabled={!provider.configured}
                  />
                </.settings_menu>
              </div>

              <div class="rounded-2xl border border-slate-100 bg-slate-50/70 p-4 overflow-visible">
                <p class="text-[10px] font-bold uppercase tracking-wider text-slate-400 mb-2">
                  {I18n.t(@locale, "aiSettings.model")}
                </p>
                <.settings_menu
                  id="ai-model"
                  field="model"
                  open_select={@open_select}
                  label={@model_label}
                  aria_label={I18n.t(@locale, "aiSettings.model")}
                >
                  <:option
                    :for={option <- @model_options}
                    value={option.id}
                    label={option.label}
                    selected={option.id == @model}
                    disabled={false}
                  />
                </.settings_menu>
              </div>

              <div
                :if={@selected_provider}
                class="rounded-2xl border border-slate-100 bg-slate-50/70 p-4"
              >
                <p class="text-[10px] font-bold uppercase tracking-wider text-slate-400 mb-2">
                  {I18n.t(@locale, "aiSettings.capabilities")}
                </p>
                <div class="flex flex-wrap gap-2">
                  <span class={capability_badge(@selected_provider.capabilities.structured_json)}>
                    {I18n.t(@locale, "aiSettings.structuredJson")}
                  </span>
                  <span class={capability_badge(@selected_provider.capabilities.web_grounding)}>
                    {if @selected_provider.capabilities.web_grounding,
                      do: I18n.t(@locale, "aiSettings.webGrounding"),
                      else: I18n.t(@locale, "aiSettings.webGroundingUnavailable")}
                  </span>
                </div>
              </div>
            </div>

            <div class="mt-5 flex items-center justify-between gap-3">
              <div class="flex items-center gap-2 text-[11px] text-slate-500">
                <.icon name="hero-cpu-chip" class="size-3.5 text-indigo-500" />
                <span>{I18n.t(@locale, "aiSettings.hint")}</span>
              </div>
              <button
                type="button"
                phx-click="save_ai_settings"
                disabled={@saving}
                class="rounded-xl bg-indigo-600 px-4 py-2 text-sm font-semibold text-white shadow-md shadow-indigo-600/20 transition-colors hover:bg-indigo-700 disabled:cursor-not-allowed disabled:opacity-60 cursor-pointer"
              >
                {if @saving,
                  do: I18n.t(@locale, "aiSettings.saving"),
                  else: I18n.t(@locale, "aiSettings.save")}
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :field, :string, required: true
  attr :open_select, :string, default: nil
  attr :label, :string, required: true
  attr :aria_label, :string, required: true

  slot :option, required: true do
    attr :value, :string, required: true
    attr :label, :string, required: true
    attr :selected, :boolean, required: true
    attr :disabled, :boolean, required: true
  end

  defp settings_menu(assigns) do
    assigns =
      assigns
      |> assign(:open?, assigns.open_select == assigns.field)
      |> assign(:select_event, select_event(assigns.field))

    ~H"""
    <div class="relative">
      <button
        type="button"
        id={@id}
        phx-click="toggle_ai_select"
        phx-value-field={@field}
        aria-haspopup="listbox"
        aria-expanded={to_string(@open?)}
        aria-label={@aria_label}
        class="flex w-full items-center justify-between gap-2 rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm font-semibold text-slate-800 focus:outline-none focus:ring-2 focus:ring-indigo-500/30 cursor-pointer"
      >
        <span class="truncate font-mono text-[13px]">{@label}</span>
        <.icon
          name="hero-chevron-down"
          class={["size-4 text-slate-400 transition-transform", @open? && "rotate-180"]}
        />
      </button>

      <ul
        :if={@open?}
        id={"#{@id}-menu"}
        role="listbox"
        aria-labelledby={@id}
        class="absolute left-0 right-0 z-[120] mt-1 max-h-56 overflow-y-auto rounded-xl border border-slate-200 bg-white p-1 shadow-xl shadow-slate-200/70"
      >
        <li :for={option <- @option} role="none">
          <button
            :if={@field == "provider"}
            type="button"
            role="option"
            aria-selected={to_string(option.selected)}
            phx-click={@select_event}
            phx-value-provider={option.value}
            disabled={option.disabled}
            class={option_button_class(option)}
          >
            {option.label}
          </button>
          <button
            :if={@field == "model"}
            type="button"
            role="option"
            aria-selected={to_string(option.selected)}
            phx-click={@select_event}
            phx-value-model={option.value}
            disabled={option.disabled}
            class={option_button_class(option)}
          >
            {option.label}
          </button>
        </li>
      </ul>
    </div>
    """
  end

  defp select_event("provider"), do: "select_ai_provider"
  defp select_event("model"), do: "select_ai_model"

  defp option_button_class(option) do
    [
      "w-full rounded-lg px-3 py-2 text-left text-[13px] font-semibold transition-colors",
      option.selected && "bg-indigo-50 text-indigo-800",
      !option.selected && !option.disabled && "text-slate-700 hover:bg-slate-50",
      option.disabled && "cursor-not-allowed text-slate-400"
    ]
  end

  defp capability_badge(true),
    do:
      "text-[10px] font-bold px-2 py-1 rounded-full border bg-emerald-50 text-emerald-700 border-emerald-100"

  defp capability_badge(false),
    do:
      "text-[10px] font-bold px-2 py-1 rounded-full border bg-slate-100 text-slate-500 border-slate-200"
end
