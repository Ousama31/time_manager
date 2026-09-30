defmodule TimeManager.Workingtimes do
  @moduledoc """
  The Workingtimes context.
  """

  import Ecto.Query, warn: false
  alias TimeManager.Repo

  alias TimeManager.Workingtimes.Workingtime

  @doc """
  Returns the list of workingtime.

  ## Examples

      iex> list_workingtime()
      [%Workingtime{}, ...]

  """
  def list_workingtime(user_id, params) do
    user_id = String.to_integer(user_id)

    query =
      from w in Workingtime,
        where: w.user_id == ^user_id

    # Apply the date range only when both values are present.
    query =
      if params["start"] && params["end"] do
        {:ok, start_time, _} = DateTime.from_iso8601(params["start"])
        {:ok, end_time, _} = DateTime.from_iso8601(params["end"])

        from w in query,
          where: w.start >= ^start_time and w.end <= ^end_time
      else
        query
      end

    Repo.all(query)
  end

  @doc """
  Gets a single workingtime.

  Raises `Ecto.NoResultsError` if the Workingtime does not exist.

  ## Examples

      iex> get_workingtime!(123)
      %Workingtime{}

      iex> get_workingtime!(456)
      ** (Ecto.NoResultsError)

  """
  def get_workingtime!(id), do: Repo.get!(Workingtime, id)

  @doc """
  Creates a workingtime.

  ## Examples

      iex> create_workingtime(%{field: value})
      {:ok, %Workingtime{}}

      iex> create_workingtime(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_workingtime(attrs) do
    %Workingtime{}
    |> Workingtime.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a workingtime.

  ## Examples

      iex> update_workingtime(workingtime, %{field: new_value})
      {:ok, %Workingtime{}}

      iex> update_workingtime(workingtime, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_workingtime(%Workingtime{} = workingtime, attrs) do
    workingtime
    |> Workingtime.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a workingtime.

  ## Examples

      iex> delete_workingtime(workingtime)
      {:ok, %Workingtime{}}

      iex> delete_workingtime(workingtime)
      {:error, %Ecto.Changeset{}}

  """
  def delete_workingtime(%Workingtime{} = workingtime) do
    Repo.delete(workingtime)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking workingtime changes.

  ## Examples

      iex> change_workingtime(workingtime)
      %Ecto.Changeset{data: %Workingtime{}}

  """
  def change_workingtime(%Workingtime{} = workingtime, attrs \\ %{}) do
    Workingtime.changeset(workingtime, attrs)
  end
end
