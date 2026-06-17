defmodule TripPlannerIaWeb.Components.Logo do
  @moduledoc false
  use TripPlannerIaWeb, :html

  attr :size, :atom, default: :sm, values: [:xs, :sm, :md]
  attr :class, :string, default: ""

  def logo(assigns) do
    ~H"""
    <div class={[
      "bg-indigo-600 flex items-center justify-center text-white shadow-md shadow-indigo-600/20",
      @size == :xs && "w-9 h-9 rounded-xl",
      @size == :sm && "w-10 h-10 rounded-2xl",
      @size == :md && "w-16 h-16 rounded-2xl",
      @class
    ]}>
      <.icon
        name="hero-map"
        class={[
          @size == :xs && "size-4",
          @size == :sm && "size-5",
          @size == :md && "size-8"
        ]}
      />
    </div>
    """
  end
end
