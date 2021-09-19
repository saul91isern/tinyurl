defmodule Tinyurl.Hasher do
  @moduledoc """
  Hashing helper module.
  """
  alias Base62
  ## Client API
  def encode(seed) do
    Base62.encode(seed)
  end
end
