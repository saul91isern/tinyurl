defmodule Tinyurl.Cache.LinkCache do
  @moduledoc """
  Link cache utility. It handles the side effects of the API
  """
  use GenServer

  alias Tinyurl.Links
  alias Tinyurl.RedisHelper

  require Logger

  ## Client API

  def start_link(config \\ []) do
    GenServer.start_link(__MODULE__, config, name: __MODULE__)
  end

  def get_seed do
    GenServer.call(__MODULE__, :get_seed)
  end

  def reset_seed do
    GenServer.call(__MODULE__, :reset_seed)
  end

  def get_link_by_hash(hash) do
    GenServer.call(__MODULE__, {:link_by_hash, hash})
  end

  def get_link_by_url(url) do
    GenServer.call(__MODULE__, {:link_by_url, url})
  end

  def refresh(%{} = link) do
    GenServer.cast(__MODULE__, {:refresh, link})
  end

  def delete(%{} = link) do
    GenServer.cast(__MODULE__, {:delete, link})
  end

  def migrate do
    GenServer.cast(__MODULE__, :migrate)
  end

  ## GenServer Callbacks
  @impl GenServer
  def init(state) do
    name = String.replace_prefix("#{__MODULE__}", "Elixir.", "")
    Logger.info("Running #{name}")
    {:ok, state}
  end

  @impl GenServer
  def handle_call(:get_seed, _from, state) do
    reply = RedisHelper.get_seed()
    {:reply, reply, state}
  end

  @impl GenServer
  def handle_call(:reset_seed, _from, state) do
    id = Links.max_id()
    reply = RedisHelper.set_seed(id)
    {:reply, reply, state}
  end

  @impl GenServer
  def handle_call({:link_by_hash, hash}, _from, state) do
    reply = RedisHelper.get_link_by_hash(hash)
    {:reply, reply, state}
  end

  @impl GenServer
  def handle_call({:link_by_url, url}, _from, state) do
    reply = RedisHelper.get_link_by_url(url)
    {:reply, reply, state}
  end

  @impl GenServer
  def handle_cast({:refresh, link}, state) do
    RedisHelper.put_link(link)
    {:noreply, state}
  end

  @impl GenServer
  def handle_cast({:delete, link}, state) do
    RedisHelper.delete_link(link)
    {:noreply, state}
  end

  @impl GenServer
  def handle_cast(:migrate, state) do
    # Maybe we should include a deletion policy
    # based on ttl
    # we want to get all duplicated links by url
    # and keep only one of the links and delete
    # the rest of them
    clean_duplicates()
    # then we load all links into cache
    load_data()

    {:noreply, state}
  end

  defp clean_duplicates do
    links_to_delete =
      Links.duplicated_links()
      |> Enum.flat_map(fn %{links: [_head | tail]} -> tail end)
      |> Enum.map(fn %{"id" => id, "url" => url, "hash" => hash} ->
        %{id: id, url: url, hash: hash}
      end)

    ids_to_delete = links_to_delete |> Enum.map(& &1.id) |> Enum.uniq()

    {deleted, _} = Links.delete_all(ids_to_delete)

    Logger.info("Deleted #{deleted} duplicated links from database")

    unless deleted != Enum.count(ids_to_delete) do
      {oks, errors} =
        links_to_delete
        |> Enum.map(&RedisHelper.delete_link/1)
        |> Enum.split_with(&(elem(&1, 0) == :ok))

      Logger.info(
        "Deletion in cache finished with #{Enum.count(oks)} deletions and #{Enum.count(errors)} errors"
      )
    end
  end

  defp load_data do
    {oks, errors} =
      Links.list_links()
      |> Enum.map(&RedisHelper.put_link/1)
      |> Enum.split_with(&(elem(&1, 0) == :ok))

    Logger.info("Put #{Enum.count(oks)} links with #{Enum.count(errors)} errors")
  end
end
