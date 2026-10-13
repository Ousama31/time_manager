defmodule TimeManager.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias TimeManager.Repo

  alias TimeManager.Accounts.User
  alias TimeManager.Clocks.Clock
  alias TimeManager.Workingtimes.Workingtime

  @token_max_age_seconds 60 * 60 # 1 hour

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users(params) do
    query =
      case params["email"] do
        nil -> User
        email -> where(User, [u], u.email == ^email)
      end

    query =
      case params["username"] do
        nil -> query
        username -> where(query, [u], u.username == ^username)
      end

    Repo.all(from u in query, order_by: [asc: u.inserted_at, asc: u.id])
  end

  def list_team_users(manager_id) do
    Repo.all(
      from u in User,
        where: u.manager_id == ^manager_id and u.role == :employee,
        order_by: [asc: u.full_name, asc: u.id]
    )
  end

  def can_access_user_data?(%User{role: :admin}, _user_id), do: true

  def can_access_user_data?(%User{id: user_id, role: role} = user, requested_id)
      when role in [:employee, :manager] do
    if to_string(user_id) == to_string(requested_id) do
      true
    else
      case user do
        %User{role: :manager, id: manager_id} ->
          case Integer.parse(to_string(requested_id)) do
            {id, ""} -> Repo.exists?(from u in User, where: u.id == ^id and u.manager_id == ^manager_id)
            _ -> false
          end

        _ ->
          false
      end
    end
  end

  def can_access_user_data?(_user, _user_id), do: false

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  # This function is used to get a user by ID without raising an error if the user does not exist.

  def get_user(id), do: Repo.get(User, id)

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user(attrs) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  def update_user_role(%User{} = user, attrs) do
    user
    |> User.role_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a user.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user(%User{} = user) do
    Repo.transaction(fn ->
      Repo.delete_all(from clock in Clock, where: clock.user_id == ^user.id)
      Repo.delete_all(from workingtime in Workingtime, where: workingtime.user_id == ^user.id)

      case Repo.delete(user) do
        {:ok, deleted_user} -> deleted_user
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end


  ## Authentication functions

  def authenticate_user(identifier, password) do
    user =
      Repo.one(
        from u in User,
          where: u.username == ^identifier or u.email == ^identifier
      )

    cond do
      user && Bcrypt.verify_pass(password, user.password_hash) ->
        if user.status == :active do
          token = Phoenix.Token.sign(TimeManagerWeb.Endpoint, "user_auth", user.id)
          {:ok, user, token}
        else
          {:error, :unauthorized}
        end

      user ->
        {:error, :unauthorized}

      true ->
        Bcrypt.no_user_verify()
        {:error, :unauthorized}
    end
  end

  def verify_token(token) do

    case Phoenix.Token.verify(TimeManagerWeb.Endpoint, "user_auth", token,
           max_age: @token_max_age_seconds
         ) do
      {:ok, user_id} ->
        case get_user(user_id) do
          nil -> {:error, :user_not_found}
          %User{status: :active} = user -> {:ok, user}
          _inactive_user -> {:error, :unauthorized}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end
end
