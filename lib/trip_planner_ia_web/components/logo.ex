defmodule TripPlannerIaWeb.Components.Logo do
  @moduledoc false
  use TripPlannerIaWeb, :html

  attr :size, :atom, default: :sm, values: [:sm, :md]
  attr :class, :string, default: ""

  def logo(assigns) do
    ~H"""
    <div class={[
      "rounded-2xl bg-indigo-600 flex items-center justify-center text-white shadow-md shadow-indigo-600/20",
      @size == :sm && "w-10 h-10",
      @size == :md && "w-16 h-16",
      @class
    ]}>
      <.icon
        name="hero-map"
        class={[
          @size == :sm && "size-5",
          @size == :md && "size-8"
        ]}
      />
    </div>
    """
  end
end
