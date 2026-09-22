defmodule Todolist.Tasks.Task do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tasks" do
    field :title, :string
    field :description, :string
    field :status, :string
    belongs_to :user, Todolist.Accounts.User # <-- Association to user's table

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(task, attrs) do
    task
    # |> cast(attrs, [:title, :description, :status])
    # |> validate_required([:title, :description, :status])
    |> cast(attrs, [:title, :description, :status, :user_id])
    |> validate_required([:title, :description, :status, :user_id])
  end
end
