defmodule TimeManager.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :username, :string
      add :email, :string
      add :full_name, :string
      add :password_hash, :string
      # add :role, :string, default: "employee", null: false
      # or remove add role migration cz we cant have both

      timestamps(type: :utc_datetime)
    end
  end
end
