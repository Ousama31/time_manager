defmodule TimeManagerWeb.ClockControllerTest do
  use TimeManagerWeb.ConnCase

  import TimeManager.AccountsFixtures
  import TimeManager.ClocksFixtures
  alias TimeManager.Accounts.User

  setup %{conn: conn} do
    user = user_fixture()
    conn = conn |> put_req_header("accept", "application/json") |> authenticated_as(user)
    {:ok, conn: conn, user: user}
  end

  test "shows the latest clock state for the signed-in user", %{conn: conn, user: user} do
    conn = get(conn, ~p"/api/clocks/#{user.id}")
    assert json_response(conn, 200)["data"] == nil
  end

  test "creates a clock-in transition", %{conn: conn, user: user} do
    conn = post(conn, ~p"/api/clocks/#{user.id}", action: "clock")

    assert %{"id" => _id, "status" => true, "state" => "working"} =
             json_response(conn, 201)["data"]
  end

  test "creates a break transition and resumes work on the next break action", %{
    conn: conn,
    user: user
  } do
    _clock = clock_fixture(user_id: user.id)

    conn = post(conn, ~p"/api/clocks/#{user.id}", action: "break")
    assert json_response(conn, 201)["data"]["state"] == "break"

    conn =
      Phoenix.ConnTest.build_conn()
      |> put_req_header("accept", "application/json")
      |> authenticated_as(user)
      |> post(~p"/api/clocks/#{user.id}", action: "break")

    assert json_response(conn, 201)["data"]["state"] == "working"
  end

  test "clock out after working", %{conn: conn, user: user} do
    _clock = clock_fixture(user_id: user.id)
    conn = post(conn, ~p"/api/clocks/#{user.id}", action: "clock")
    assert json_response(conn, 201)["data"]["state"] == "off"
  end

  test "prevents clocking another user in or out", %{conn: conn} do
    other = user_fixture()
    conn = post(conn, ~p"/api/clocks/#{other.id}", action: "clock")
    assert json_response(conn, 403)["error"] =~ "cannot change"
  end

  test "manager can view an assigned employee clock" do
    manager = manager_fixture()
    employee = user_fixture()
    {:ok, _} = TimeManager.Accounts.update_user_manager(employee, manager.id)
    _clock = clock_fixture(user_id: employee.id)

    conn =
      Phoenix.ConnTest.build_conn()
      |> put_req_header("accept", "application/json")
      |> authenticated_as(manager)
      |> get(~p"/api/clocks/#{employee.id}")

    assert json_response(conn, 200)["data"]["state"] == "working"
  end

  test "requires authentication to create a clock transition", %{user: user} do
    conn = Phoenix.ConnTest.build_conn() |> post(~p"/api/clocks/#{user.id}", action: "clock")
    assert json_response(conn, 401)["error"] == "Unauthorized"
  end

  test "rejects starting a break while clocked out", %{conn: conn, user: user} do
    conn = post(conn, ~p"/api/clocks/#{user.id}", action: "break")
    assert json_response(conn, 422)["error"] =~ "break can only be started"
  end

  test "prevents an employee from viewing another user's clock", %{conn: conn} do
    other_user = user_fixture()
    conn = get(conn, ~p"/api/clocks/#{other_user.id}")
    assert json_response(conn, 403)["error"] =~ "cannot view"
  end

  test "requires authentication", %{user: user} do
    conn = Phoenix.ConnTest.build_conn() |> get(~p"/api/clocks/#{user.id}")
    assert json_response(conn, 401)["error"] == "Unauthorized"
  end

  test "clock fixture belongs to its user" do
    clock = clock_fixture()
    assert clock.user_id
  end

  defp authenticated_as(conn, %User{id: user_id}) do
    token = Phoenix.Token.sign(TimeManagerWeb.Endpoint, "user_auth", user_id)
    put_req_header(conn, "x-xsrf-token", token)
  end

  defp manager_fixture do
    user = user_fixture()
    {:ok, manager} = user |> User.role_changeset(%{role: :manager}) |> TimeManager.Repo.update()
    manager
  end
end
