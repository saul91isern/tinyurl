defmodule TinyurlWeb.FallbackController do
  @moduledoc """
  Translates controller action results into valid `Plug.Conn` responses.

  See `Phoenix.Controller.action_fallback/1` for more details.
  """
  use TinyurlWeb, :controller

  # This clause handles errors returned by Ecto's insert/update/delete.
  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(TinyurlWeb.ChangesetView)
    |> render("error.json", changeset: changeset)
  end

  # This clause is an example of how to handle resources that cannot be found.
  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(TinyurlWeb.ErrorView)
    |> render(:"404")
  end

  # This clause handles the creation a link when it already exists and the creation is not needed.
  def call(conn, {:ok, %{} = link}) when is_map_key(link, :url) and is_map_key(link, :hash) do
    conn
    |> put_status(303)
    |> put_view(TinyurlWeb.ErrorView)
    |> render(:"303")
  end
end
