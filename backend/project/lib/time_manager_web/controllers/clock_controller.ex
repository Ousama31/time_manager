defmodule TimeManagerWeb.ClockController do
  use TimeManagerWeb, :controller

  alias TimeManager.Clocks
  alias TimeManager.Clocks.Clock

  action_fallback TimeManagerWeb.FallbackController

  def index(conn, _params) do
    clocks = Clocks.list_clocks()
    render(conn, :index, clocks: clocks)
  end

  # Switch between work, break, and off-clock states.
  def create(conn, %{"userID" => user_id} = params) do
    if not TimeManager.Accounts.can_access_user_data?(conn.assigns.current_user, user_id) do
      conn
      |> put_status(:forbidden)
      |> json(%{error: "You cannot change this user's clock status"})
    else
      create_transition(conn, user_id, params)
    end
  end

  defp create_transition(conn, user_id, params) do
    last_clock = Clocks.get_clock_by_user(user_id)

    current_state =
      case last_clock do
        nil -> "off"
        %{state: state} when is_binary(state) -> state
        %{status: true} -> "working"
        _ -> "off"
      end

    action = params["action"] || "clock"

    next_state =
      case {action, current_state} do
        {"break", "working"} -> "break"
        {"break", "break"} -> "working"
        {"clock", "off"} -> "working"
        {"clock", "working"} -> "off"
        {"clock", "break"} -> "off"
        _ -> nil
      end

    if is_nil(next_state) do
      conn
      |> put_status(:unprocessable_entity)
      |> json(%{error: "A break can only be started while working"})
    else
      clock_params = %{
        "time" => DateTime.utc_now() |> DateTime.truncate(:second),
        "status" => next_state == "working",
        "state" => next_state,
        "user_id" => String.to_integer(user_id)
      }

      with {:ok, %Clock{} = clock} <- Clocks.create_clock(clock_params) do
        conn
        |> put_status(:created)
        |> render(:show, clock: clock)
      end
    end
  end

  def show(conn, %{"userID" => user_id}) do
    if TimeManager.Accounts.can_access_user_data?(conn.assigns.current_user, user_id) do
      clock = Clocks.get_clock_by_user(user_id)
      render(conn, :show, clock: clock)
    else
      conn
      |> put_status(:forbidden)
      |> json(%{error: "You cannot view this user's clock status"})
    end
  end

  def update(conn, %{"id" => id, "clock" => clock_params}) do
    clock = Clocks.get_clock!(id)

    with {:ok, %Clock{} = clock} <- Clocks.update_clock(clock, clock_params) do
      render(conn, :show, clock: clock)
    end
  end

  def delete(conn, %{"id" => id}) do
    clock = Clocks.get_clock!(id)

    with {:ok, %Clock{}} <- Clocks.delete_clock(clock) do
      send_resp(conn, :no_content, "")
    end
  end
end
