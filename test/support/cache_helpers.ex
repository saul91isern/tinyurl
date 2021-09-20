defmodule CacheHelpers do
  @moduledoc """
      Functions to support test operations over cache 
  """
  def clean do
    Redix.command(:redix, ["DEL", "seed"])
    clean_urls()
    clean_hashes()
  end

  defp clean_urls do
    {:ok, reply} = Redix.command(:redix, ["KEYS", "url:*"])
    urls = List.flatten(reply)
    clean_keys(urls)
  end

  defp clean_hashes do
    {:ok, reply} = Redix.command(:redix, ["KEYS", "hash:*"])
    hashes = List.flatten(reply)
    clean_keys(hashes)
  end

  defp clean_keys([_ | _] = keys) do
    cmds = Enum.map(keys, &["DEL", &1])
    Redix.pipeline(:redix, cmds)
  end

  defp clean_keys(_keys), do: {:ok, []}
end
