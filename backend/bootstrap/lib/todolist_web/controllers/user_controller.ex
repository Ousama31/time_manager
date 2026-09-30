defmodule TodolistWeb.UserController do
  use TodolistWeb, :controller

  alias Todolist.Accounts
  alias Todolist.Accounts.User

  action_fallback TodolistWeb.FallbackController

  def index(conn, _params) do
    users = Accounts.list_users()
    render(conn, :index, users: users)
  end

  # =========================================================================
  # UPDATED: create/2 action
  # EXPLANATION: Uses a `case` match to return:
  # - HTTP 201 Created on successful user creation
  # - HTTP 400 Bad Request on invalid parameters or validation errors
  # =========================================================================
  def create(conn, %{"user" => user_params}) do
    case Accounts.create_user(user_params) do
      {:ok, %User{} = user} ->
        conn
        |> put_status(:created) # HTTP 201
        |> put_resp_header("location", ~p"/api/users/#{user}")
        |> render(:show, user: user)

      {:error, _changeset} ->
        conn
        |> put_status(:bad_request) # HTTP 400
        |> put_view(json: TodolistWeb.ErrorJSON)
        |> render(:"400")
    end
  end

  # =========================================================================
  # UPDATED: show/2 action
  # EXPLANATION: Uses function-level rescue to catch `Ecto.NoResultsError` 
  # when a user ID isn't found and return a 404 response.
  # =========================================================================
  def show(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)
    render(conn, :show, user: user)
  rescue
    Ecto.NoResultsError ->
      conn
      |> put_status(:not_found)
      |> put_view(json: TodolistWeb.ErrorJSON)
      |> render(:"404")
  end

  def update(conn, %{"id" => id, "user" => user_params}) do
    user = Accounts.get_user!(id)

    with {:ok, %User{} = user} <- Accounts.update_user(user, user_params) do
      render(conn, :show, user: user)
    end
  end

  def delete(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)

    with {:ok, %User{}} <- Accounts.delete_user(user) do
      send_resp(conn, :no_content, "")
    end
  end
end