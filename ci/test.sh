#!/bin/sh

mix local.hex --force
mix local.rebar --force
mix deps.get
mix compile
mix credo --strict
mix test
