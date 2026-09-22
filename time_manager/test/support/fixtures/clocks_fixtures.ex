defmodule TimeManager.ClocksFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `TimeManager.Clocks` context.
  """

  @doc """
  Generate a clock.
  """
  def clock_fixture(attrs \\ %{}) do
    {:ok, clock} =
      attrs
      |> Enum.into(%{
        status: true,
        time: ~U[2026-09-21 14:19:00Z]
      })
      |> TimeManager.Clocks.create_clock()

    clock
  end
end
