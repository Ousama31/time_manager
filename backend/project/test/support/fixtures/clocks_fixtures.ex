defmodule TimeManager.ClocksFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `TimeManager.Clocks` context.
  """

  @doc """
  Generate a clock.
  """
  def clock_fixture(attrs \\ %{}) do
    attrs = Enum.into(attrs, %{})
    user_id = Map.get(attrs, :user_id) || TimeManager.AccountsFixtures.user_fixture().id

    {:ok, clock} =
      Map.merge(
        %{
          status: true,
          state: "working",
          time: ~U[2026-09-21 14:19:00Z],
          user_id: user_id
        },
        attrs
      )
      |> TimeManager.Clocks.create_clock()

    clock
  end
end
