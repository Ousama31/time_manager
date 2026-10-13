defmodule TimeManager.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  @roles [:employee, :manager, :admin]

  schema "users" do
    field :username, :string
    field :email, :string
    field :full_name, :string
    field :password, :string, virtual: true
    field :password_hash, :string
    field :role, Ecto.Enum, values: @roles, default: :employee
    field :status, Ecto.Enum, values: [:active, :inactive], default: :active
    field :manager_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :email, :full_name, :password])
    |> validate_required([:username, :email, :full_name, :password])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/)
    |> unique_constraint(:email)
    |> put_pass_hash()
    |> validate_inclusion(:role, @roles)
  end

  def role_changeset(user, attrs) do
    user
    |> cast(attrs, [:role, :status])
    |> validate_inclusion(:role, @roles)
    |> validate_inclusion(:status, [:active, :inactive])
  end

  def profile_changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :email, :full_name, :password])
    |> validate_required([:username, :email, :full_name])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/)
    |> unique_constraint(:email)
    |> put_pass_hash()
  end

  defp put_pass_hash(%Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset) do
    put_change(changeset, :password_hash, Bcrypt.hash_pwd_salt(password))
  end

  defp put_pass_hash(changeset), do: changeset
end
