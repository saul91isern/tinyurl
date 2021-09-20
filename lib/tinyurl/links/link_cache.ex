defmodule Tinyurl.Cache.LinkCache do
  @moduledoc """
  Link cache utility. It handles the side effects of the API
  """
  use GenServer

  alias Tinyurl.RedisHelper

  require Logger

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
    reply = RedisHelper.get_seed()
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
end
