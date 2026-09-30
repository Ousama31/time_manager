defmodule TimeManagerWeb.ClockController do
  use TimeManagerWeb, :controller

  alias TimeManager.Clocks
  alias TimeManager.Clocks.Clock

  action_fallback TimeManagerWeb.FallbackController

  def index(conn, _params) do
    clocks = Clocks.list_clocks()
    render(conn, :index, clocks: clocks)
  end

  # Switch between clocking in and out.
  def create(conn, %{"userID" => user_id}) do
    last_clock = Clocks.get_clock_by_user(user_id)

    status =
      if last_clock do
        !last_clock.status
      else
        true
      end

    clock_params = %{
      "time" => DateTime.utc_now() |> DateTime.truncate(:second),
      "status" => status,
      "user_id" => String.to_integer(user_id)
    }

    with {:ok, %Clock{} = clock} <- Clocks.create_clock(clock_params) do
      conn
      |> put_status(:created)
      |> render(:show, clock: clock)
    end
  end

  def show(conn, %{"userID" => user_id}) do
    clock = Clocks.get_clock_by_user(user_id)
    render(conn, :show, clock: clock)
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
