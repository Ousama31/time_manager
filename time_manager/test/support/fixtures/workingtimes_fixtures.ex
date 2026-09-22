defmodule TimeManager.WorkingtimesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `TimeManager.Workingtimes` context.
  """

  @doc """
  Generate a workingtime.
  """
  def workingtime_fixture(attrs \\ %{}) do
    {:ok, workingtime} =
      attrs
      |> Enum.into(%{
        end: ~U[2026-09-21 14:23:00Z],
        start: ~U[2026-09-21 14:23:00Z]
      })
      |> TimeManager.Workingtimes.create_workingtime()

    workingtime
  end
end
