defmodule TripPlannerIaWeb.LocaleControllerTest do
  use TripPlannerIaWeb.ConnCase

  import Phoenix.LiveViewTest
  import TripPlannerIa.AccountsFixtures

  setup :register_and_log_in_user

  test "switching locale keeps the user session", %{conn: conn} do
    conn = get(conn, ~p"/locale/en?return_to=/")
    assert redirected_to(conn) == ~p"/"
    assert get_session(conn, :user_token)

    conn =
      conn
      |> recycle()
      |> get(~p"/")

    assert html_response(conn, 200) =~ "TripPlanner"
    assert conn.status == 200
  end

  test "switching locale keeps live session", %{conn: conn} do
    conn = get(conn, ~p"/locale/en?return_to=/")

    assert {:ok, _view, html} =
             live(conn, ~p"/")

    assert html =~ "TripPlanner"
  end

  test "sets locale cookie", %{conn: conn} do
    conn = get(conn, ~p"/locale/en?return_to=/")
    assert conn.resp_cookies["locale"].value == "en"
  end

  test "switching locale after real login keeps session cookie chain", %{conn: conn, user: user} do
    conn =
      post(conn, ~p"/users/log-in", %{
        "user" => %{"email" => user.email, "password" => valid_user_password()}
      })

    conn = get(conn, ~p"/locale/en?return_to=/")
    assert redirected_to(conn) == ~p"/"

    assert {:ok, _view, html} = live(conn, ~p"/")
    assert html =~ "TripPlanner"
  end

  test "locale switcher uses live events on the home page", %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/")

    assert html =~ ~s(phx-click="set_locale")
    assert html =~ ~s(phx-value-locale="en")
    refute html =~ ~s(href="/locale/en)

    html =
      view
      |> element("#header-locale-switcher button[phx-value-locale=\"en\"]")
      |> render_click()

    assert html =~ "virtual assistant"
    assert html =~ ~s(phx-value-locale="en")
  end
end
