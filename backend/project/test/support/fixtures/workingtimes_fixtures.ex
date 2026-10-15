defmodule TimeManager.WorkingtimesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `TimeManager.Workingtimes` context.
  """

  @doc """
  Generate a workingtime.
  """
  def workingtime_fixture(attrs \\ %{}) do
    attrs = Enum.into(attrs, %{})
    user_id = Map.get(attrs, :user_id) || TimeManager.AccountsFixtures.user_fixture().id

    {:ok, workingtime} =
      Map.merge(
        %{
          end: ~U[2026-09-21 14:23:00Z],
          start: ~U[2026-09-21 14:19:00Z],
          user_id: user_id
        },
        attrs
      )
      |> TimeManager.Workingtimes.create_workingtime()

    workingtime
  end
end
