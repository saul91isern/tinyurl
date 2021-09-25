defmodule Tinyurl.DataCase do
  @moduledoc """
  This module defines the setup for tests requiring
  access to the application's data layer.

  You may define functions here to be used as helpers in
  your tests.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use Tinyurl.DataCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  alias Ecto.Adapters.SQL.Sandbox
  alias Ecto.Changeset

  using do
    quote do
      alias Tinyurl.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Tinyurl.DataCase
      import Tinyurl.Factory
    end
  end

  setup tags do
    :ok = Sandbox.checkout(Tinyurl.Repo)

    if tags[:async] or tags[:sandbox] == :shared do
      Sandbox.mode(Tinyurl.Repo, {:shared, self()})
    else
      parent = self()

      allow(parent, [
        Tinyurl.Cache.LinkCache
      ])
    end

    :ok
  end

  @doc """
  A helper that transforms changeset errors into a map of messages.

      assert {:error, changeset} = Accounts.create_user(%{password: "short"})
      assert "password is too short" in errors_on(changeset).password
      assert %{password: ["password is too short"]} = errors_on(changeset)

  """
  def errors_on(changeset) do
    Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end

  defp allow(parent, workers) do
    Enum.each(workers, fn worker ->
      case Process.whereis(worker) do
        nil -> nil
        pid -> Sandbox.allow(Tinyurl.Repo, parent, pid)
      end
    end)
  end
end
