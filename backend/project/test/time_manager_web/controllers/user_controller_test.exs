defmodule TimeManagerWeb.UserControllerTest do
  use TimeManagerWeb.ConnCase

  import TimeManager.AccountsFixtures
  alias TimeManager.Accounts
  alias TimeManager.Accounts.User
  alias TimeManager.Repo

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  test "admin lists users", %{conn: conn} do
    admin = admin_fixture()
    employee = user_fixture()
    conn = authenticated_as(conn, admin) |> get(~p"/api/users")
    assert Enum.map(json_response(conn, 200)["data"], & &1["id"]) == [admin.id, employee.id]
  end

  test "admin filters users by email and username", %{conn: conn} do
    admin = admin_fixture()
    user = user_fixture()
    _other = user_fixture()

    conn =
      authenticated_as(conn, admin)
      |> get(~p"/api/users?email=#{user.email}&username=#{user.username}")

    assert Enum.map(json_response(conn, 200)["data"], & &1["id"]) == [user.id]
  end

  test "user show returns the requested user", %{conn: conn} do
    user = user_fixture()
    conn = authenticated_as(conn, user) |> get(~p"/api/users/#{user.id}")
    assert json_response(conn, 200)["data"]["id"] == user.id
  end

  test "employees cannot list users", %{conn: conn} do
    employee = user_fixture()
    conn = authenticated_as(conn, employee) |> get(~p"/api/users")
    assert json_response(conn, 403)["error"] =~ "Manager or admin"
  end

  test "manager lists only their assigned employees", %{conn: conn} do
    manager = manager_fixture()
    employee = user_fixture()
    other_employee = user_fixture()
    {:ok, _employee} = Accounts.update_user_manager(employee, manager.id)

    conn = authenticated_as(conn, manager) |> get(~p"/api/users")
    assert Enum.map(json_response(conn, 200)["data"], & &1["id"]) == [employee.id]
    refute other_employee.id in Enum.map(json_response(conn, 200)["data"], & &1["id"])
  end

  test "manager lists unassigned employees", %{conn: conn} do
    manager = manager_fixture()
    employee = user_fixture()
    conn = authenticated_as(conn, manager) |> get(~p"/api/users/unassigned")
    assert Enum.map(json_response(conn, 200)["data"], & &1["id"]) == [employee.id]
  end

  test "manager can assign an unassigned employee", %{conn: conn} do
    manager = manager_fixture()
    employee = user_fixture()

    conn =
      authenticated_as(conn, manager)
      |> patch(~p"/api/users/#{employee.id}", user: %{manager_id: manager.id})

    assert json_response(conn, 200)["data"]["manager_id"] == manager.id
  end

  test "manager contact returns the assigned manager to its employee", %{conn: conn} do
    manager = manager_fixture()
    employee = user_fixture()
    {:ok, employee} = Accounts.update_user_manager(employee, manager.id)
    conn = authenticated_as(conn, employee) |> get(~p"/api/users/#{employee.id}/manager")

    assert json_response(conn, 200)["data"] == %{
             "id" => manager.id,
             "full_name" => manager.full_name,
             "email" => manager.email
           }
  end

  test "employee without a manager gets not found", %{conn: conn} do
    employee = user_fixture()
    conn = authenticated_as(conn, employee) |> get(~p"/api/users/#{employee.id}/manager")
    assert json_response(conn, 404)["error"] == "No assigned manager found"
  end

  test "employee cannot retrieve another employee's manager", %{conn: conn} do
    employee = user_fixture()
    other_employee = user_fixture()
    conn = authenticated_as(conn, employee) |> get(~p"/api/users/#{other_employee.id}/manager")
    assert json_response(conn, 403)["error"] =~ "assigned manager"
  end

  test "employee can sign up through the public registration route", %{conn: conn} do
    params = %{
      username: "new-employee",
      email: "new@example.com",
      full_name: "New Employee",
      password: "secure-password"
    }

    conn = post(conn, ~p"/api/users/sign_up", user: params)
    assert %{"id" => id, "email" => "new@example.com"} = json_response(conn, 201)["data"]
    assert Accounts.get_user!(id).role == :employee
  end

  test "sign up rejects invalid user data", %{conn: conn} do
    conn = post(conn, ~p"/api/users/sign_up", user: %{username: nil, email: "invalid"})
    assert json_response(conn, 422)["errors"] != %{}
  end

  test "public signup accepts flat user parameters", %{conn: conn} do
    params = %{
      username: "flat-user",
      email: "flat@example.com",
      full_name: "Flat User",
      password: "secure-password"
    }

    conn = post(conn, ~p"/api/users/sign_up", params)
    assert json_response(conn, 201)["data"]["email"] == "flat@example.com"
  end

  test "user can update their own profile", %{conn: conn} do
    user = user_fixture()

    attrs = %{
      username: "updated-user",
      email: "updated@example.com",
      full_name: "Updated User",
      password: "new-secure-password"
    }

    conn = authenticated_as(conn, user) |> patch(~p"/api/users/#{user.id}", user: attrs)
    assert json_response(conn, 200)["data"]["email"] == "updated@example.com"
  end

  test "admin can delete another user", %{conn: conn} do
    admin = admin_fixture()
    user = user_fixture()
    conn = authenticated_as(conn, admin) |> delete(~p"/api/users/#{user.id}")
    assert response(conn, 204)
    refute Accounts.get_user(user.id)
  end

  test "admin cannot delete their own account", %{conn: conn} do
    admin = admin_fixture()
    conn = authenticated_as(conn, admin) |> delete(~p"/api/users/#{admin.id}")
    assert json_response(conn, 422)["error"] =~ "cannot delete"
  end

  test "non-admin cannot delete a user", %{conn: conn} do
    employee = user_fixture()
    other = user_fixture()
    conn = authenticated_as(conn, employee) |> delete(~p"/api/users/#{other.id}")
    assert json_response(conn, 403)["error"] =~ "Admin access"
  end

  test "manager cannot change a user outside their team", %{conn: conn} do
    manager = manager_fixture()
    employee = user_fixture()

    conn =
      authenticated_as(conn, manager)
      |> patch(~p"/api/users/#{employee.id}", user: %{manager_id: manager.id})

    assert json_response(conn, 200)["data"]["manager_id"] == manager.id
  end

  test "admin cannot deactivate their own account", %{conn: conn} do
    admin = admin_fixture()

    conn =
      authenticated_as(conn, admin)
      |> patch(~p"/api/users/#{admin.id}", user: %{status: "inactive"})

    assert json_response(conn, 422)["error"] =~ "cannot suspend"
  end

  test "protected user routes require authentication", %{conn: conn} do
    conn = get(conn, ~p"/api/users")
    assert json_response(conn, 401)["error"] == "Unauthorized"
  end

  defp admin_fixture do
    user = user_fixture()
    {:ok, admin} = user |> User.role_changeset(%{role: :admin}) |> Repo.update()
    admin
  end

  defp manager_fixture do
    user = user_fixture()
    {:ok, manager} = user |> User.role_changeset(%{role: :manager}) |> Repo.update()
    manager
  end

  defp authenticated_as(conn, %User{id: user_id}) do
    token = Phoenix.Token.sign(TimeManagerWeb.Endpoint, "user_auth", user_id)
    put_req_header(conn, "x-xsrf-token", token)
  end
end
