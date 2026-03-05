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

echo "The Final (optional step) is to wipe the shared volumes, 
echo "which will remove all data from the dataverse application. 
echo "This is useful if you want to start with a clean slate, 
echo "but be aware that it will also remove any data that you have created in the dataverse application!"
echo ""
echo "Do you want to wipe the shared volumes? (y/n)"
read -r answer
if [ "$answer" != "${answer#[Yy]}" ]; then
  echo "Wiping shared volumes..."
  # Removes the 'dataverse/docker-dev-volumes' directory and its contents recursively and forcefully.
  echo "This step requires sudo privileges. Please enter your password if prompted."
  sudo rm -rf dataverse/docker-dev-volumes
else
  echo "Keeping shared volumes."
fi

echo "Cleanup complete!"

