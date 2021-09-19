defmodule Tinyurl.Factory do
  @moduledoc """
      An `ExMachina` factory for url shortening API.
  """
  use ExMachina.Ecto, repo: Tinyurl.Repo

  def link_factory(attrs) do
    %Tinyurl.Links.Link{
      url: "http://foo/bar",
      hash: sequence("foo")
    }
  end
end
