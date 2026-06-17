defmodule TripPlannerIaWeb.UserSessionController do
  use TripPlannerIaWeb, :controller

  alias TripPlannerIa.Accounts
  alias TripPlannerIaWeb.UserAuth

  def new(conn, _params) do
    email = get_in(conn.assigns, [:current_scope, Access.key(:user), Access.key(:email)])
    form = Phoenix.Component.to_form(%{"email" => email}, as: "user")

    render(conn, :new, form: form, locale: conn.assigns[:locale] || "pt-BR")
  end

  def create(conn, %{"user" => %{"email" => email, "password" => password} = user_params})
      when is_binary(password) and password != "" do
    if user = Accounts.get_user_by_email_and_password(email, password) do
      conn
      |> put_flash(:info, "Welcome back!")
      |> UserAuth.log_in_user(user, user_params)
    else
      form = Phoenix.Component.to_form(user_params, as: "user")
      locale = conn.assigns[:locale] || "pt-BR"

      conn
      |> put_flash(:error, TripPlannerIaWeb.I18n.t(locale, "auth.login_error"))
      |> render(:new, form: form, locale: locale)
    end
  end

  def create(conn, %{"user" => user_params}) do
    form = Phoenix.Component.to_form(user_params, as: "user")
    locale = conn.assigns[:locale] || "pt-BR"

    conn
    |> put_flash(:error, TripPlannerIaWeb.I18n.t(locale, "auth.login_error"))
    |> render(:new, form: form, locale: locale)
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UserAuth.log_out_user()
  end
end
