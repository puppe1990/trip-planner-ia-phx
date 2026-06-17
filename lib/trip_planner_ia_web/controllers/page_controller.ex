defmodule TripPlannerIaWeb.PageController do
  use TripPlannerIaWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
