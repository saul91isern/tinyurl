#!/bin/sh

set -o errexit
set -o xtrace

bin/tinyurl eval 'Elixir.Tinyurl.Release.migrate()'
bin/tinyurl start
