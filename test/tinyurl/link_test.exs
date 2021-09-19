defmodule Tinyurl.LinkTest do
  use Tinyurl.DataCase

  alias Ecto.Changeset
  alias Redis
  alias Tinyurl.Links.Link

  describe "changeset/1" do
    test "returns valid changeset" do
      params = %{"url" => url, "hash" => hash} = string_params_for(:link)

      assert %Changeset{valid?: true, changes: %{hash: ^hash, url: ^url}} =
               Link.changeset(%Link{}, params)
    end

    test "returns invalid changeset when required params missing" do
      params = string_params_for(:link)

      assert %Changeset{valid?: false, errors: [url: {"can't be blank", [validation: :required]}]} =
               Link.changeset(%Link{}, Map.delete(params, "url"))

      assert %Changeset{
               valid?: false,
               errors: [hash: {"can't be blank", [validation: :required]}]
             } = Link.changeset(%Link{}, Map.delete(params, "hash"))
    end

    test "returns invalid changeset when field's length is exceeded" do
      params = string_params_for(:link)
      long_url = Map.get(params, "url") <> String.duplicate("xyz", 682)
      long_hash = Map.get(params, "hash") <> String.duplicate("foo", 3)

      assert %Changeset{
               valid?: false,
               errors: [
                 url:
                   {"should be at most %{count} character(s)",
                    [count: 2048, validation: :length, kind: :max, type: :string]}
               ]
             } = Link.changeset(%Link{}, Map.put(params, "url", long_url))

      assert %Changeset{
               valid?: false,
               errors: [
                 hash:
                   {"should be at most %{count} character(s)",
                    [count: 8, validation: :length, kind: :max, type: :string]}
               ]
             } = Link.changeset(%Link{}, Map.put(params, "hash", long_hash))
    end

    test "casts url to decoded binary if needed" do
      params =
        %{"url" => url, "hash" => hash} =
        string_params_for(:link, url: "https%3A%2F%2Felixir-lang.org")

      decoded = URI.decode(url)

      assert %Changeset{valid?: true, changes: %{hash: ^hash, url: ^decoded}} =
               Link.changeset(%Link{}, params)
    end

    test "validates url valid format" do
      params = string_params_for(:link)

      url = "foo.es/bar"

      assert %Changeset{
               valid?: false,
               errors: [url: {"expected schema to be informed", [validation: :format]}]
             } = Link.changeset(%Link{}, Map.put(params, "url", url))

      url = "http://"

      assert %Changeset{
               valid?: false,
               errors: [url: {"expected host to be informed", [validation: :format]}]
             } = Link.changeset(%Link{}, Map.put(params, "url", url))

      url = "http://bar/xyz"
      assert %Changeset{valid?: true} = Link.changeset(%Link{}, Map.put(params, "url", url))
    end
  end
end
