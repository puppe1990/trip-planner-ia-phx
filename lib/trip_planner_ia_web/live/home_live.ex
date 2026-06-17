defmodule TripPlannerIaWeb.HomeLive do
  use TripPlannerIaWeb, :live_view

  alias TripPlannerIa.{
    Accounts,
    AiConfig,
    Planner,
    QuickDestinations,
    Transit,
    TripPlan,
    TripPlannerConfig,
    Trips
  }

  alias TripPlannerIa.Llm.Factory
  alias TripPlannerIaWeb.Components.TripView
  alias TripPlannerIaWeb.I18n

  @budget_options [
    %{value: "Baixo", label_key: "budget.economic"},
    %{value: "Médio", label_key: "budget.moderate"},
    %{value: "Alto", label_key: "budget.premium"}
  ]

  @style_options [
    %{value: "Equilibrado", label_key: "style.balanced"},
    %{value: "Aventura", label_key: "style.adventure"},
    %{value: "Cultural", label_key: "style.cultural"},
    %{value: "Relaxante", label_key: "style.relaxing"},
    %{value: "Gastronômico", label_key: "style.foodie"},
    %{value: "Familiar", label_key: "style.family"}
  ]

  @companion_options [
    %{value: "Solo", label_key: "companion.solo"},
    %{value: "Casal", label_key: "companion.couple"},
    %{value: "Amigos", label_key: "companion.friends"},
    %{value: "Família", label_key: "companion.family"}
  ]

  @default_form %{
    "destination" => "",
    "duration" => 4,
    "budget" => "Médio",
    "style" => "Equilibrado",
    "companion" => "Solo",
    "season" => "",
    "extra_notes" => ""
  }

  @impl true
  def mount(_params, _session, socket) do
    locale = locale_from_socket(socket)
    ai_state = load_ai_settings(socket)

    {:ok,
     socket
     |> assign(:page_title, I18n.t(locale, "app_name"))
     |> assign(:locale, locale)
     |> assign(:view_state, :search)
     |> assign(:form, @default_form)
     |> assign(:active_region, QuickDestinations.default_region())
     |> assign(:saved_trips, [])
     |> assign(:saved_search, "")
     |> assign(:active_plan, nil)
     |> assign(:generation_progress, nil)
     |> assign(:loading_message_idx, 0)
     |> assign(:budget_options, @budget_options)
     |> assign(:style_options, @style_options)
     |> assign(:companion_options, @companion_options)
     |> assign(:quick_regions, QuickDestinations.regions())
     |> assign(:active_day, 1)
     |> assign(:travelers_count, 1)
     |> assign(:map_filter_day, 1)
     |> assign(:selected_map_point_id, nil)
     |> assign(:climate_month_index, default_climate_month_index())
     |> assign(:checked_packing, %{})
     |> assign(:share_open, false)
     |> assign(:calendar_open, false)
     |> assign(:start_date, default_start_date())
     |> assign(:share_copied, false)
     |> assign(:transit_data, nil)
     |> assign(:transit_loading, false)
     |> assign(:transit_error, nil)
     |> assign(:transit_tab_index, 0)
     |> assign(:uri, "http://localhost:4000/")
     |> assign(ai_state)
     |> load_saved_trips()}
  end

  @impl true
  def handle_params(params, uri, socket) do
    socket = assign(socket, :uri, uri)

    socket =
      case Map.get(params, "share") do
        nil ->
          case parse_share_fragment(uri) do
            nil -> socket
            plan -> show_shared_plan(socket, plan)
          end

        share_data ->
          case TripPlannerIa.Share.decode_shared_trip_plan(share_data) do
            nil ->
              put_flash(socket, :error, I18n.t(socket.assigns.locale, "errors.invalidShareLink"))

            plan ->
              show_shared_plan(socket, TripPlan.from_atoms(plan))
          end
      end

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={@current_scope}
      locale={@locale}
      ai_settings_open={@ai_settings_open}
      ai_providers={@ai_providers}
      ai_provider_id={@ai_provider_id}
      ai_model={@ai_model}
      ai_settings_error={@ai_settings_error}
      ai_settings_saving={@ai_settings_saving}
    >
      <%= case @view_state do %>
        <% :loading -> %>
          <.loading_view
            locale={@locale}
            progress={@generation_progress}
            message_idx={@loading_message_idx}
          />
        <% :trip -> %>
          <TripView.trip_view
            locale={@locale}
            plan={@active_plan}
            uri={@uri}
            active_day={@active_day}
            travelers_count={@travelers_count}
            map_filter_day={@map_filter_day}
            selected_map_point_id={@selected_map_point_id}
            climate_month_index={@climate_month_index}
            checked_packing={@checked_packing}
            share_open={@share_open}
            calendar_open={@calendar_open}
            start_date={@start_date}
            share_copied={@share_copied}
            transit_data={@transit_data}
            transit_loading={@transit_loading}
            transit_error={@transit_error}
            transit_tab_index={@transit_tab_index}
          />
        <% _ -> %>
          <.search_view
            locale={@locale}
            form={@form}
            active_region={@active_region}
            quick_regions={@quick_regions}
            budget_options={@budget_options}
            style_options={@style_options}
            companion_options={@companion_options}
            saved_trips={@saved_trips}
            saved_search={@saved_search}
          />
      <% end %>
    </Layouts.app>
    """
  end

  @impl true
  def handle_event("update_form", %{"form" => form_params}, socket) do
    form =
      socket.assigns.form
      |> Map.merge(form_params)
      |> maybe_parse_duration()

    {:noreply, assign(socket, :form, form)}
  end

  def handle_event("set_region", %{"region" => region}, socket) do
    region_atom = String.to_existing_atom(region)
    {:noreply, assign(socket, :active_region, region_atom)}
  rescue
    ArgumentError -> {:noreply, socket}
  end

  def handle_event("quick_destination", %{"key" => key}, socket) do
    dest =
      socket.assigns.active_region
      |> QuickDestinations.destinations_for_region()
      |> Enum.find(&(&1.key == key))

    case dest do
      nil ->
        {:noreply, socket}

      %{params: params} ->
        form = stringify_params(params)
        socket = assign(socket, :form, form)
        generate_trip(socket, form)
    end
  end

  def handle_event("submit_search", %{"form" => form_params}, socket) do
    form =
      socket.assigns.form
      |> Map.merge(form_params)
      |> maybe_parse_duration()

    if String.trim(form["destination"] || "") == "" do
      {:noreply, socket}
    else
      socket = assign(socket, :form, form)
      generate_trip(socket, form)
    end
  end

  def handle_event("filter_saved", %{"search" => search}, socket) do
    {:noreply, assign(socket, :saved_search, search)}
  end

  def handle_event("select_trip", %{"id" => id}, socket) do
    plan = Enum.find(socket.assigns.saved_trips, &(&1["id"] == id))

    {:noreply,
     socket
     |> assign(:active_plan, plan)
     |> assign(:view_state, :trip)}
  end

  def handle_event("delete_trip", %{"id" => id}, socket) do
    user_id = socket.assigns.current_scope.user.id
    Trips.delete_trip(user_id, id)

    socket =
      socket
      |> load_saved_trips()
      |> then(fn s ->
        if s.assigns.active_plan && s.assigns.active_plan["id"] == id do
          assign(s, :active_plan, nil)
          |> assign(:view_state, :search)
        else
          s
        end
      end)

    {:noreply, socket}
  end

  def handle_event("back_to_search", _params, socket) do
    {:noreply,
     socket
     |> assign(:view_state, :search)
     |> assign(:active_plan, nil)}
  end

  def handle_event("set_active_day", %{"day" => day}, socket) do
    {:noreply, assign(socket, :active_day, String.to_integer(day))}
  end

  def handle_event("set_travelers", %{"count" => count}, socket) do
    {:noreply, assign(socket, :travelers_count, String.to_integer(count))}
  end

  def handle_event("set_map_filter", %{"day" => "all"}, socket) do
    {:noreply, assign(socket, :map_filter_day, "all")}
  end

  def handle_event("set_map_filter", %{"day" => day}, socket) do
    {:noreply, assign(socket, :map_filter_day, String.to_integer(day))}
  end

  def handle_event("select_map_point", %{"id" => id}, socket) do
    {:noreply, assign(socket, :selected_map_point_id, id)}
  end

  def handle_event("clear_map_point", _params, socket) do
    {:noreply, assign(socket, :selected_map_point_id, nil)}
  end

  def handle_event("set_climate_month", %{"index" => index}, socket) do
    {:noreply, assign(socket, :climate_month_index, String.to_integer(index))}
  end

  def handle_event("toggle_packing", %{"item" => item}, socket) do
    checked = Map.get(socket.assigns.checked_packing, item, false)

    {:noreply,
     assign(socket, :checked_packing, Map.put(socket.assigns.checked_packing, item, !checked))}
  end

  def handle_event("open_share", _params, socket) do
    {:noreply, assign(socket, share_open: true, share_copied: false)}
  end

  def handle_event("close_share", _params, socket) do
    {:noreply, assign(socket, :share_open, false)}
  end

  def handle_event("copy_share_link", _params, socket) do
    {:noreply,
     push_event(socket, "copy_to_clipboard", %{text: share_url(socket)})
     |> assign(:share_copied, true)}
  end

  def handle_event("open_calendar", _params, socket) do
    {:noreply, assign(socket, :calendar_open, true)}
  end

  def handle_event("close_calendar", _params, socket) do
    {:noreply, assign(socket, :calendar_open, false)}
  end

  def handle_event("set_start_date", %{"start_date" => date}, socket) do
    socket =
      socket
      |> assign(:start_date, date)
      |> maybe_update_climate_month(date)

    {:noreply, socket}
  end

  def handle_event("download_calendar", _params, socket) do
    plan = TripPlan.to_atoms(socket.assigns.active_plan)

    case TripPlannerIa.IcsExport.generate(plan, socket.assigns.start_date) do
      nil ->
        {:noreply,
         put_flash(socket, :error, I18n.t(socket.assigns.locale, "errors.genericError"))}

      ics ->
        dest =
          socket.assigns.active_plan["destination"]
          |> String.downcase()
          |> String.replace(~r/[^a-z0-9]/, "_")

        {:noreply,
         push_event(socket, "download", %{
           filename: "roteiro_#{dest}.ics",
           content: ics,
           mime: "text/calendar;charset=utf-8"
         })}
    end
  end

  def handle_event("search_transit", _params, socket) do
    parent = self()
    user_id = socket.assigns.current_scope.user.id
    destination = socket.assigns.active_plan["destination"]
    locale = socket.assigns.locale

    socket =
      socket
      |> assign(:transit_loading, true)
      |> assign(:transit_error, nil)

    Task.start(fn ->
      result =
        try do
          prefs = Accounts.get_user_ai_preferences(user_id)
          ai_config = AiConfig.resolve_ai_config(prefs)
          provider = Factory.create_provider(ai_config)
          Transit.search_transit(provider, destination, locale)
        rescue
          error -> {:error, Exception.message(error)}
        end

      send(parent, {:transit_result, result})
    end)

    {:noreply, socket}
  end

  def handle_event("set_transit_tab", %{"index" => index}, socket) do
    {:noreply, assign(socket, :transit_tab_index, String.to_integer(index))}
  end

  def handle_event("open_ai_settings", _params, socket) do
    {:noreply, assign(socket, ai_settings_open: true, ai_settings_error: nil)}
  end

  def handle_event("close_ai_settings", _params, socket) do
    {:noreply, assign(socket, :ai_settings_open, false)}
  end

  def handle_event("select_ai_provider", %{"provider" => provider_id}, socket) do
    default_model =
      socket.assigns.ai_providers
      |> Enum.find(&(&1.id == provider_id))
      |> then(fn
        nil -> socket.assigns.ai_model
        provider -> provider.default_model
      end)

    {:noreply,
     socket
     |> assign(:ai_provider_id, provider_id)
     |> assign(:ai_model, default_model)}
  end

  def handle_event("select_ai_model", %{"model" => model}, socket) do
    {:noreply, assign(socket, :ai_model, model)}
  end

  def handle_event("save_ai_settings", _params, socket) do
    user_id = socket.assigns.current_scope.user.id
    socket = assign(socket, :ai_settings_saving, true)

    case Accounts.update_user_ai_preferences(user_id, %{
           provider_id: socket.assigns.ai_provider_id,
           model: socket.assigns.ai_model
         }) do
      {:ok, _} ->
        {:noreply,
         socket
         |> assign(:ai_settings_saving, false)
         |> assign(:ai_settings_open, false)
         |> assign(:ai_settings_error, nil)}

      {:error, _} ->
        {:noreply,
         socket
         |> assign(:ai_settings_saving, false)
         |> assign(:ai_settings_error, I18n.t(socket.assigns.locale, "aiSettings.saveError"))}
    end
  end

  @impl true
  def handle_info({:gen_progress, progress}, socket) do
    {:noreply,
     socket
     |> assign(:generation_progress, progress)
     |> assign(:loading_message_idx, rem(socket.assigns.loading_message_idx + 1, 3))}
  end

  def handle_info({:gen_complete, plan}, socket) do
    {:noreply,
     socket
     |> assign(:view_state, :trip)
     |> assign(:active_plan, plan)
     |> assign(:generation_progress, nil)
     |> load_saved_trips()}
  end

  def handle_info({:gen_error, _reason}, socket) do
    {:noreply,
     socket
     |> put_flash(:error, "Failed to generate trip. Please try again.")
     |> assign(:view_state, :search)
     |> assign(:generation_progress, nil)}
  end

  def handle_info(:tick_loading, socket) do
    if socket.assigns.view_state == :loading do
      Process.send_after(self(), :tick_loading, 3000)

      {:noreply,
       assign(socket, :loading_message_idx, rem(socket.assigns.loading_message_idx + 1, 3))}
    else
      {:noreply, socket}
    end
  end

  def handle_info({:transit_result, {:error, message}}, socket) do
    {:noreply,
     socket
     |> assign(:transit_loading, false)
     |> assign(:transit_error, message)}
  end

  def handle_info({:transit_result, result}, socket) do
    {:noreply,
     socket
     |> assign(:transit_loading, false)
     |> assign(:transit_data, result)
     |> assign(:transit_tab_index, 0)
     |> assign(:transit_error, nil)}
  end

  defp generate_trip(socket, form) do
    user_id = socket.assigns.current_scope.user.id
    locale = socket.assigns.locale
    parent = self()

    socket =
      socket
      |> assign(:view_state, :loading)
      |> assign(:active_plan, nil)
      |> assign(:generation_progress, %{phase: "outline"})
      |> assign(:loading_message_idx, 0)
      |> then(fn s ->
        Process.send_after(self(), :tick_loading, 3000)
        s
      end)

    Task.start(fn ->
      run_generation(user_id, form, locale, parent)
    end)

    socket
  end

  defp run_generation(user_id, form, locale, parent) do
    multi_step? = TripPlannerConfig.multi_step_enabled?()
    llm_ready? = llm_configured?()

    try do
      plan =
        if llm_ready? do
          run_with_trip_generation(form, locale, multi_step?, parent, user_id)
        else
          simulate_generation(form, multi_step?, parent)
        end

      persisted = Trips.upsert_trip(user_id, form, plan)
      send(parent, {:gen_complete, persisted})
    rescue
      _ -> send(parent, {:gen_error, :generation_failed})
    end
  end

  defp llm_configured? do
    AiConfig.get_provider_id()
    |> AiConfig.provider_configured?()
  end

  defp run_with_trip_generation(form, locale, multi_step?, parent, user_id) do
    params = atomize_form(form)
    provider = build_provider(user_id)

    deps = %{
      is_multi_step_enabled: fn -> multi_step? end,
      params: params,
      locale: locale,
      on_progress: fn progress -> send(parent, {:gen_progress, progress}) end,
      generate_single_shot: fn p, loc ->
        p
        |> then(&Planner.generate_plan(provider, &1, loc))
        |> then(&Planner.build_trip_plan(&1, p))
        |> TripPlan.from_atoms()
      end,
      generate_outline: fn p, loc -> Planner.generate_outline(provider, p, loc) end,
      generate_day: fn p, loc, day, outline ->
        Planner.generate_day(provider, p, loc, day, outline)
      end,
      generate_tips: fn p, loc, outline, days ->
        Planner.generate_tips(provider, p, loc, outline, days)
      end,
      persist_assembled: fn p, outline, days, tips ->
        outline
        |> Planner.assemble_result(days, tips)
        |> Planner.build_trip_plan(p)
        |> TripPlan.from_atoms()
      end
    }

    TripPlannerIa.TripGeneration.run_trip_generation(deps)
  end

  defp build_provider(user_id) do
    user_id
    |> Accounts.get_user_ai_preferences()
    |> AiConfig.resolve_ai_config()
    |> Factory.create_provider()
  end

  defp simulate_generation(form, multi_step?, parent) do
    params = atomize_form(form)
    duration = params.duration

    if multi_step? do
      send(parent, {:gen_progress, %{phase: "outline"}})
      Process.sleep(600)

      for day <- 1..duration do
        send(parent, {:gen_progress, %{phase: "day", day_number: day, total_days: duration}})
        Process.sleep(500)
      end

      send(parent, {:gen_progress, %{phase: "tips"}})
      Process.sleep(400)
      send(parent, {:gen_progress, %{phase: "saving"}})
      Process.sleep(300)
    else
      Process.sleep(1500)
    end

    mock_plan(params)
  end

  defp mock_plan(params) when is_map(params) do
    destination = Map.get(params, :destination) || Map.get(params, "destination")
    duration = Map.get(params, :duration) || Map.get(params, "duration") || 3

    days =
      Enum.map(1..duration, fn day ->
        mock_day(params, day) |> stringify_keys()
      end)

    %{
      "id" => Ecto.UUID.generate(),
      "destination" => destination,
      "duration_days" => duration,
      "tagline" => "Uma aventura inesquecível em #{destination}",
      "summary" =>
        "Roteiro personalizado pela IA para explorar o melhor de #{destination} em #{duration} dias.",
      "budget_estimate" => %{
        "total_cost_estimate" => "R$ 2.500 - R$ 4.000",
        "hotel_average_night" => "R$ 200 - R$ 350/noite",
        "food_average_day" => "R$ 80 - R$ 120/dia",
        "transport_average_day" => "R$ 40 - R$ 60/dia"
      },
      "packing_essentials" => [
        "Documentos",
        "Protetor solar",
        "Roupas confortáveis",
        "Carregador"
      ],
      "weather_expected" =>
        Map.get(params, :season) || Map.get(params, "season") || "Clima agradável",
      "days" => days,
      "tips" => [
        %{"category" => "Transporte", "text" => "Use transporte público quando possível."},
        %{
          "category" => "Cultura",
          "text" => "Respeite costumes locais e horários de funcionamento."
        }
      ],
      "created_at" => DateTime.utc_now() |> DateTime.to_iso8601(),
      "budget_preference" => Map.get(params, :budget) || Map.get(params, "budget"),
      "style_preference" => Map.get(params, :style) || Map.get(params, "style"),
      "companion_preference" => Map.get(params, :companion) || Map.get(params, "companion")
    }
  end

  defp mock_day(params, day_number) do
    destination = Map.get(params, :destination) || Map.get(params, "destination")

    %{
      day_number: day_number,
      theme: "Dia #{day_number} em #{destination}",
      morning: %{
        title: "Exploração matinal",
        description: "Comece o dia visitando um ponto emblemático de #{destination}.",
        cost: "R$ 30 - R$ 80",
        duration: "2-3h"
      },
      afternoon: %{
        title: "Cultura e gastronomia",
        description: "Almoço local e passeio por bairros históricos.",
        cost: "R$ 50 - R$ 120",
        duration: "3-4h"
      },
      evening: %{
        title: "Pôr do sol e relaxamento",
        description: "Finalize com vista panorâmica e jantar regional.",
        cost: "R$ 60 - R$ 150",
        duration: "2h"
      },
      dining_spot: %{
        name: "Restaurante local recomendado",
        type: "Regional",
        price_level: "$$",
        description: "Culinária típica com ingredientes frescos da região."
      }
    }
  end

  defp load_saved_trips(socket) do
    user_id = socket.assigns.current_scope.user.id
    assign(socket, :saved_trips, Trips.list_trips_for_user(user_id))
  end

  defp maybe_parse_duration(%{"duration" => duration} = form) when is_binary(duration) do
    Map.put(form, "duration", String.to_integer(duration))
  end

  defp maybe_parse_duration(form), do: form

  defp stringify_params(params) do
    params
    |> Enum.map(fn
      {k, v} when is_atom(k) -> {Atom.to_string(k), v}
      {k, v} -> {k, v}
    end)
    |> Map.new()
    |> Map.put_new("duration", 4)
  end

  defp atomize_form(form) do
    %{
      destination: form["destination"],
      duration: form["duration"] || 4,
      budget: form["budget"],
      style: form["style"],
      companion: form["companion"],
      season: form["season"],
      extra_notes: form["extra_notes"]
    }
  end

  defp stringify_keys(map) when is_map(map) do
    Map.new(map, fn
      {key, value} when is_atom(key) -> {Atom.to_string(key), stringify_keys(value)}
      {key, value} -> {key, stringify_keys(value)}
    end)
  end

  defp stringify_keys(value), do: value

  defp locale_from_socket(socket) do
    case Phoenix.LiveView.get_connect_info(socket, :cookies) do
      %{"locale" => locale} -> TripPlannerIaWeb.Plugs.SetLocale.normalize_locale(locale)
      _ -> socket.assigns[:locale] || "pt-BR"
    end
  rescue
    _ -> socket.assigns[:locale] || "pt-BR"
  end

  defp load_ai_settings(socket) do
    user_id = socket.assigns.current_scope.user.id
    prefs = Accounts.get_user_ai_preferences(user_id)
    config = AiConfig.resolve_ai_config(prefs)

    %{
      ai_settings_open: false,
      ai_providers: AiConfig.list_provider_options(),
      ai_provider_id: config.provider_id,
      ai_model: config.model,
      ai_settings_error: nil,
      ai_settings_saving: false
    }
  end

  defp default_start_date do
    Date.utc_today() |> Date.add(1) |> Date.to_iso8601()
  end

  defp default_climate_month_index do
    Date.utc_today() |> Date.add(1) |> then(& &1.month) |> Kernel.-(1)
  end

  defp maybe_update_climate_month(socket, date) do
    case Date.from_iso8601(date) do
      {:ok, parsed} -> assign(socket, :climate_month_index, parsed.month - 1)
      _ -> socket
    end
  end

  defp show_shared_plan(socket, plan) do
    socket
    |> assign(:active_plan, plan)
    |> assign(:view_state, :trip)
    |> assign(:active_day, 1)
    |> assign(:map_filter_day, 1)
  end

  defp parse_share_fragment(uri) do
    uri
    |> URI.parse()
    |> Map.get(:fragment)
    |> case do
      nil -> nil
      fragment -> TripPlannerIa.Share.parse_share_hash(fragment)
    end
    |> case do
      nil -> nil
      plan -> TripPlan.from_atoms(plan)
    end
  end

  defp share_url(socket) do
    TripPlannerIa.Share.build_share_url(
      socket.assigns.active_plan,
      origin_from_uri(socket.assigns.uri),
      "/"
    )
  end

  defp origin_from_uri(uri) do
    %URI{scheme: scheme, host: host, port: port} = URI.parse(uri)
    port_part = if port in [nil, 80, 443], do: "", else: ":#{port}"
    "#{scheme}://#{host}#{port_part}"
  rescue
    _ -> "http://localhost:4000"
  end

  # --- Template components ---

  defp search_view(assigns) do
    destinations = QuickDestinations.destinations_for_region(assigns.active_region)
    assigns = assign(assigns, :quick_destinations, destinations)

    ~H"""
    <div class="space-y-12" id="search-section">
      <div class="space-y-3">
        <h3 class="text-sm font-semibold uppercase tracking-wider text-slate-500 flex items-center gap-2">
          <.icon name="hero-sparkles" class="size-4 text-amber-500" />
          {I18n.t(@locale, "search.quick_title")}
        </h3>
        <p class="text-xs text-slate-500">{I18n.t(@locale, "search.quick_subtitle")}</p>

        <div class="flex flex-wrap gap-2">
          <%= for region <- @quick_regions do %>
            <button
              type="button"
              phx-click="set_region"
              phx-value-region={region.id}
              class={[
                "inline-flex items-center gap-1.5 px-3.5 py-2 rounded-full text-sm font-medium transition-all cursor-pointer border",
                @active_region == region.id &&
                  "bg-amber-500 text-white border-amber-500 shadow-md shadow-amber-500/25",
                @active_region != region.id &&
                  "bg-white text-slate-600 border-slate-200 hover:border-amber-300 hover:text-amber-700 hover:bg-amber-50/50"
              ]}
            >
              <span class="text-base leading-none">{region.emoji}</span>
              <span>{if @locale == "en", do: region.label_en, else: region.label_pt}</span>
            </button>
          <% end %>
        </div>

        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          <%= for dest <- @quick_destinations do %>
            <button
              type="button"
              phx-click="quick_destination"
              phx-value-key={dest.key}
              class="text-left p-4 rounded-2xl bg-white border border-slate-100 hover:border-slate-200 shadow-sm hover:shadow-md transition-all duration-300 flex flex-col justify-between h-36 relative overflow-hidden group cursor-pointer"
            >
              <div class={[
                "absolute top-0 right-0 w-24 h-24 bg-gradient-to-br opacity-5 group-hover:opacity-10 rounded-full blur-xl transition-all duration-500",
                dest.bg_gradient
              ]} />
              <div class="flex justify-between items-start">
                <span class="text-3xl filter drop-shadow-sm">{dest.emoji}</span>
                <span class="text-[10px] uppercase tracking-wide font-semibold text-slate-400 bg-slate-50 py-1 px-2 rounded-full">
                  {dest.params.duration} {I18n.t(@locale, "days")}
                </span>
              </div>
              <div>
                <h4 class="font-bold text-slate-800 group-hover:text-amber-600 transition-colors duration-200">
                  {if @locale == "en", do: dest.name_en, else: dest.name_pt}
                </h4>
                <p class="text-xs text-slate-400 line-clamp-2 mt-1">
                  {if @locale == "en", do: dest.tagline_en, else: dest.tagline_pt}
                </p>
              </div>
            </button>
          <% end %>
        </div>
      </div>

      <hr class="border-slate-100" />

      <.form
        for={%{}}
        as={:form}
        phx-change="update_form"
        phx-submit="submit_search"
        class="bg-white rounded-3xl border border-slate-100 shadow-xl shadow-slate-100/40 p-6 md:p-8 space-y-6"
      >
        <h2 class="text-xl font-bold text-slate-800 flex items-center gap-2">
          <.icon name="hero-map" class="size-5 text-indigo-600" />
          {I18n.t(@locale, "search.form_title")}
        </h2>

        <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div class="md:col-span-2 space-y-2">
            <label class="block text-sm font-medium text-slate-700 flex items-center gap-2">
              <.icon name="hero-map-pin" class="size-4 text-rose-500" />
              {I18n.t(@locale, "search.destination")}
            </label>
            <input
              type="text"
              name="form[destination]"
              value={@form["destination"]}
              required
              placeholder={I18n.t(@locale, "search.destination_placeholder")}
              class="w-full px-4 py-3 rounded-xl border border-slate-200 focus:border-indigo-500 focus:ring-2 focus:ring-indigo-100 transition-all text-slate-800 placeholder-slate-400 font-medium"
            />
          </div>

          <div class="space-y-2">
            <label class="block text-sm font-medium text-slate-700 flex items-center gap-2">
              <.icon name="hero-calendar-days" class="size-4 text-emerald-500" />
              {I18n.t(@locale, "search.duration", %{count: @form["duration"]})}
            </label>
            <div class="flex items-center gap-4 bg-slate-50 p-2.5 rounded-xl border border-slate-200/60">
              <input
                type="range"
                name="form[duration]"
                min="1"
                max="10"
                value={@form["duration"]}
                class="w-full accent-indigo-600 cursor-pointer"
              />
              <span class="text-sm font-bold text-slate-700 bg-white shadow-sm border border-slate-100 px-3 py-1 rounded-lg min-w-[50px] text-center">
                {@form["duration"]}d
              </span>
            </div>
          </div>
        </div>

        <div class="space-y-3">
          <label class="block text-sm font-medium text-slate-700">
            {I18n.t(@locale, "search.budget")}
          </label>
          <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
            <%= for option <- @budget_options do %>
              <button
                type="button"
                phx-click={JS.push("update_form", value: %{form: %{budget: option.value}})}
                class={[
                  "text-left p-4 rounded-xl border transition-all flex flex-col justify-between cursor-pointer",
                  @form["budget"] == option.value &&
                    "border-indigo-600 bg-indigo-50/40 ring-2 ring-indigo-100",
                  @form["budget"] != option.value &&
                    "border-slate-100 bg-slate-50/50 hover:bg-slate-50"
                ]}
              >
                <span class="font-bold text-slate-800 text-sm">
                  {I18n.t(@locale, option.label_key)}
                </span>
              </button>
            <% end %>
          </div>
        </div>

        <div class="space-y-3">
          <label class="block text-sm font-medium text-slate-700">
            {I18n.t(@locale, "search.travel_style")}
          </label>
          <div class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-3">
            <%= for style <- @style_options do %>
              <button
                type="button"
                phx-click={JS.push("update_form", value: %{form: %{style: style.value}})}
                class={[
                  "text-center p-3 rounded-xl border transition-all cursor-pointer",
                  @form["style"] == style.value &&
                    "border-indigo-600 bg-indigo-50/30 text-indigo-700 font-semibold",
                  @form["style"] != style.value &&
                    "border-slate-100 bg-slate-50/50 text-slate-600 hover:bg-slate-50"
                ]}
              >
                <span class="text-sm">{I18n.t(@locale, style.label_key)}</span>
              </button>
            <% end %>
          </div>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div class="space-y-3">
            <label class="block text-sm font-medium text-slate-700 flex items-center gap-2">
              <.icon name="hero-user-group" class="size-4 text-indigo-500" />
              {I18n.t(@locale, "search.companion")}
            </label>
            <div class="grid grid-cols-2 gap-2">
              <%= for item <- @companion_options do %>
                <button
                  type="button"
                  phx-click={JS.push("update_form", value: %{form: %{companion: item.value}})}
                  class={[
                    "text-left p-3 rounded-lg border text-xs transition-all flex items-center justify-between cursor-pointer",
                    @form["companion"] == item.value &&
                      "border-indigo-600 bg-indigo-50/20 text-indigo-700 font-semibold",
                    @form["companion"] != item.value &&
                      "border-slate-100 bg-slate-50/35 hover:bg-slate-50"
                  ]}
                >
                  <span>{I18n.t(@locale, item.label_key)}</span>
                </button>
              <% end %>
            </div>
          </div>

          <div class="space-y-3">
            <label class="block text-sm font-medium text-slate-700 flex items-center gap-2">
              <.icon name="hero-calendar" class="size-4 text-sky-500" />
              {I18n.t(@locale, "search.season")}
            </label>
            <input
              type="text"
              name="form[season]"
              value={@form["season"]}
              placeholder={I18n.t(@locale, "search.season_placeholder")}
              class="w-full px-4 py-3 rounded-xl border border-slate-200 focus:border-indigo-500 focus:ring-2 focus:ring-indigo-100 transition-all text-slate-800"
            />
          </div>
        </div>

        <div class="space-y-2">
          <label class="block text-sm font-medium text-slate-700 flex items-center gap-2">
            <.icon name="hero-pencil-square" class="size-4 text-purple-500" />
            {I18n.t(@locale, "search.notes")}
          </label>
          <textarea
            name="form[extra_notes]"
            rows="3"
            placeholder={I18n.t(@locale, "search.notes_placeholder")}
            class="w-full px-4 py-3 rounded-xl border border-slate-200 focus:border-indigo-500 focus:ring-2 focus:ring-indigo-100 transition-all text-slate-800 text-sm"
          >{@form["extra_notes"]}</textarea>
        </div>

        <div class="pt-2 flex justify-end">
          <button
            type="submit"
            class="w-full md:w-auto px-8 py-4 bg-indigo-600 hover:bg-indigo-700 text-white rounded-xl shadow-lg shadow-indigo-600/20 font-bold transition-all flex items-center justify-center gap-2 cursor-pointer disabled:opacity-50"
          >
            <.icon name="hero-sparkles" class="size-5 animate-pulse" />
            {I18n.t(@locale, "search.submit")}
          </button>
        </div>
      </.form>

      <div id="saved-trips" class="scroll-mt-24">
        <hr class="border-slate-100" />
        <.saved_trips_section
          locale={@locale}
          saved_trips={@saved_trips}
          saved_search={@saved_search}
        />
      </div>
    </div>
    """
  end

  defp saved_trips_section(assigns) do
    filtered =
      assigns.saved_trips
      |> Enum.filter(fn trip ->
        term = String.downcase(assigns.saved_search)

        term == "" ||
          String.contains?(String.downcase(trip["destination"] || ""), term)
      end)

    assigns = assign(assigns, :filtered_trips, filtered)

    ~H"""
    <div class="pt-8 space-y-6">
      <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h2 class="text-xl font-bold text-slate-800 flex items-center gap-2">
            <.icon name="hero-briefcase" class="size-5 text-indigo-600" />
            {I18n.t(@locale, "saved.title", %{count: length(@saved_trips)})}
          </h2>
          <p class="text-xs text-slate-500 mt-1">{I18n.t(@locale, "saved.subtitle")}</p>
        </div>

        <div :if={@saved_trips != []} class="relative w-full sm:w-64">
          <.icon
            name="hero-magnifying-glass"
            class="size-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2"
          />
          <input
            type="text"
            name="search"
            value={@saved_search}
            phx-change="filter_saved"
            placeholder={I18n.t(@locale, "saved.search_placeholder")}
            class="w-full pl-9 pr-4 py-2 text-xs rounded-xl border border-slate-200 focus:border-indigo-500 focus:ring-1 focus:ring-indigo-100 transition-all text-slate-700 bg-white"
          />
        </div>
      </div>

      <%= cond do %>
        <% @saved_trips == [] -> %>
          <div class="text-center py-12 px-4 rounded-3xl border border-dashed border-slate-200 bg-slate-50/50 flex flex-col items-center justify-center space-y-4">
            <div class="w-14 h-14 rounded-full bg-indigo-50 text-indigo-500 flex items-center justify-center">
              <.icon name="hero-map" class="size-7" />
            </div>
            <div class="space-y-1">
              <h3 class="font-bold text-slate-800 text-sm">{I18n.t(@locale, "saved.empty_title")}</h3>
              <p class="text-xs text-slate-400 max-w-xs mx-auto text-center leading-relaxed">
                {I18n.t(@locale, "saved.empty_desc")}
              </p>
            </div>
          </div>
        <% @filtered_trips == [] -> %>
          <div class="text-center py-8 text-slate-500 text-xs">
            {I18n.t(@locale, "saved.no_results", %{term: @saved_search})}
          </div>
        <% true -> %>
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            <%= for trip <- @filtered_trips do %>
              <div
                class="group relative cursor-pointer bg-white border border-slate-100 rounded-2xl overflow-hidden shadow-sm hover:shadow-md transition-all duration-300 flex flex-col justify-between h-56"
                phx-click="select_trip"
                phx-value-id={trip["id"]}
              >
                <div class="p-4 bg-gradient-to-r from-sky-500 via-indigo-500 to-indigo-600 text-white flex justify-between items-start h-24">
                  <div class="space-y-1 max-w-[80%]">
                    <span class="text-[9px] uppercase tracking-wider font-extrabold bg-white/20 px-2 py-0.5 rounded-full backdrop-blur-sm">
                      {trip["duration_days"]} {I18n.t(@locale, "days")}
                    </span>
                    <h3 class="font-extrabold text-base leading-tight truncate drop-shadow-sm text-white">
                      {trip["destination"]}
                    </h3>
                  </div>
                  <button
                    type="button"
                    phx-click="delete_trip"
                    phx-value-id={trip["id"]}
                    onclick="event.stopPropagation()"
                    class="p-1.5 rounded-lg bg-white/10 hover:bg-rose-500/80 transition-colors"
                  >
                    <.icon name="hero-trash" class="size-4" />
                  </button>
                </div>
                <div class="p-4 flex-1 flex flex-col justify-between">
                  <p class="text-xs text-slate-500 italic line-clamp-2">"{trip["tagline"]}"</p>
                  <span class="text-[10px] text-indigo-600 font-semibold flex items-center gap-1 mt-2">
                    <.icon name="hero-sparkles" class="size-3" /> IA
                  </span>
                </div>
              </div>
            <% end %>
          </div>
      <% end %>
    </div>
    """
  end

  defp loading_view(assigns) do
    message =
      case assigns.progress do
        %{phase: "day", day_number: day, total_days: total} ->
          I18n.t(assigns.locale, "loading.step.day", %{day: day, total: total})

        %{phase: phase} when is_binary(phase) ->
          I18n.t(assigns.locale, "loading.step.#{phase}", %{})

        _ ->
          key = "loading.msg_#{assigns.message_idx + 1}"
          I18n.t(assigns.locale, key, %{})
      end

    assigns = assign(assigns, :message, message)

    ~H"""
    <div class="py-16 flex flex-col items-center justify-center space-y-8 max-w-md mx-auto text-center">
      <div class="relative">
        <div class="w-20 h-20 rounded-full border-4 border-indigo-100 border-t-indigo-600 animate-spin" />
        <div class="absolute inset-0 flex items-center justify-center">
          <.icon name="hero-paper-airplane" class="size-7 text-indigo-600 animate-pulse" />
        </div>
      </div>

      <div class="space-y-3">
        <div class="flex items-center justify-center gap-1">
          <span class="w-2 h-2 rounded-full bg-amber-500 animate-bounce" />
          <span class="text-xs font-black uppercase text-amber-600 tracking-wider">
            {I18n.t(@locale, "loading.title")}
          </span>
        </div>
        <h3 class="text-xl font-bold text-slate-800 transition-all duration-300">{@message}</h3>
        <p class="text-xs text-slate-500 leading-relaxed max-w-xs mx-auto">
          {I18n.t(@locale, "loading.hint")}
        </p>
      </div>

      <div class="bg-indigo-50/40 border border-indigo-100 p-4 rounded-2xl space-y-1 text-left w-full">
        <h4 class="text-xs font-bold text-indigo-900 flex items-center gap-1.5">
          <.icon name="hero-information-circle" class="size-3.5 text-indigo-500" />
          {I18n.t(@locale, "loading.did_you_know")}
        </h4>
        <p class="text-[11px] text-indigo-900/80 leading-relaxed">{I18n.t(@locale, "loading.tip")}</p>
      </div>
    </div>
    """
  end
end
