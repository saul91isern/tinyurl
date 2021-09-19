defmodule Tinyurl.Cache.LinkCache do
  @moduledoc """
  Link cache utility.
  """
  use GenServer

  alias Redix

  require Logger

  ## Client API

  def start_link(config \\ []) do
    GenServer.start_link(__MODULE__, config, name: __MODULE__)
  end

  def get_seed do
    GenServer.call(__MODULE__, :get_seed)
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
end
