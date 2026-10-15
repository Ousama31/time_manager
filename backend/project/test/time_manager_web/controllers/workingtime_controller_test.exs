defmodule TimeManagerWeb.WorkingtimeControllerTest do
  use TimeManagerWeb.ConnCase

  import TimeManager.AccountsFixtures
  import TimeManager.WorkingtimesFixtures
  alias TimeManager.Accounts.User

  setup %{conn: conn} do
    user = user_fixture()
    conn = conn |> put_req_header("accept", "application/json") |> authenticated_as(user)
    {:ok, conn: conn, user: user}
  end

  test "lists the signed-in user's working times", %{conn: conn, user: user} do
    conn = get(conn, ~p"/api/workingtime/#{user.id}")
    assert json_response(conn, 200)["data"] == []
  end

  test "creates a working-time entry for the URL user", %{conn: conn, user: user} do
    attrs = %{start: "2026-09-21T14:19:00Z", end: "2026-09-21T14:23:00Z", kind: "work"}
    conn = post(conn, ~p"/api/workingtime/#{user.id}", workingtime: attrs)
    assert %{"id" => id, "kind" => "work"} = json_response(conn, 201)["data"]

    conn =
      Phoenix.ConnTest.build_conn()
      |> put_req_header("accept", "application/json")
      |> authenticated_as(user)
      |> get(~p"/api/workingtime/#{user.id}/#{id}")

    assert json_response(conn, 200)["data"]["id"] == id
  end

  test "rejects invalid working-time data", %{conn: conn, user: user} do
    conn = post(conn, ~p"/api/workingtime/#{user.id}", workingtime: %{start: nil, end: nil})
    assert json_response(conn, 422)["errors"] != %{}
  end

  test "prevents creating working time for another user", %{conn: conn} do
    other = user_fixture()

    conn =
      post(conn, ~p"/api/workingtime/#{other.id}",
        workingtime: %{start: "2026-09-21T14:19:00Z", end: "2026-09-21T14:23:00Z", kind: "work"}
      )

    assert json_response(conn, 403)["error"] =~ "cannot create"
  end

  test "prevents an employee from listing another user's working times", %{conn: conn} do
    other_user = user_fixture()
    conn = get(conn, ~p"/api/workingtime/#{other_user.id}")
    assert json_response(conn, 403)["error"] =~ "cannot view"
  end

  test "updates a working-time entry", %{conn: conn, user: user} do
    entry = workingtime_fixture(user_id: user.id)
    attrs = %{start: "2026-09-22T14:19:00Z", end: "2026-09-22T14:23:00Z"}
    conn = put(conn, ~p"/api/workingtime/#{entry.id}", workingtime: attrs)
    assert json_response(conn, 200)["data"]["start"] == "2026-09-22T14:19:00Z"
  end

  test "prevents updating another user's working-time entry", %{conn: conn} do
    other = user_fixture()
    entry = workingtime_fixture(user_id: other.id)
    conn = put(conn, ~p"/api/workingtime/#{entry.id}", workingtime: %{kind: "break"})
    assert json_response(conn, 403)["error"] =~ "cannot modify"
  end

  test "deletes a working-time entry", %{conn: conn, user: user} do
    entry = workingtime_fixture(user_id: user.id)
    conn = delete(conn, ~p"/api/workingtime/#{entry.id}")
    assert response(conn, 204)
  end

  test "prevents deleting another user's working-time entry", %{conn: conn} do
    other = user_fixture()
    entry = workingtime_fixture(user_id: other.id)
    conn = delete(conn, ~p"/api/workingtime/#{entry.id}")
    assert json_response(conn, 403)["error"] =~ "cannot modify"
  end

  test "requires ownership when showing a working-time entry", %{conn: conn} do
    other = user_fixture()
    entry = workingtime_fixture(user_id: other.id)
    conn = get(conn, ~p"/api/workingtime/#{other.id}/#{entry.id}")
    assert json_response(conn, 403)["error"] =~ "cannot view"
  end

  test "returns not found for a missing working-time entry", %{conn: conn} do
    conn = get(conn, ~p"/api/workingtime/999999/999999")
    assert json_response(conn, 404)["error"] == "Working time not found"
  end

  test "manager can view assigned employee working times" do
    manager = manager_fixture()
    employee = user_fixture()
    {:ok, _} = TimeManager.Accounts.update_user_manager(employee, manager.id)
    entry = workingtime_fixture(user_id: employee.id)

    conn =
      authenticated_as(Phoenix.ConnTest.build_conn(), manager)
      |> put_req_header("accept", "application/json")
      |> get(~p"/api/workingtime/#{employee.id}/#{entry.id}")

    assert json_response(conn, 200)["data"]["id"] == entry.id
  end

  test "requires authentication", %{user: user} do
    conn = Phoenix.ConnTest.build_conn() |> get(~p"/api/workingtime/#{user.id}")
    assert json_response(conn, 401)["error"] == "Unauthorized"
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
