defmodule TodolistWeb.TaskController do
  use TodolistWeb, :controller

  alias Todolist.Tasks
  alias Todolist.Tasks.Task

  action_fallback TodolistWeb.FallbackController

  # =========================================================================
  # ADDED: user_tasks/2 action
  # EXPLANATION: Handles GET requests to `/api/tasks/users/:idUser`.
  # Queries user tasks via `list_user_tasks/1` and returns:
  # - 200 OK with the task list if tasks exist
  # - 404 Not Found if no tasks are associated with the user ID
  # =========================================================================
  def user_tasks(conn, %{"idUser" => user_id}) do
    tasks = Tasks.list_user_tasks(user_id)

    case tasks do
      [] ->
        conn
        |> put_status(:not_found) # HTTP 404
        |> put_view(json: TodolistWeb.ErrorJSON)
        |> render(:"404")

      tasks ->
        render(conn, :index, tasks: tasks) # HTTP 200
    end
  end

  def index(conn, _params) do
    tasks = Tasks.list_tasks()
    render(conn, :index, tasks: tasks)
  end

  # =========================================================================
  # UPDATED: create/2 action
  # EXPLANATION: Replaced `with` statement with a `case` match to guarantee:
  # - HTTP 201 Created on successful insert
  # - HTTP 400 Bad Request on failure/invalid params (as required on Page 4)
  # =========================================================================
  def create(conn, %{"task" => task_params}) do
    case Tasks.create_task(task_params) do
      {:ok, %Task{} = task} ->
        conn
        |> put_status(:created) # HTTP 201
        |> put_resp_header("location", ~p"/api/tasks/#{task}")
        |> render(:show, task: task)

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
  # when a task ID isn't found and return a 404 response.
  # =========================================================================
  def show(conn, %{"id" => id}) do
    task = Tasks.get_task!(id)
    render(conn, :show, task: task)
  rescue
    Ecto.NoResultsError ->
      conn
      |> put_status(:not_found)
      |> put_view(json: TodolistWeb.ErrorJSON)
      |> render(:"404")
  end

  def update(conn, %{"id" => id, "task" => task_params}) do
    task = Tasks.get_task!(id)

    with {:ok, %Task{} = task} <- Tasks.update_task(task, task_params) do
      render(conn, :show, task: task)
    end
  end

  def delete(conn, %{"id" => id}) do
    task = Tasks.get_task!(id)

    with {:ok, %Task{}} <- Tasks.delete_task(task) do
      send_resp(conn, :no_content, "")
    end
  end
end