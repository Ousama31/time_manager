defmodule TimeManagerWeb.WorkingtimeController do
  use TimeManagerWeb, :controller

  alias TimeManager.Workingtimes
  alias TimeManager.Workingtimes.Workingtime

  action_fallback TimeManagerWeb.FallbackController

  #update the index function to accept userID as a parameter and filter the workingtime by userID
  def index(conn, %{"userID" => user_id} = params) do
    workingtime = Workingtimes.list_workingtime(user_id, params)
    render(conn, :index, workingtime: workingtime)
  end

  #update the create function to accept userID as a parameter and associate the new workingtime with the userID
  def create(conn, %{"userID" => user_id, "workingtime" => workingtime_params}) do

    # add the user_id from the URL to the workingtime data
    workingtime_params = Map.put(workingtime_params, "user_id", String.to_integer(user_id))

    with {:ok, %Workingtime{} = workingtime} <-
      Workingtimes.create_workingtime(workingtime_params) do
      conn
      |> put_status(:created)
      #|> put_resp_header("location", ~p"/api/workingtime/#{workingtime}")
      |> render(:show, workingtime: workingtime)
    end
  end

  def show(conn, %{"id" => id}) do
    workingtime = Workingtimes.get_workingtime!(id)
    render(conn, :show, workingtime: workingtime)
  end

  def update(conn, %{"id" => id, "workingtime" => workingtime_params}) do
    workingtime = Workingtimes.get_workingtime!(id)

    with {:ok, %Workingtime{} = workingtime} <- Workingtimes.update_workingtime(workingtime, workingtime_params) do
      render(conn, :show, workingtime: workingtime)
    end
  end

  def delete(conn, %{"id" => id}) do
    workingtime = Workingtimes.get_workingtime!(id)

    with {:ok, %Workingtime{}} <- Workingtimes.delete_workingtime(workingtime) do
      send_resp(conn, :no_content, "")
    end
  end
end
