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
  def list_links(opts \\ []) do
    Link
    |> filter(opts[:search])
    |> Repo.all()
  end

  @doc """
  Gets max links id.

  ## Examples

      iex> max_id()
      1

      iex> max_id()
      nil

  """
  def max_id do
    Link
    |> select([l], max(l.id))
    |> Repo.one()
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
      {:ok, %Link{}}

      iex> get_link_by(hash: "bar")
      ** {:error, :not_found}

  """
  def get_link_by(params) do
    link = Repo.get_by(Link, params)

    case link do
      %Link{} -> {:ok, link}
      _ -> {:error, :not_found}
    end
  end

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
        |> on_insert()

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
    link
    |> Repo.delete()
    |> on_delete()
  end

  @doc """
  Gets duplicated links grouped by url.

  ## Examples

      iex> duplicated_links()
      [%{url: "", ids: [...]}]

  """
  def duplicated_links do
    Link
    |> group_by([l], l.url)
    |> having([l], count(l) > 1)
    |> select([l], %{
      url: l.url,
      links:
        fragment("json_agg(json_build_object('id', ?, 'url', ?, 'hash', ?))", l.id, l.url, l.hash)
    })
    |> Repo.all()
  end

  @doc """
  Deletes all links by given ids.

  ## Examples

      iex> delete_all([id])
      {1, [id]}

  """
  def delete_all(ids) do
    Link
    |> where([l], l.id in ^ids)
    |> Repo.delete_all()
  end

  defp filter(query, search) when byte_size(search) > 0 do
    query
    |> or_where([l], ilike(l.url, ^"%#{search}%"))
    |> or_where([l], ilike(l.hash, ^"%#{search}%"))
  end

  defp filter(query, _search), do: query

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

  defp on_insert(reply) do
    with {:ok, %Link{} = link} <- reply do
      LinkCache.refresh(link)
      reply
    end
  end

  defp on_delete(reply) do
    with {:ok, %Link{} = link} <- reply do
      LinkCache.delete(link)
      reply
    end
  end
end
