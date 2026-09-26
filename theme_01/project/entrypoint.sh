#!/bin/bash

echo "Check the env file"
if [! -f .env]; then
  echo "no env file"
  exit 1
fi

while !pg_isready -q -h db -U postgres; do
  echo "Wait until the container of the database is usable"
  sleep 2
done

mix ecto.create
mix ecto.migrate
exec mix phx.server