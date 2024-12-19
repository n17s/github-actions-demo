#!/bin/bash

# Define the target name pattern and the image name
TARGET_NAME="act-CI-test"
IMAGE_NAME="genai-latest"

# Extract container IDs matching the target name
CONTAINER_IDS=$(docker ps -a --format "{{.ID}} {{.Names}}" | grep "$TARGET_NAME" | awk '{print $1}')

# Count the number of matching containers
MATCH_COUNT=$(echo "$CONTAINER_IDS" | wc -l)

if [ "$MATCH_COUNT" -eq 0 ]; then
  echo "No container found matching the name: $TARGET_NAME"
  exit 1
elif [ "$MATCH_COUNT" -gt 1 ]; then
  echo "Multiple containers found matching the name: $TARGET_NAME"
  echo "Matching container IDs:"
  echo "$CONTAINER_IDS"
  exit 1
else
  # Exactly one match
  CONTAINER_ID=$(echo "$CONTAINER_IDS")
  echo "Container ID for $TARGET_NAME: $CONTAINER_ID"
fi

# Execute the copy command in the container
echo "Copying files inside the container..."
docker exec "$CONTAINER_ID" bash -c "cp -ra /opt/hostedtoolcache/* /opt/acttoolcache/"
if [ $? -ne 0 ]; then
  echo "Error copying files in the container."
  exit 1
fi
echo "Files copied successfully."

# Commit the container with the specified changes
echo "Committing the container..."
docker commit \
  --change 'ENV PATH="$PATH:/opt/acttoolcache/Java_Temurin-Hotspot_jdk/21.0.5-11.0.LTS/x64/bin:/opt/acttoolcache/Ruby/3.3.6/x64/bin:/opt/acttoolcache/go/1.23.4/x64/bin:/opt/acttoolcache/go/workspace/bin:/usr/share/dotnet"' \
  --change 'ENV JAVA_HOME="/opt/acttoolcache/Java_Temurin-Hotspot_jdk/21.0.5-11.0.LTS/x64"' \
  --change 'ENV GEM_HOME="/opt/hostedtoolcache/Ruby/3.3.6/x64/lib/ruby/gems"' \
  --change 'ENV GEM_PATH="/opt/hostedtoolcache/Ruby/3.3.6/x64/lib/ruby/gems"' \
  --change 'ENV GOPATH="/opt/acttoolcache/go/workspace"' \
  --change 'ENV DOTNET_ROOT="/usr/share/dotnet"' \
  --change 'ENTRYPOINT ["/bin/sh", "-c", "ln -s /opt/acttoolcache/Ruby /opt/hostedtoolcache/Ruby && exec tail -f /dev/null"]' \
  "$CONTAINER_ID" "$IMAGE_NAME"

if [ $? -ne 0 ]; then
  echo "Error committing the container."
  exit 1
fi
echo "Container committed successfully as $IMAGE_NAME."

