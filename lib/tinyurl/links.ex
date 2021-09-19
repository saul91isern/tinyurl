defmodule Tinyurl.Links do
  @moduledoc """
  The Links context.
  """

  import Ecto.Query, warn: false

  alias Tinyurl.Cache.LinkCache
  alias Tinyurl.Hasher
  alias Tinyurl.Links.Link
  alias Tinyurl.Repo

  @doc """
  Returns the list of links.

  ## Examples

      iex> list_links()
      [%Link{}, ...]

  """
  def list_links do
    Repo.all(Link)
  end

  @doc """
  Gets a single link.

  Raises `Ecto.NoResultsError` if the Link does not exist.

  ## Examples

      iex> get_link!(123)
      %Link{}

      iex> get_link!(456)
      ** (Ecto.NoResultsError)

  """
  def get_link!(id), do: Repo.get!(Link, id)

  @doc """
  Gets a single link by given fields.

  nil if the Link does not exist.

  ## Examples

      iex> get_link_by(hash: "foo")
      %Link{}

      iex> get_link_by(hash: "bar")
      ** nil

  """
  def get_link_by(params), do: Repo.get_by(Link, params)

  @doc """
  Creates a link.

  ## Examples

      iex> create_link(%{field: value})
      {:ok, %Link{}}

      iex> create_link(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_link(attrs \\ %{}) do
    reply = LinkCache.get_seed()

    case reply do
      {:ok, seed} when is_number(seed) ->
        # generate base 62 hash with seed
        hash = Hasher.encode(seed)
        # build changeset and insert
        attrs
        |> change_link(hash)
        |> Repo.insert()

      _ ->
        {:error, seed: [format: :invalid]}
    end
  end

  @doc """
  Deletes a link.

  ## Examples

      iex> delete_link(link)
      {:ok, %Link{}}

      iex> delete_link(link)
      {:error, %Ecto.Changeset{}}

  """
  def delete_link(%Link{} = link) do
    Repo.delete(link)
  end

  defp change_link(attrs, hash) when is_binary(hash) do
    attrs =
      attrs
      |> Enum.into(%{}, fn
        {"url", value} -> {:url, value}
        tuple -> tuple
      end)
      |> Map.take([:url])
      |> Map.put(:hash, hash)

    Link.changeset(%Link{}, attrs)
  end

  defp change_link(attrs, _), do: Link.changeset(%Link{}, attrs)
end
