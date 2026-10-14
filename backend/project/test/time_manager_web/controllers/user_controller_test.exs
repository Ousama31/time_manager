defmodule TimeManagerWeb.UserControllerTest do
  use TimeManagerWeb.ConnCase

  import TimeManager.AccountsFixtures
  alias TimeManager.Accounts
  alias TimeManager.Accounts.User
  alias TimeManager.Repo

  @create_attrs %{
    username: "some username",
    email: "some email"
  }
  @update_attrs %{
    username: "some updated username",
    email: "some updated email"
  }
  @invalid_attrs %{username: nil, email: nil}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all users", %{conn: conn} do
      conn = get(conn, ~p"/api/users")
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "manager contact" do
    test "an employee can retrieve their assigned manager's contact", %{conn: conn} do
      employee =
        user_fixture(%{
          email: "employee@example.com",
          username: "employee",
          full_name: "Employee",
          password: "secure-password"
        })

      manager =
        user_fixture(%{
          email: "manager@example.com",
          username: "manager",
          full_name: "Manager",
          password: "secure-password"
        })

      manager = Repo.update!(Ecto.Changeset.change(manager, role: :manager))
      {:ok, employee} = Accounts.update_user_manager(employee, manager.id)

      conn =
        conn
        |> authenticated_as(employee)
        |> get(~p"/api/users/#{employee.id}/manager")

      assert json_response(conn, 200)["data"]["email"] == manager.email
    end

    test "an employee cannot retrieve another employee's manager", %{conn: conn} do
      employee =
        user_fixture(%{
          email: "employee@example.com",
          username: "employee",
          full_name: "Employee",
          password: "secure-password"
        })

      other_employee =
        user_fixture(%{
          email: "other@example.com",
          username: "other",
          full_name: "Other Employee",
          password: "secure-password"
        })

      conn =
        conn
        |> authenticated_as(employee)
        |> get(~p"/api/users/#{other_employee.id}/manager")

      assert json_response(conn, 403)["error"] =~ "assigned manager"
    end
  end

  describe "create user" do
    test "renders user when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/api/users", user: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/users/#{id}")

      assert %{
               "id" => ^id,
               "email" => "some email",
               "username" => "some username"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/api/users", user: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update user" do
    setup [:create_user]

    test "renders user when data is valid", %{conn: conn, user: %User{id: id} = user} do
      conn = put(conn, ~p"/api/users/#{user}", user: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/users/#{id}")

      assert %{
               "id" => ^id,
               "email" => "some updated email",
               "username" => "some updated username"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, user: user} do
      conn = put(conn, ~p"/api/users/#{user}", user: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete user" do
    setup [:create_user]

    test "deletes chosen user", %{conn: conn, user: user} do
      conn = delete(conn, ~p"/api/users/#{user}")
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/users/#{user}")
      end
    end
  end

  defp create_user(_) do
    user = user_fixture()

    %{user: user}
  end

  defp authenticated_as(conn, %User{id: user_id}) do
    token = Phoenix.Token.sign(TimeManagerWeb.Endpoint, "user_auth", user_id)
    put_req_header(conn, "x-xsrf-token", token)
  end
end
