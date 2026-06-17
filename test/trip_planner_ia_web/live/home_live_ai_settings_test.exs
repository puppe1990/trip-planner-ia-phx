defmodule TripPlannerIaWeb.HomeLiveAiSettingsTest do
  use TripPlannerIaWeb.ConnCase

  import Phoenix.LiveViewTest

  setup :register_and_log_in_user

  setup do
    System.put_env("GEMINI_API_KEY", "test-key")
    System.put_env("NVIDIA_API_KEY", "test-key")

    on_exit(fn ->
      System.delete_env("GEMINI_API_KEY")
      System.delete_env("NVIDIA_API_KEY")
    end)

    :ok
  end

  test "user can change the ai model in settings", %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/")

    refute html =~ "Gemini 2.5 Flash"

    view |> element("button[phx-click=\"open_ai_settings\"]") |> render_click()
    view |> element("#ai-model") |> render_click()

    html =
      view
      |> element("button[phx-click=\"select_ai_model\"][phx-value-model=\"gemini-2.5-flash\"]")
      |> render_click()

    assert html =~ "Gemini 2.5 Flash"
    refute html =~ "indisponível"
  end

  test "lists configured providers without unavailable suffix", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    view |> element("button[phx-click=\"open_ai_settings\"]") |> render_click()
    view |> element("#ai-provider") |> render_click()
    html = render(view)

    assert html =~ "Google Gemini"
    refute html =~ "Google Gemini (indisponível)"
  end
end
