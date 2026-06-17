defmodule TripPlannerIaWeb.PageControllerTest do
  use TripPlannerIaWeb.ConnCase

  test "GET / redirects unauthenticated users to login", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert redirected_to(conn) == ~p"/users/log-in"
  end

  test "GET / renders home for authenticated users", %{conn: conn} do
    conn =
      conn
      |> log_in_user(TripPlannerIa.AccountsFixtures.user_fixture())
      |> get(~p"/")

    assert html_response(conn, 200) =~ "TripPlanner"
  end
end