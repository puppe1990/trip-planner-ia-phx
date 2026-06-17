defmodule TripPlannerIaWeb.UserRegistrationController do
  use TripPlannerIaWeb, :controller

  alias TripPlannerIa.Accounts
  alias TripPlannerIa.Accounts.User
  alias TripPlannerIaWeb.UserAuth

  def new(conn, _params) do
    changeset = Accounts.change_user_registration(%User{})
    render(conn, :new, changeset: changeset, locale: conn.assigns[:locale] || "pt-BR")
  end

  def create(conn, %{"user" => user_params}) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Welcome!")
        |> UserAuth.log_in_user(user, user_params)

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset, locale: conn.assigns[:locale] || "pt-BR")
    end
  end
end
