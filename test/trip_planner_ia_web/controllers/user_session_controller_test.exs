defmodule TripPlannerIaWeb.UserSessionControllerTest do
  use TripPlannerIaWeb.ConnCase

  import Phoenix.LiveViewTest
  import TripPlannerIa.AccountsFixtures

  setup do
    %{user: user_fixture()}
  end

  describe "GET /users/log-in" do
    test "renders login page", %{conn: conn} do
      conn = get(conn, ~p"/users/log-in")
      response = html_response(conn, 200)
      assert response =~ "Bem-vindo de volta"
      assert response =~ ~p"/users/register"
      refute response =~ "Log in with email"
    end

    test "renders login page with email filled in (sudo mode)", %{conn: conn, user: user} do
      html =
        conn
        |> log_in_user(user)
        |> get(~p"/users/log-in")
        |> html_response(200)

      assert html =~ "Você precisa entrar novamente"
      refute html =~ ~p"/users/register"
      refute html =~ "Log in with email"
      assert html =~ ~s(value="#{user.email}")
    end
  end

  describe "POST /users/log-in" do
    test "logs the user in", %{conn: conn, user: user} do
      conn =
        post(conn, ~p"/users/log-in", %{
          "user" => %{"email" => user.email, "password" => valid_user_password()}
        })

      assert get_session(conn, :user_token)
      assert get_session(conn, :live_socket_id)
      assert conn.resp_cookies["_trip_planner_ia_web_user_remember_me"]
      assert redirected_to(conn) == ~p"/"

      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      assert response =~ "TripPlanner"
      assert response =~ ~p"/users/log-out"
    end

    test "first login works when session cookie is missing but remember-me cookie is set", %{
      conn: conn,
      user: user
    } do
      conn =
        post(conn, ~p"/users/log-in", %{
          "user" => %{"email" => user.email, "password" => valid_user_password()}
        })

      remember_cookie = conn.resp_cookies["_trip_planner_ia_web_user_remember_me"].value

      conn =
        Phoenix.ConnTest.build_conn()
        |> Plug.Conn.put_req_header(
          "cookie",
          "_trip_planner_ia_web_user_remember_me=#{remember_cookie}"
        )

      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      assert response =~ "TripPlanner"
      assert get_session(conn, :user_token)
    end

    test "first login reaches home live view without a second attempt", %{conn: conn, user: user} do
      conn =
        post(conn, ~p"/users/log-in", %{
          "user" => %{"email" => user.email, "password" => valid_user_password()}
        })

      assert {:ok, _view, html} = live(conn, ~p"/")
      assert html =~ "TripPlanner"
    end

    test "live view authenticates with stale session cookie and fresh remember-me cookie", %{
      conn: conn,
      user: user
    } do
      anon_conn = get(conn, ~p"/users/log-in")
      anon_session_cookie = anon_conn.resp_cookies["_trip_planner_ia_key"].value

      login_conn =
        post(anon_conn, ~p"/users/log-in", %{
          "user" => %{"email" => user.email, "password" => valid_user_password()}
        })

      remember_cookie = login_conn.resp_cookies["_trip_planner_ia_web_user_remember_me"].value

      conn =
        Phoenix.ConnTest.build_conn()
        |> Plug.Conn.put_req_header(
          "cookie",
          "_trip_planner_ia_key=#{anon_session_cookie}; _trip_planner_ia_web_user_remember_me=#{remember_cookie}"
        )

      assert {:ok, _view, html} = live(conn, ~p"/")
      assert html =~ "TripPlanner"
      refute html =~ ~p"/users/log-in"
    end

    test "first login live view works with only remember-me cookie after session renew", %{
      conn: conn,
      user: user
    } do
      conn =
        post(conn, ~p"/users/log-in", %{
          "user" => %{"email" => user.email, "password" => valid_user_password()}
        })

      remember_cookie = conn.resp_cookies["_trip_planner_ia_web_user_remember_me"].value

      conn =
        Phoenix.ConnTest.build_conn()
        |> Plug.Conn.put_req_header(
          "cookie",
          "_trip_planner_ia_web_user_remember_me=#{remember_cookie}"
        )

      assert {:ok, _view, html} = live(conn, ~p"/")
      assert html =~ "TripPlanner"
      refute html =~ ~p"/users/log-in"
    end

    test "logs the user in with remember me", %{conn: conn, user: user} do
      conn =
        post(conn, ~p"/users/log-in", %{
          "user" => %{
            "email" => user.email,
            "password" => valid_user_password(),
            "remember_me" => "true"
          }
        })

      assert conn.resp_cookies["_trip_planner_ia_web_user_remember_me"]
      assert redirected_to(conn) == ~p"/"
    end

    test "keeps english locale after logging in from the english login page", %{
      conn: conn,
      user: user
    } do
      conn = get(conn, "/locale/en?" <> URI.encode_query(%{return_to: "/users/log-in"}))
      assert redirected_to(conn) == ~p"/users/log-in"

      conn =
        post(conn, ~p"/users/log-in", %{
          "user" => %{"email" => user.email, "password" => valid_user_password()}
        })

      assert redirected_to(conn) == ~p"/"
      assert get_session(conn, :locale) == "en"

      {:ok, _view, html} = live(conn, ~p"/")
      assert html =~ "Your virtual assistant for smart itineraries"
      refute html =~ "Seu assistente virtual para roteiros inteligentes"
    end

    test "logs the user in with return to", %{conn: conn, user: user} do
      conn =
        conn
        |> init_test_session(user_return_to: "/foo/bar")
        |> post(~p"/users/log-in", %{
          "user" => %{
            "email" => user.email,
            "password" => valid_user_password()
          }
        })

      assert redirected_to(conn) == "/foo/bar"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Welcome back!"
    end

    test "emits error message with invalid credentials", %{conn: conn, user: user} do
      conn =
        post(conn, ~p"/users/log-in", %{
          "user" => %{"email" => user.email, "password" => "invalid_password"}
        })

      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "E-mail ou senha incorretos."
    end
  end

  describe "DELETE /users/log-out" do
    test "logs the user out", %{conn: conn, user: user} do
      conn = conn |> log_in_user(user) |> delete(~p"/users/log-out")
      assert redirected_to(conn) == ~p"/users/log-in"
      refute get_session(conn, :user_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end

    test "succeeds even if the user is not logged in", %{conn: conn} do
      conn = delete(conn, ~p"/users/log-out")
      assert redirected_to(conn) == ~p"/users/log-in"
      refute get_session(conn, :user_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end
  end
end
