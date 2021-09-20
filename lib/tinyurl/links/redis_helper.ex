defmodule Tinyurl.RedisHelper do
  @moduledoc """
  Module to communicate with redis.
  """

  alias Redix

  @url_prefix "url"
  @hash_prefix "hash"

  def get_seed do
    Redix.command(:redix, ["INCR", "seed"])
  end

  def set_seed(id) when is_number(id) do
    Redix.command(:redix, ["SET", "seed", id])
  end

  def set_seed(_id), do: {:ok, []}

  def get_link_by_hash(hash) do
    reply = Redix.command(:redix, ["HGET", "#{@hash_prefix}:#{hash}", "url"])

    case reply do
      {:ok, url} when is_binary(url) ->
        {:ok, %{hash: hash, url: url}}

      reply ->
        reply
    end
  end

  def get_link_by_url(url) do
    reply = Redix.command(:redix, ["HGET", "#{@url_prefix}:#{url}", "hash"])

    case reply do
      {:ok, hash} when is_binary(hash) ->
        {:ok, %{hash: hash, url: url}}

      reply ->
        reply
    end
  end

  def put_link(link) do
    url = link.url
    hash = link.hash

    Redix.pipeline(:redix, [
      ["HMSET", "#{@url_prefix}:#{url}", "hash", hash],
      ["HMSET", "#{@hash_prefix}:#{hash}", "url", url]
    ])
  end

  def delete_link(link) do
    url = link.url
    hash = link.hash

    Redix.pipeline(:redix, [
      ["DEL", "#{@url_prefix}:#{url}"],
      ["DEL", "#{@hash_prefix}:#{hash}"]
    ])
  end
end
