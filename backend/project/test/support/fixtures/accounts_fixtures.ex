defmodule TimeManager.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `TimeManager.Accounts` context.
  """

  @doc """
  Generate a user.
  """
  def user_fixture(attrs \\ %{}) do
    suffix = System.unique_integer([:positive])

    {:ok, user} =
      attrs
      |> Enum.into(%{
        email: "user#{suffix}@example.com",
        username: "user#{suffix}",
        full_name: "Test User #{suffix}",
        password: "secure-password"
      })
      |> TimeManager.Accounts.create_user()

    user
  end
end
