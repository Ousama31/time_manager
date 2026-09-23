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
  #update for a user and optionally filter by start and end dates
  def list_workingtime(user_id, params) do
    # convert the user id from the URL into an integer
    user_id = String.to_integer(user_id)

    # get all working times that belong to this user
    query =
      from w in Workingtime,
      where: w.user_id == ^user_id

    # if start and end dates are provided, filter between them
    query =
      if params["start"] && params["end"] do
        # convert the start and end values from text into datetime values
        {:ok, start_time, _} = DateTime.from_iso8601(params["start"])
        {:ok, end_time, _} = DateTime.from_iso8601(params["end"])

        # keep only working times inside the requested date range
        from w in query,
        where: w.start >= ^start_time and w.end <= ^end_time
      else
        # if no dates are provided, keep the original user query
        query
      end

    # execute the query and return the results
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
