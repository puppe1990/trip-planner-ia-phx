defmodule TripPlannerIaWeb.Components.TripView do
  @moduledoc false
  use TripPlannerIaWeb, :html

  alias TripPlannerIa.{Budget, Climate, MapPoints, Share, TripPlan}
  alias TripPlannerIaWeb.I18n

  attr :locale, :string, required: true
  attr :plan, :map, required: true
  attr :uri, :string, default: "http://localhost:4000/"
  attr :active_day, :integer, default: 1
  attr :travelers_count, :integer, default: 1
  attr :map_filter_day, :any, default: 1
  attr :selected_map_point_id, :string, default: nil
  attr :climate_month_index, :integer, default: 0
  attr :checked_packing, :map, default: %{}
  attr :share_open, :boolean, default: false
  attr :calendar_open, :boolean, default: false
  attr :start_date, :string, default: ""
  attr :share_copied, :boolean, default: false
  attr :transit_data, :map, default: nil
  attr :transit_loading, :boolean, default: false
  attr :transit_error, :string, default: nil
  attr :transit_tab_index, :integer, default: 0

  def trip_view(assigns) do
    atom_plan = TripPlan.to_atoms(assigns.plan)
    destination = assigns.plan["destination"]
    days = assigns.plan["days"] || []
    climate = Climate.get_destination_climate(destination)
    budget = Budget.calculate_group_budget(atom_plan, assigns.travelers_count)
    map_points = MapPoints.build_map_points(atom_plan)

    filtered_points =
      case assigns.map_filter_day do
        "all" ->
          map_points

        day when is_integer(day) ->
          Enum.filter(map_points, &(&1.day_number == day))

        day when is_binary(day) ->
          Enum.filter(map_points, &(&1.day_number == String.to_integer(day)))

        _ ->
          map_points
      end

    routes_path = MapPoints.build_routes_path(filtered_points)
    selected_point = Enum.find(filtered_points, &(&1.id == assigns.selected_map_point_id))
    share_url = Share.build_share_url(assigns.plan, origin_from_uri(assigns.uri), "/")

    climate_month =
      climate.months
      |> Enum.at(assigns.climate_month_index, hd(climate.months))

    transit_sections =
      case assigns.transit_data do
        %{raw_text: text} when is_binary(text) ->
          TripPlannerIa.TransitParse.parse_transit_sections(text)

        _ ->
          []
      end

    active_transit_section = Enum.at(transit_sections, assigns.transit_tab_index)

    active_day_plan =
      Enum.find(days, &(Map.get(&1, "day_number") == assigns.active_day)) || List.first(days)

    assigns =
      assigns
      |> assign(:destination, destination)
      |> assign(:days, days)
      |> assign(:climate, climate)
      |> assign(:budget, budget)
      |> assign(:filtered_points, filtered_points)
      |> assign(:routes_path, routes_path)
      |> assign(:selected_point, selected_point)
      |> assign(:share_url, share_url)
      |> assign(:climate_month, climate_month)
      |> assign(:transit_sections, transit_sections)
      |> assign(:active_transit_section, active_transit_section)
      |> assign(:active_day_plan, active_day_plan)
      |> assign(:duration_days, assigns.plan["duration_days"])
      |> assign(:packing_items, assigns.plan["packing_essentials"] || [])
      |> assign(:tips, assigns.plan["tips"] || [])
      |> assign(:budget_estimate, assigns.plan["budget_estimate"] || %{})

    ~H"""
    <div class="space-y-8" id="trip-view-container">
      <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 bg-slate-50 border border-slate-100 p-4 rounded-2xl print:hidden">
        <button
          type="button"
          phx-click="back_to_search"
          class="flex items-center gap-2 text-sm text-slate-600 hover:text-indigo-600 font-semibold cursor-pointer transition-colors"
        >
          <.icon name="hero-arrow-left" class="size-4" />
          {I18n.t(@locale, "back")}
        </button>

        <div class="flex flex-wrap items-center gap-3 w-full sm:w-auto">
          <button
            type="button"
            phx-click="open_share"
            class="flex items-center gap-2 text-xs font-semibold bg-white text-slate-700 hover:text-indigo-600 border border-slate-200 px-4 py-2.5 rounded-xl transition-all shadow-sm cursor-pointer ml-auto sm:ml-0"
          >
            <.icon name="hero-share" class="size-3.5 text-indigo-500" />
            {I18n.t(@locale, "common.share")}
          </button>
          <button
            type="button"
            onclick="window.print()"
            class="flex items-center gap-2 text-xs font-semibold bg-white text-slate-700 hover:text-indigo-600 border border-slate-200 px-4 py-2.5 rounded-xl transition-all shadow-sm cursor-pointer"
          >
            <.icon name="hero-printer" class="size-3.5" />
            {I18n.t(@locale, "common.print")}
          </button>
          <button
            type="button"
            phx-click="open_calendar"
            class="flex items-center gap-2 text-xs font-semibold bg-white text-slate-700 hover:text-indigo-600 border border-slate-200 px-4 py-2.5 rounded-xl transition-all shadow-sm cursor-pointer"
          >
            <.icon name="hero-calendar" class="size-3.5 text-rose-500" />
            {I18n.t(@locale, "common.calendar")}
          </button>
        </div>
      </div>

      <.hero_section
        locale={@locale}
        destination={@destination}
        duration_days={@duration_days}
        tagline={@plan["tagline"]}
        summary={@plan["summary"]}
      />

      <.map_section
        locale={@locale}
        days={@days}
        map_filter_day={@map_filter_day}
        filtered_points={@filtered_points}
        routes_path={@routes_path}
        selected_point={@selected_point}
      />

      <.budget_section
        locale={@locale}
        budget={@budget}
        budget_estimate={@budget_estimate}
        travelers_count={@travelers_count}
        duration_days={@duration_days}
      />

      <.climate_section
        locale={@locale}
        climate={@climate}
        climate_month={@climate_month}
        climate_month_index={@climate_month_index}
        weather_expected={@plan["weather_expected"]}
      />

      <.transit_section
        locale={@locale}
        destination={@destination}
        transit_loading={@transit_loading}
        transit_error={@transit_error}
        transit_sections={@transit_sections}
        active_transit_section={@active_transit_section}
        transit_tab_index={@transit_tab_index}
        transit_data={@transit_data}
      />

      <.itinerary_section
        locale={@locale}
        days={@days}
        active_day={@active_day}
        active_day_plan={@active_day_plan}
      />

      <.packing_section
        locale={@locale}
        packing_items={@packing_items}
        checked_packing={@checked_packing}
      />

      <.tips_section locale={@locale} tips={@tips} />

      <.share_modal
        :if={@share_open}
        locale={@locale}
        share_url={@share_url}
        destination={@destination}
        duration_days={@duration_days}
        share_copied={@share_copied}
      />

      <.calendar_modal
        :if={@calendar_open}
        locale={@locale}
        start_date={@start_date}
        days={@days}
        destination={@destination}
      />
    </div>
    """
  end

  defp hero_section(assigns) do
    ~H"""
    <div class="relative overflow-hidden rounded-3xl bg-gradient-to-r from-slate-900 via-indigo-950 to-slate-900 border border-indigo-900/30 text-white p-8 md:p-12 shadow-2xl">
      <div class="absolute -top-12 -right-12 w-64 h-64 bg-indigo-500/10 rounded-full blur-3xl" />
      <div class="space-y-4 max-w-3xl relative z-10">
        <span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-indigo-500/25 border border-indigo-400/20 text-indigo-200">
          <.icon name="hero-sparkles" class="size-3.5" />
          {I18n.t(@locale, "trip.itineraryBadge", %{days: @duration_days})}
        </span>
        <h1 class="text-3xl md:text-5xl font-black tracking-tight leading-none">
          <span class="bg-gradient-to-r from-amber-200 via-rose-300 to-indigo-200 bg-clip-text text-transparent">
            {@destination}
          </span>
        </h1>
        <p
          :if={@tagline}
          class="text-lg md:text-xl font-bold tracking-tight text-indigo-200 italic max-w-2xl"
        >
          "{@tagline}"
        </p>
        <p :if={@summary} class="text-sm md:text-base text-slate-300 leading-relaxed">{@summary}</p>
      </div>
    </div>
    """
  end

  defp map_section(assigns) do
    ~H"""
    <div
      class="bg-slate-900 border border-slate-800 rounded-3xl overflow-hidden shadow-2xl text-white"
      id="trip-map-block"
    >
      <div class="p-4 bg-slate-950/60 border-b border-slate-800/80 flex flex-col sm:flex-row justify-between items-start sm:items-center gap-3">
        <div>
          <h3 class="font-extrabold text-sm text-slate-100 flex items-center gap-2">
            {I18n.t(@locale, "trip.mapTitle")}
            <span class="text-[10px] bg-slate-800 text-slate-300 py-0.5 px-2 rounded-full font-mono">
              {I18n.t(@locale, "trip.mapSimulation")}
            </span>
          </h3>
          <p class="text-[10px] text-slate-400">{I18n.t(@locale, "trip.mapSubtitle")}</p>
        </div>
        <div class="flex items-center gap-1.5 bg-slate-900 border border-slate-800/80 p-1 rounded-xl flex-wrap">
          <button
            type="button"
            phx-click="set_map_filter"
            phx-value-day="all"
            class={[
              "px-3 py-1.5 rounded-lg text-xs font-bold transition-all cursor-pointer",
              @map_filter_day == "all" && "bg-indigo-600 text-white",
              @map_filter_day != "all" && "text-slate-400 hover:text-slate-200"
            ]}
          >
            {I18n.t(@locale, "trip.viewAll")}
          </button>
          <%= for day <- @days do %>
            <button
              type="button"
              phx-click="set_map_filter"
              phx-value-day={day["day_number"]}
              class={[
                "px-2.5 py-1.5 rounded-lg text-xs font-bold transition-all cursor-pointer",
                @map_filter_day == day["day_number"] && "bg-indigo-600 text-white",
                @map_filter_day != day["day_number"] && "text-slate-400 hover:text-slate-200"
              ]}
            >
              D{day["day_number"]}
            </button>
          <% end %>
        </div>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-4 min-h-[450px]">
        <div class="lg:col-span-3 h-[450px] relative bg-slate-950 overflow-hidden">
          <svg class="w-full h-full absolute inset-0 pointer-events-none" viewBox="0 0 700 450">
            <defs>
              <linearGradient id="route-gradient" x1="0%" y1="0%" x2="100%" y2="100%">
                <stop offset="0%" stop-color="#4f46e5" stop-opacity="0.8" />
                <stop offset="50%" stop-color="#06b6d4" stop-opacity="0.8" />
                <stop offset="100%" stop-color="#10b981" stop-opacity="0.8" />
              </linearGradient>
            </defs>
            <path
              :if={@routes_path != ""}
              d={@routes_path}
              fill="none"
              stroke="url(#route-gradient)"
              stroke-width="2.5"
              stroke-dasharray="6,5"
            />
          </svg>

          <%= for point <- @filtered_points do %>
            <button
              type="button"
              phx-click="select_map_point"
              phx-value-id={point.id}
              style={"left: #{point.x}px; top: #{point.y}px"}
              class={[
                "absolute -translate-x-1/2 -translate-y-1/2 w-6 h-6 rounded-full border-2 flex items-center justify-center transition-all cursor-pointer shadow-lg z-20",
                map_point_color(point.time_slot),
                @selected_point && @selected_point.id == point.id &&
                  "ring-4 ring-amber-500 scale-125 z-30"
              ]}
            >
              <span class="text-[8px] font-bold">{slot_emoji(point.time_slot)}</span>
            </button>
          <% end %>

          <div
            :if={@selected_point}
            class="absolute bottom-4 right-4 left-4 md:left-auto md:w-80 bg-slate-900/95 border border-slate-800 p-4 rounded-2xl shadow-2xl z-30 backdrop-blur"
          >
            <div class="flex justify-between items-start border-b border-slate-800 pb-2 mb-2.5">
              <div>
                <span class="text-[9px] uppercase tracking-wider font-extrabold text-indigo-400">
                  {I18n.t(@locale, "day")} {@selected_point.day_number} • {slot_label(
                    @locale,
                    @selected_point.time_slot
                  )}
                </span>
                <h4 class="font-extrabold text-xs text-slate-100 mt-1">{@selected_point.title}</h4>
              </div>
              <button
                type="button"
                phx-click="clear_map_point"
                class="text-slate-400 hover:text-slate-100"
              >
                <.icon name="hero-x-mark" class="size-3" />
              </button>
            </div>
            <p class="text-[11px] text-slate-300 leading-relaxed line-clamp-3">
              {@selected_point.description}
            </p>
            <div class="mt-3 pt-2.5 border-t border-slate-800 text-[10px] text-slate-400 flex justify-between font-mono">
              <span>{I18n.t(@locale, "trip.costs")}: {@selected_point.cost}</span>
              <span>{@selected_point.duration}</span>
            </div>
          </div>
        </div>

        <div class="lg:col-span-1 bg-slate-950/80 border-t lg:border-t-0 lg:border-l border-slate-800 flex flex-col max-h-[450px]">
          <div class="p-4 border-b border-slate-800 flex justify-between items-center">
            <span class="text-xs font-black uppercase text-slate-400 tracking-wider">
              {I18n.t(@locale, "trip.stopsDirectory")}
            </span>
            <span class="text-[9px] bg-indigo-500/15 py-0.5 px-2 rounded-full font-bold text-indigo-400">
              {I18n.t(@locale, "trip.stopsCount", %{count: length(@filtered_points)})}
            </span>
          </div>
          <div class="overflow-y-auto p-3 space-y-2 flex-grow">
            <%= for point <- @filtered_points do %>
              <button
                type="button"
                phx-click="select_map_point"
                phx-value-id={point.id}
                class={[
                  "w-full text-left p-2.5 rounded-xl border text-xs flex flex-col gap-1 transition-all cursor-pointer",
                  @selected_point && @selected_point.id == point.id &&
                    "bg-indigo-600/40 border-indigo-600 text-indigo-200",
                  (!@selected_point || @selected_point.id != point.id) &&
                    "bg-slate-900/40 border-slate-800 hover:bg-slate-900 text-slate-300"
                ]}
              >
                <div class="flex justify-between items-center">
                  <span class="font-mono text-[9px] text-slate-500">
                    {I18n.t(@locale, "day")} {point.day_number}
                  </span>
                  <span class="text-[8px] font-bold uppercase">
                    {slot_label(@locale, point.time_slot)}
                  </span>
                </div>
                <h5 class="font-bold text-slate-100 truncate">{point.title}</h5>
              </button>
            <% end %>
          </div>
          <div class="p-3 border-t border-slate-800 text-[10px] text-slate-500 flex items-center gap-1.5">
            <.icon name="hero-information-circle" class="size-3.5 text-indigo-400 shrink-0" />
            <span>{I18n.t(@locale, "trip.coordsDisclaimer")}</span>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp budget_section(assigns) do
    ~H"""
    <div class="bg-white rounded-3xl border border-slate-100 shadow-sm p-6 md:p-8 space-y-6">
      <h2 class="text-xl font-bold text-slate-800 flex items-center gap-2">
        <.icon name="hero-banknotes" class="size-5 text-emerald-600" />
        {I18n.t(@locale, "trip.financialSimulator")}
      </h2>
      <p class="text-xs text-slate-500">
        {I18n.t(@locale, "trip.travelersAdjust", %{days: @duration_days})}
      </p>

      <div class="flex items-center gap-4">
        <span class="text-sm font-medium text-slate-700">
          {I18n.t(@locale, "trip.travelersCount")}
        </span>
        <input
          type="range"
          min="1"
          max="8"
          value={@travelers_count}
          phx-change="set_travelers"
          name="count"
          class="w-full max-w-xs accent-indigo-600"
        />
        <span class="text-sm font-bold text-indigo-700 bg-indigo-50 px-3 py-1 rounded-lg">
          {@travelers_count}
        </span>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <div class="p-4 rounded-2xl bg-slate-50 border border-slate-100">
          <p class="text-[10px] uppercase font-bold text-slate-400">
            {I18n.t(@locale, "trip.hotelLine", %{rooms: @budget.double_rooms})}
          </p>
          <p class="text-lg font-black text-slate-800">R$ {format_money(@budget.hotel_group)}</p>
        </div>
        <div class="p-4 rounded-2xl bg-slate-50 border border-slate-100">
          <p class="text-[10px] uppercase font-bold text-slate-400">
            {I18n.t(@locale, "trip.foodLine", %{count: @travelers_count})}
          </p>
          <p class="text-lg font-black text-slate-800">R$ {format_money(@budget.food_group)}</p>
        </div>
        <div class="p-4 rounded-2xl bg-slate-50 border border-slate-100">
          <p class="text-[10px] uppercase font-bold text-slate-400">
            {I18n.t(@locale, "trip.transportLine", %{count: @travelers_count})}
          </p>
          <p class="text-lg font-black text-slate-800">R$ {format_money(@budget.transport_group)}</p>
        </div>
        <div class="p-4 rounded-2xl bg-indigo-600 text-white">
          <p class="text-[10px] uppercase font-bold text-indigo-200">
            {I18n.t(@locale, "trip.totalReference")}
          </p>
          <p class="text-2xl font-black">R$ {format_money(@budget.total)}</p>
        </div>
      </div>
    </div>
    """
  end

  defp climate_section(assigns) do
    ~H"""
    <div class="bg-white rounded-3xl border border-slate-100 shadow-sm p-6 md:p-8 space-y-6">
      <div>
        <h2 class="text-xl font-bold text-slate-800 flex items-center gap-2">
          <.icon name="hero-sun" class="size-5 text-amber-500" />
          {I18n.t(@locale, "trip.climateTitle")}
        </h2>
        <p class="text-xs text-slate-500 mt-1">{I18n.t(@locale, "trip.climateSubtitle")}</p>
      </div>

      <div class="p-4 rounded-2xl bg-sky-50 border border-sky-100">
        <p class="font-bold text-sky-900">{@climate.climate_type}</p>
        <p class="text-xs text-sky-800/80 mt-1 leading-relaxed">{@climate.description}</p>
        <p class="text-xs font-semibold text-sky-700 mt-2">
          {I18n.t(@locale, "trip.bestSeason", %{months: @climate.best_months})}
        </p>
      </div>

      <div class="flex flex-wrap gap-2">
        <%= for {month, index} <- Enum.with_index(@climate.months) do %>
          <button
            type="button"
            phx-click="set_climate_month"
            phx-value-index={index}
            class={[
              "px-3 py-1.5 rounded-lg text-xs font-bold border cursor-pointer transition-all",
              @climate_month_index == index && "bg-indigo-600 text-white border-indigo-600",
              @climate_month_index != index &&
                "bg-white text-slate-600 border-slate-200 hover:border-indigo-300"
            ]}
          >
            {month_label(@locale, month.month)}
          </button>
        <% end %>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div class="p-4 rounded-2xl bg-slate-50 border border-slate-100">
          <p class="text-[10px] uppercase font-bold text-slate-400">
            {I18n.t(@locale, "trip.tempGoals")}
          </p>
          <p class="text-lg font-black text-slate-800">
            {@climate_month.temp_max}° / {@climate_month.temp_min}°
          </p>
        </div>
        <div class="p-4 rounded-2xl bg-slate-50 border border-slate-100">
          <p class="text-[10px] uppercase font-bold text-slate-400">
            {I18n.t(@locale, "trip.rainChance")}
          </p>
          <p class="text-lg font-black text-slate-800">{@climate_month.precip}%</p>
        </div>
        <div class="p-4 rounded-2xl bg-slate-50 border border-slate-100">
          <p class="text-[10px] uppercase font-bold text-slate-400">
            {I18n.t(@locale, "trip.sunHours")}
          </p>
          <p class="text-lg font-black text-slate-800">
            {@climate_month.sun_hours} {I18n.t(@locale, "trip.sunHoursUnit")}
          </p>
        </div>
      </div>

      <div class="p-4 rounded-2xl bg-amber-50 border border-amber-100">
        <p class="text-[10px] uppercase font-bold text-amber-700 mb-1">
          {I18n.t(@locale, "trip.packingGuide")}
        </p>
        <p class="text-sm text-amber-900 leading-relaxed">{@climate_month.recommendation}</p>
      </div>

      <p :if={@weather_expected} class="text-xs text-slate-500 italic">
        {I18n.t(@locale, "trip.climateSummary")}: {@weather_expected}
      </p>
    </div>
    """
  end

  defp transit_section(assigns) do
    ~H"""
    <div class="bg-white rounded-3xl border border-slate-100 shadow-sm p-6 md:p-8 space-y-6">
      <div class="flex items-center justify-between gap-4">
        <div>
          <h2 class="text-xl font-bold text-slate-800 flex items-center gap-2">
            <.icon name="hero-truck" class="size-5 text-indigo-600" />
            {I18n.t(@locale, "trip.transitTitle")}
            <span class="text-[10px] font-black tracking-widest text-indigo-600 bg-indigo-50 px-2 py-0.5 rounded uppercase border border-indigo-100">
              {I18n.t(@locale, "trip.liveSearch")}
            </span>
          </h2>
          <p class="text-xs text-slate-500 mt-1">{I18n.t(@locale, "trip.transitSubtitle")}</p>
        </div>
      </div>

      <%= if @transit_data == nil && !@transit_loading do %>
        <div class="p-6 rounded-2xl bg-slate-50 border border-dashed border-slate-200 text-center space-y-3">
          <h4 class="font-bold text-sm text-slate-800">
            {I18n.t(@locale, "trip.transitCtaTitle", %{destination: @destination})}
          </h4>
          <p class="text-xs text-slate-500 max-w-lg mx-auto">
            {I18n.t(@locale, "trip.transitCtaDesc")}
          </p>
          <button
            type="button"
            phx-click="search_transit"
            class="inline-flex items-center gap-2 px-5 py-2.5 bg-indigo-600 hover:bg-indigo-700 text-white rounded-xl text-sm font-bold cursor-pointer"
          >
            <.icon name="hero-magnifying-glass" class="size-4" />
            {I18n.t(@locale, "trip.transitSearch")}
          </button>
        </div>
      <% end %>

      <div :if={@transit_loading} class="py-8 text-center space-y-2">
        <div class="w-10 h-10 mx-auto rounded-full border-4 border-indigo-100 border-t-indigo-600 animate-spin" />
        <p class="text-xs font-bold text-slate-700">{I18n.t(@locale, "trip.transitLoading")}</p>
        <p class="text-[11px] text-slate-500 max-w-sm mx-auto">
          {I18n.t(@locale, "trip.transitLoadingDesc")}
        </p>
      </div>

      <p
        :if={@transit_error}
        class="text-xs text-rose-600 bg-rose-50 border border-rose-100 rounded-xl p-3"
      >
        {@transit_error}
      </p>

      <%= if @transit_sections != [] do %>
        <div class="flex flex-wrap gap-2">
          <%= for {section, index} <- Enum.with_index(@transit_sections) do %>
            <button
              type="button"
              phx-click="set_transit_tab"
              phx-value-index={index}
              class={[
                "px-3 py-1.5 rounded-lg text-xs font-bold border cursor-pointer",
                @transit_tab_index == index && "bg-indigo-600 text-white border-indigo-600",
                @transit_tab_index != index && "bg-white text-slate-600 border-slate-200"
              ]}
            >
              {transit_section_label(@locale, section)}
            </button>
          <% end %>
        </div>

        <div :if={@active_transit_section} class="p-4 rounded-2xl bg-slate-50 border border-slate-100">
          <h4 class="font-bold text-slate-800 text-sm mb-2">{@active_transit_section.title}</h4>
          <div class="space-y-2">
            <%= for segments <- TripPlannerIa.TransitParse.content_lines(@active_transit_section.content) do %>
              <div class="flex items-start gap-2">
                <span class="text-[10px] text-indigo-500 mt-1">✦</span>
                <p class="text-xs text-slate-600 leading-relaxed">
                  <%= for segment <- segments do %>
                    <%= if segment.type == :bold do %>
                      <strong class="font-semibold text-slate-800">{segment.text}</strong>
                    <% else %>
                      {segment.text}
                    <% end %>
                  <% end %>
                </p>
              </div>
            <% end %>
          </div>
        </div>

        <div :if={@transit_data && @transit_data[:sources] != []} class="space-y-2">
          <p class="text-xs font-bold text-slate-700">{I18n.t(@locale, "trip.sourcesTitle")}</p>
          <%= for source <- @transit_data[:sources] do %>
            <a
              href={source.url}
              target="_blank"
              rel="noopener"
              class="text-xs text-indigo-600 hover:underline block"
            >
              {source.title}
            </a>
          <% end %>
        </div>

        <button
          type="button"
          phx-click="search_transit"
          class="text-xs font-semibold text-indigo-600 hover:text-indigo-800 cursor-pointer"
        >
          {I18n.t(@locale, "trip.reloadSearch")}
        </button>
      <% end %>
    </div>
    """
  end

  defp itinerary_section(assigns) do
    ~H"""
    <div class="space-y-4">
      <h2 class="text-xl font-bold text-slate-800 flex items-center gap-2">
        <.icon name="hero-calendar-days" class="size-5 text-indigo-600" />
        {I18n.t(@locale, "trip.scheduleTitle")}
      </h2>

      <div class="flex flex-wrap gap-2">
        <%= for day <- @days do %>
          <button
            type="button"
            phx-click="set_active_day"
            phx-value-day={day["day_number"]}
            class={[
              "px-4 py-2 rounded-xl text-sm font-bold border cursor-pointer transition-all",
              @active_day == day["day_number"] && "bg-indigo-600 text-white border-indigo-600",
              @active_day != day["day_number"] &&
                "bg-white text-slate-600 border-slate-200 hover:border-indigo-300"
            ]}
          >
            {I18n.t(@locale, "day")} {day["day_number"]}
          </button>
        <% end %>
      </div>

      <div
        :if={@active_day_plan}
        class="bg-white rounded-2xl border border-slate-100 shadow-sm p-6 space-y-4"
      >
        <div>
          <h3 class="font-bold text-slate-800 text-lg">
            {I18n.t(@locale, "trip.dayFocus")}: {@active_day_plan["theme"]}
          </h3>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
          <%= for {slot, label_key} <- [{"morning", "trip.morning"}, {"afternoon", "trip.afternoon"}, {"evening", "trip.evening"}] do %>
            <% activity = @active_day_plan[slot] %>
            <div :if={activity} class="bg-slate-50 rounded-xl p-4 space-y-1">
              <span class="text-[10px] uppercase font-bold text-indigo-600 tracking-wider">
                {I18n.t(@locale, label_key)}
              </span>
              <h4 class="font-semibold text-slate-800 text-sm">{activity["title"]}</h4>
              <p class="text-xs text-slate-500 leading-relaxed">{activity["description"]}</p>
              <div class="flex gap-3 text-[10px] text-slate-400 pt-1">
                <span :if={activity["duration"]}>{activity["duration"]}</span>
                <span :if={activity["cost"]}>{activity["cost"]}</span>
              </div>
            </div>
          <% end %>
        </div>

        <% dining = @active_day_plan["dining_spot"] %>
        <div :if={dining} class="p-4 rounded-xl bg-amber-50 border border-amber-100">
          <p class="text-[10px] uppercase font-bold text-amber-700">
            {I18n.t(@locale, "trip.diningTitle")}
          </p>
          <h4 class="font-bold text-slate-800">{dining["name"]}</h4>
          <p class="text-xs text-slate-600">{dining["type"]} • {dining["price_level"]}</p>
          <p class="text-xs text-slate-500 mt-1">{dining["description"]}</p>
        </div>
      </div>
    </div>
    """
  end

  defp packing_section(assigns) do
    checked_count =
      Enum.count(assigns.packing_items, &Map.get(assigns.checked_packing, &1, false))

    assigns = assign(assigns, :checked_count, checked_count)

    ~H"""
    <div class="bg-white rounded-3xl border border-slate-100 shadow-sm p-6 space-y-4">
      <h2 class="text-lg font-bold text-slate-800 flex items-center gap-2">
        <.icon name="hero-briefcase" class="size-5 text-indigo-600" />
        {I18n.t(@locale, "trip.packingTitle")}
      </h2>
      <p class="text-xs text-slate-500">{I18n.t(@locale, "trip.packingDesc")}</p>
      <p class="text-[10px] font-bold text-indigo-600">
        {I18n.t(@locale, "trip.packingProgress")} {I18n.t(@locale, "trip.packingCount", %{
          checked: @checked_count,
          total: length(@packing_items)
        })}
      </p>
      <div class="grid grid-cols-1 sm:grid-cols-2 gap-2">
        <%= for item <- @packing_items do %>
          <label class="flex items-center gap-2 p-3 rounded-xl border border-slate-100 bg-slate-50/50 cursor-pointer">
            <input
              type="checkbox"
              phx-click="toggle_packing"
              phx-value-item={item}
              checked={Map.get(@checked_packing, item, false)}
              class="accent-indigo-600"
            />
            <span class={[
              "text-sm",
              Map.get(@checked_packing, item, false) && "line-through text-slate-400",
              !Map.get(@checked_packing, item, false) && "text-slate-700"
            ]}>
              {item}
            </span>
          </label>
        <% end %>
      </div>
    </div>
    """
  end

  defp tips_section(assigns) do
    ~H"""
    <div
      :if={@tips != []}
      class="bg-white rounded-3xl border border-slate-100 shadow-sm p-6 space-y-4"
    >
      <h2 class="text-lg font-bold text-slate-800 flex items-center gap-2">
        <.icon name="hero-light-bulb" class="size-5 text-amber-500" />
        {I18n.t(@locale, "trip.tipsTitle")}
      </h2>
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <%= for tip <- @tips do %>
          <div class="p-4 rounded-xl bg-amber-50/50 border border-amber-100">
            <span class="text-[10px] uppercase font-bold text-amber-700">{tip["category"]}</span>
            <p class="text-sm text-slate-700 mt-1 leading-relaxed">{tip["text"]}</p>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp share_modal(assigns) do
    ~H"""
    <div class="fixed inset-0 z-50 overflow-y-auto">
      <div class="fixed inset-0 bg-slate-950/40 backdrop-blur-sm" phx-click="close_share" />
      <div class="flex min-h-screen items-center justify-center p-4">
        <div class="relative w-full max-w-lg bg-white rounded-3xl border border-slate-100 shadow-2xl p-6 z-10">
          <h2 class="text-lg font-bold text-slate-900">{I18n.t(@locale, "trip.shareModalTitle")}</h2>
          <p class="text-xs text-slate-500 mt-1">{I18n.t(@locale, "trip.shareModalDesc")}</p>
          <div class="mt-4 space-y-3">
            <input
              type="text"
              readonly
              value={@share_url}
              class="w-full text-xs p-3 rounded-xl border border-slate-200 bg-slate-50 font-mono"
            />
            <button
              type="button"
              phx-click="copy_share_link"
              class="w-full py-2.5 bg-indigo-600 text-white rounded-xl text-sm font-bold cursor-pointer"
            >
              {if @share_copied,
                do: I18n.t(@locale, "common.copied"),
                else: I18n.t(@locale, "common.copy")}
            </button>
          </div>
          <button
            type="button"
            phx-click="close_share"
            class="mt-4 text-xs text-slate-500 hover:text-slate-700 cursor-pointer"
          >
            {I18n.t(@locale, "common.cancel")}
          </button>
        </div>
      </div>
    </div>
    """
  end

  defp calendar_modal(assigns) do
    ~H"""
    <div class="fixed inset-0 z-50 overflow-y-auto">
      <div class="fixed inset-0 bg-slate-950/40 backdrop-blur-sm" phx-click="close_calendar" />
      <div class="flex min-h-screen items-center justify-center p-4">
        <div class="relative w-full max-w-md bg-white rounded-3xl border border-slate-100 shadow-2xl p-6 z-10">
          <h2 class="text-lg font-bold text-slate-900">
            {I18n.t(@locale, "trip.calendarModalTitle")}
          </h2>
          <p class="text-xs text-slate-500 mt-1">{I18n.t(@locale, "trip.calendarModalDesc")}</p>
          <label class="block mt-4 text-sm font-medium text-slate-700">
            {I18n.t(@locale, "trip.startDate")}
          </label>
          <input
            type="date"
            name="start_date"
            value={@start_date}
            phx-change="set_start_date"
            class="w-full mt-1 px-3 py-2 rounded-xl border border-slate-200"
          />
          <button
            type="button"
            phx-click="download_calendar"
            class="mt-4 w-full py-2.5 bg-rose-600 text-white rounded-xl text-sm font-bold cursor-pointer"
          >
            {I18n.t(@locale, "trip.downloadIcs")}
          </button>
          <button
            type="button"
            phx-click="close_calendar"
            class="mt-3 text-xs text-slate-500 cursor-pointer"
          >
            {I18n.t(@locale, "common.cancel")}
          </button>
        </div>
      </div>
    </div>
    """
  end

  defp origin_from_uri(uri) do
    uri
    |> URI.parse()
    |> then(fn %URI{scheme: scheme, host: host, port: port} ->
      port_part = if port in [nil, 80, 443], do: "", else: ":#{port}"
      "#{scheme}://#{host}#{port_part}"
    end)
  rescue
    _ -> "http://localhost:4000"
  end

  defp format_money(value) when is_integer(value) do
    value
    |> Integer.to_string()
    |> String.graphemes()
    |> Enum.reverse()
    |> Enum.chunk_every(3)
    |> Enum.join(".")
    |> String.reverse()
  end

  defp map_point_color("Manhã"), do: "bg-indigo-600 border-indigo-400 text-indigo-100"
  defp map_point_color("Tarde"), do: "bg-sky-500 border-sky-300 text-sky-100"
  defp map_point_color("Noite"), do: "bg-slate-700 border-slate-500 text-slate-100"
  defp map_point_color("Gastronomia"), do: "bg-orange-600 border-orange-400 text-orange-100"
  defp map_point_color(_), do: "bg-indigo-600 border-indigo-400"

  defp slot_emoji("Manhã"), do: "☀"
  defp slot_emoji("Tarde"), do: "⛅"
  defp slot_emoji("Noite"), do: "🌙"
  defp slot_emoji("Gastronomia"), do: "🍽"
  defp slot_emoji(_), do: "•"

  defp slot_label(locale, "Manhã"), do: I18n.t(locale, "trip.morning")
  defp slot_label(locale, "Tarde"), do: I18n.t(locale, "trip.afternoon")
  defp slot_label(locale, "Noite"), do: I18n.t(locale, "trip.evening")
  defp slot_label(locale, "Gastronomia"), do: I18n.t(locale, "trip.gastronomy")
  defp slot_label(_locale, slot), do: slot

  defp month_label(locale, month) do
    I18n.t(locale, "months.#{month}", %{})
    |> then(fn
      "months." <> _ -> month
      label -> label
    end)
  end

  defp transit_section_label(_locale, %{key: :other, title: title}), do: title

  defp transit_section_label(locale, %{key: key}) do
    I18n.t(locale, "trip.transitSections.#{key}", %{})
    |> then(fn
      "trip.transitSections." <> _ -> Atom.to_string(key)
      label -> label
    end)
  end
end
