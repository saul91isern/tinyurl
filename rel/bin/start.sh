#!/bin/sh

bin/tinyurl eval 'Elixir.Tinyurl.Release.migrate()'
bin/tinyurl start
