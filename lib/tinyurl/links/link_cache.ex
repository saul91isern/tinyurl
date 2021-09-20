defmodule Tinyurl.Cache.LinkCache do
  @moduledoc """
  Link cache utility.
  """
  use GenServer

  alias Redix

  require Logger

  @url_prefix "url"
  @hash_prefix "hash"

  ## Client API

  def start_link(config \\ []) do
    GenServer.start_link(__MODULE__, config, name: __MODULE__)
  end

  def get_seed do
    GenServer.call(__MODULE__, :get_seed)
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

  ## GenServer Callbacks
  @impl GenServer
  def init(state) do
    name = String.replace_prefix("#{__MODULE__}", "Elixir.", "")
    Logger.info("Running #{name}")
    {:ok, state}
  end

  @impl GenServer
  def handle_call(:get_seed, _from, state) do
    reply = Redix.command(:redix, ["INCR", "seed"])
    {:reply, reply, state}
  end

  @impl GenServer
  def handle_call({:link_by_hash, hash}, _from, state) do
    reply = Redix.command(:redix, ["HGET", "#{@hash_prefix}:#{hash}", "url"])

    reply =
      case reply do
        {:ok, url} when is_binary(url) ->
          {:ok, %{hash: hash, url: url}}

        reply ->
          reply
      end

    {:reply, reply, state}
  end

  @impl GenServer
  def handle_call({:link_by_url, url}, _from, state) do
    reply = Redix.command(:redix, ["HGET", "#{@url_prefix}:#{url}", "hash"])

    reply =
      case reply do
        {:ok, hash} when is_binary(hash) ->
          {:ok, %{hash: hash, url: url}}

        reply ->
          reply
      end

    {:reply, reply, state}
  end

  @impl GenServer
  def handle_cast({:refresh, link}, state) do
    url = link.url
    hash = link.hash

    Redix.pipeline(:redix, [
      ["HMSET", "#{@url_prefix}:#{url}", "hash", hash],
      ["HMSET", "#{@hash_prefix}:#{hash}", "url", url]
    ])

    {:noreply, state}
  end

  @impl GenServer
  def handle_cast({:delete, link}, state) do
    url = link.url
    hash = link.hash

    Redix.pipeline(:redix, [
      ["DEL", "#{@url_prefix}:#{url}"],
      ["DEL", "#{@hash_prefix}:#{hash}"]
    ]) 

    {:noreply, state}
  end
end
