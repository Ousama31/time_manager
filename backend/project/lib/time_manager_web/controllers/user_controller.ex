defmodule TimeManagerWeb.UserController do
  use TimeManagerWeb, :controller

  alias TimeManager.Accounts
  alias TimeManager.Accounts.User

  action_fallback TimeManagerWeb.FallbackController

  # include params in the index function to allow for filtering and pagination
  def index(conn, params) do
    current_user = conn.assigns.current_user

    users =
      case current_user.role do
        :admin -> Accounts.list_users(params)
        :manager -> Accounts.list_team_users(current_user.id)
        _ -> nil
      end

    if users do
      render(conn, :index, users: users)
    else
      conn
      |> put_status(:forbidden)
      |> json(%{error: "Manager or admin access required"})
    end
  end

  def unassigned(conn, _params) do
    if conn.assigns.current_user.role == :manager do
      render(conn, :index, users: Accounts.list_unassigned_users())
    else
      conn
      |> put_status(:forbidden)
      |> json(%{error: "Manager access required"})
    end
  end

  def manager(conn, %{"id" => id}) do
    current_user = conn.assigns.current_user

    if current_user.role == :employee and to_string(current_user.id) == id do
      manager = if current_user.manager_id, do: Accounts.get_user(current_user.manager_id)

      case manager do
        %User{role: :manager} = manager ->
          json(conn, %{
            data: %{id: manager.id, full_name: manager.full_name, email: manager.email}
          })

        _ ->
          conn |> put_status(:not_found) |> json(%{error: "No assigned manager found"})
      end
    else
      conn |> put_status(:forbidden) |> json(%{error: "You can only view your assigned manager"})
    end
  end

  def sign_up(conn, params) do
    user_params = Map.get(params, "user", params)

    case Accounts.create_user(user_params) do
      {:ok, user} ->
        conn
        |> put_status(:created)
        |> json(%{
          message: "User registered successfully",
          data: %{
            id: user.id,
            username: user.username,
            email: user.email
          }
        })

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: translate_errors(changeset)})
    end
  end

  # helper function to translate changeset errors into a more readable format
  defp translate_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end

  # def create(conn, %{"user" => user_params}) do
  #   with {:ok, %User{} = user} <- Accounts.create_user(user_params) do
  #     conn
  #     |> put_status(:created)
  #     |> put_resp_header("location", ~p"/api/users/#{user}")
  #     |> render(:show, user: user)
  #   end
  # end

  def show(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)
    render(conn, :show, user: user)
  end

  def update(conn, %{"id" => id, "user" => user_params}) do
    current_user = conn.assigns.current_user
    is_self = to_string(current_user.id) == to_string(id)

    cond do
      current_user.role == :admin ->
        user = Accounts.get_user!(id)

        if is_self and user_params["status"] == "inactive" do
          conn
          |> put_status(:unprocessable_entity)
          |> json(%{error: "You cannot suspend your own administrator account"})
        else
          with {:ok, %User{} = user} <- Accounts.update_user_role(user, user_params) do
            render(conn, :show, user: user)
          end
        end

      current_user.role == :manager and not is_self ->
        user = Accounts.get_user!(id)
        manager_id = Map.get(user_params, "manager_id", :missing)

        allowed_change =
          (manager_id in [current_user.id, Integer.to_string(current_user.id)] and
             is_nil(user.manager_id)) or
            (is_nil(manager_id) and user.manager_id == current_user.id)

        if user_params |> Map.keys() |> Enum.all?(&(&1 == "manager_id")) and allowed_change do
          case Accounts.update_user_manager(user, manager_id) do
            {:ok, %User{} = user} ->
              render(conn, :show, user: user)

            {:error, _reason} ->
              conn
              |> put_status(:unprocessable_entity)
              |> json(%{error: "Invalid team assignment"})
          end
        else
          conn
          |> put_status(:forbidden)
          |> json(%{
            error: "You can only add unassigned employees or remove your own team members"
          })
        end

      is_self ->
        user = Accounts.get_user!(id)
        safe_params = Map.drop(user_params, ["role", "status", "manager_id"])

        with {:ok, %User{} = user} <- Accounts.update_user(user, safe_params) do
          render(conn, :show, user: user)
        end

      true ->
        conn
        |> put_status(:forbidden)
        |> json(%{error: "Unauthorized to update this user"})
    end
  end

  def delete(conn, %{"id" => id}) do
    if conn.assigns.current_user.role == :admin do
      user = Accounts.get_user!(id)

      if user.id == conn.assigns.current_user.id do
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "You cannot delete your own administrator account"})
      else
        with {:ok, %User{}} <- Accounts.delete_user(user) do
          send_resp(conn, :no_content, "")
        end
      end
    else
      conn
      |> put_status(:forbidden)
      |> json(%{error: "Admin access required"})
    end
  end
end
