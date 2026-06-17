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
  attr :error, :string, default: nil
  attr :saving, :boolean, default: false

  def ai_settings_modal(assigns) do
    selected_provider =
      Enum.find(assigns.providers, &(&1.id == assigns.provider_id))

    model_options =
      if assigns.provider_id do
        AiConfig.get_models_for_provider(assigns.provider_id, assigns.model)
      else
        []
      end

    assigns =
      assigns
      |> assign(:selected_provider, selected_provider)
      |> assign(:model_options, model_options)

    ~H"""
    <button
      :if={!@open}
      type="button"
      phx-click="open_ai_settings"
      class="p-2 rounded-xl text-slate-500 hover:text-indigo-600 hover:bg-indigo-50 transition-colors cursor-pointer"
      aria-label={I18n.t(@locale, "aiSettings.open")}
      title={I18n.t(@locale, "aiSettings.open")}
    >
      <.icon name="hero-cog-6-tooth" class="size-4" />
    </button>

    <div :if={@open} class="fixed inset-0 z-50 overflow-y-auto" id="ai-settings-modal">
      <div
        class="fixed inset-0 bg-slate-950/40 backdrop-blur-sm"
        phx-click="close_ai_settings"
      />

      <div class="flex min-h-screen items-center justify-center p-4">
        <div
          role="dialog"
          aria-modal="true"
          aria-labelledby="ai-settings-title"
          class="relative w-full max-w-md bg-white border border-slate-100 rounded-3xl shadow-2xl shadow-slate-200/60 p-6 z-10"
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
            <div class="rounded-2xl border border-slate-100 bg-slate-50/70 p-4">
              <label
                for="ai-provider"
                class="text-[10px] font-bold uppercase tracking-wider text-slate-400 mb-2 block"
              >
                {I18n.t(@locale, "aiSettings.provider")}
              </label>
              <select
                id="ai-provider"
                name="provider"
                phx-change="select_ai_provider"
                class="w-full rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm font-semibold text-slate-800 focus:outline-none focus:ring-2 focus:ring-indigo-500/30"
              >
                <%= for provider <- @providers do %>
                  <option
                    value={provider.id}
                    selected={provider.id == @provider_id}
                    disabled={!provider.configured}
                  >
                    {provider.display_name}
                    {if !provider.configured, do: " (#{I18n.t(@locale, "aiSettings.unavailable")})"}
                  </option>
                <% end %>
              </select>
            </div>

            <div class="rounded-2xl border border-slate-100 bg-slate-50/70 p-4">
              <label
                for="ai-model"
                class="text-[10px] font-bold uppercase tracking-wider text-slate-400 mb-2 block"
              >
                {I18n.t(@locale, "aiSettings.model")}
              </label>
              <select
                id="ai-model"
                name="model"
                phx-change="select_ai_model"
                class="w-full rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm font-semibold text-slate-800 focus:outline-none focus:ring-2 focus:ring-indigo-500/30"
              >
                <%= for option <- @model_options do %>
                  <option value={option.id} selected={option.id == @model}>
                    {option.label}
                  </option>
                <% end %>
              </select>
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
    """
  end

  defp capability_badge(true),
    do:
      "text-[10px] font-bold px-2 py-1 rounded-full border bg-emerald-50 text-emerald-700 border-emerald-100"

  defp capability_badge(false),
    do:
      "text-[10px] font-bold px-2 py-1 rounded-full border bg-slate-100 text-slate-500 border-slate-200"
end
