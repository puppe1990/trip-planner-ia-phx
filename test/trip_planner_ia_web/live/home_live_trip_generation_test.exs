defmodule TripPlannerIaWeb.HomeLiveTripGenerationTest do
  use TripPlannerIaWeb.ConnCase

  import Phoenix.LiveViewTest

  setup :register_and_log_in_user

  setup do
    on_exit(fn ->
      System.delete_env("TRIP_PLANNER_MULTI_STEP")
      System.delete_env("GEMINI_API_KEY")
      System.delete_env("NVIDIA_API_KEY")
    end)

    System.put_env("TRIP_PLANNER_MULTI_STEP", "false")
    System.delete_env("GEMINI_API_KEY")
    System.delete_env("NVIDIA_API_KEY")

    :ok
  end

  test "quick destination generation keeps the user authenticated", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    html =
      view
      |> element("button[phx-click=quick_destination][phx-value-key=rio]")
      |> render_click()

    assert html =~ "Gerando Roteiro"
    refute html =~ "Bem-vindo de volta"
    refute html =~ ~p"/users/log-in"

    html = wait_for_generation(view)
    assert html =~ "Rio de Janeiro"
    refute html =~ "Bem-vindo de volta"
    refute html =~ ~p"/users/log-in"
  end

  test "search form generation keeps the user authenticated", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    html =
      view
      |> form("form[phx-submit=submit_search]", %{
        "form" => %{
          "destination" => "Lisboa",
          "duration" => "3"
        }
      })
      |> render_submit()

    assert html =~ "Gerando Roteiro"
    refute html =~ "Bem-vindo de volta"

    html = wait_for_generation(view)
    assert html =~ "Lisboa"
    refute html =~ ~p"/users/log-in"
  end

  test "generation error keeps the user on the home page", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    send(view.pid, {:gen_error, {:error, :test}})

    html = render(view)

    assert html =~ "Não foi possível gerar o roteiro"
    refute html =~ "Bem-vindo de volta"
    refute html =~ ~p"/users/log-in"
  end

  defp wait_for_generation(view, attempts \\ 30) do
    html = render(view)

    if html =~ "Gerando Roteiro" and attempts > 0 do
      Process.sleep(100)
      wait_for_generation(view, attempts - 1)
    else
      html
    end
  end
end
