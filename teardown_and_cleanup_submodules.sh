#!/usr/bin/env sh

# Note that Skosmos stuff is in here as well, 
# for the time being

echo "Tearing down and cleaning up submodules..."

docker compose -f Skosmos/docker-compose.yml down 
docker compose -f dataverse/docker-compose.yml down
docker compose -f utils/traefik/docker-compose.yml down

echo "The next step will remove any uncommitted changes in the submodules."

echo "Are you sure you want to continue? (y/n)"
read -r answer
if [ "$answer" != "${answer#[Yy]}" ]; then
  echo "Removing uncommitted changes in the submodules..."
  git submodule foreach --recursive git reset --hard
  git submodule foreach --recursive git clean -fd
else
  echo "Aborting cleanup."
  exit 1
fi
echo "Cleanup complete!"

