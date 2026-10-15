defmodule TimeManagerWeb.WorkingtimeController do
  use TimeManagerWeb, :controller

  alias TimeManager.Workingtimes
  alias TimeManager.Workingtimes.Workingtime

  action_fallback TimeManagerWeb.FallbackController

  def index(conn, %{"userID" => user_id} = params) do
    if TimeManager.Accounts.can_access_user_data?(conn.assigns.current_user, user_id) do
      workingtime = Workingtimes.list_workingtime(user_id, params)
      render(conn, :index, workingtime: workingtime)
    else
      conn
      |> put_status(:forbidden)
      |> json(%{error: "You cannot view this user's working times"})
    end
  end

  def create(conn, %{"userID" => user_id, "workingtime" => workingtime_params}) do
    if TimeManager.Accounts.can_access_user_data?(conn.assigns.current_user, user_id) do
      # Accept IDs from URL parameters or direct calls.
      parsed_user_id = if is_binary(user_id), do: String.to_integer(user_id), else: user_id
      workingtime_params = Map.put(workingtime_params, "user_id", parsed_user_id)

      with {:ok, %Workingtime{} = workingtime} <-
             Workingtimes.create_workingtime(workingtime_params) do
        conn
        |> put_status(:created)
        |> render(:show, workingtime: workingtime)
      end
    else
      conn
      |> put_status(:forbidden)
      |> json(%{error: "You cannot create working time for this user"})
    end
  end

  def show(conn, %{"id" => id}) do
    case Workingtimes.get_workingtime(id) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "Working time not found"})

      workingtime ->
        if TimeManager.Accounts.can_access_user_data?(
             conn.assigns.current_user,
             workingtime.user_id
           ) do
          render(conn, :show, workingtime: workingtime)
        else
          conn
          |> put_status(:forbidden)
          |> json(%{error: "You cannot view this user's working times"})
        end
    end
  end

  def update(conn, %{"id" => id, "workingtime" => workingtime_params}) do
    workingtime = Workingtimes.get_workingtime!(id)

    if TimeManager.Accounts.can_access_user_data?(conn.assigns.current_user, workingtime.user_id) do
      with {:ok, %Workingtime{} = workingtime} <-
             Workingtimes.update_workingtime(workingtime, workingtime_params) do
        render(conn, :show, workingtime: workingtime)
      end
    else
      conn
      |> put_status(:forbidden)
      |> json(%{error: "You cannot modify this user's working times"})
    end
  end

  def delete(conn, %{"id" => id}) do
    workingtime = Workingtimes.get_workingtime!(id)

    if TimeManager.Accounts.can_access_user_data?(conn.assigns.current_user, workingtime.user_id) do
      with {:ok, %Workingtime{}} <- Workingtimes.delete_workingtime(workingtime) do
        send_resp(conn, :no_content, "")
      end
    else
      conn
      |> put_status(:forbidden)
      |> json(%{error: "You cannot modify this user's working times"})
    end
  end
end
