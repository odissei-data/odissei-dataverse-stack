#!/usr/bin/env sh

echo "Tearing down containers and cleaning up submodules..."

docker compose -f dataverse/docker-compose.yml down
docker compose -f utils/traefik/docker-compose.yml down

echo "The next step will remove any uncommitted changes in the submodules."

echo "Are you sure you want to continue? (y/n)"
read -r answer
if [ "$answer" != "${answer#[Yy]}" ]; then
  echo "Removing uncommitted changes in the submodules..."
  git submodule foreach --recursive git reset --hard
  git submodule foreach --recursive git clean -fd
  git submodule update
else
  echo "Aborting cleanup."
  exit 1
fi
echo "Cleanup complete!"

