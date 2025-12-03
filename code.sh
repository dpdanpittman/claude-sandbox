#!/bin/bash

# Interactive script to run Claude Code in Docker

# Check if path was provided as argument
if [ -n "$1" ]; then
  PATH_TO_CODE=$(realpath "$1")
else
  # Interactive prompt
  read -e -p "Enter the path to your code directory: " user_path

  if [ -z "$user_path" ]; then
    echo "Error: No path provided."
    exit 1
  fi

  # Expand ~ and resolve to absolute path
  user_path="${user_path/#\~/$HOME}"
  PATH_TO_CODE=$(realpath "$user_path" 2>/dev/null)

  if [ ! -d "$PATH_TO_CODE" ]; then
    echo "Error: Directory '$user_path' does not exist."
    exit 1
  fi
fi

# Check for Claude authentication
if [ ! -d "$HOME/.claude" ]; then
  echo "Error: Claude Code authentication not found."
  echo "Please run 'claude' on your host machine first to authenticate."
  exit 1
fi

# Ensure Docker image exists
if ! docker image inspect claudecode:latest > /dev/null 2>&1;
then
  echo "Docker image 'claudecode:latest' not found. Please build it first with 'make build'."
  exit 1
fi

# Stop and remove any existing container
if docker ps -a --filter "name=claude-code-dev" | grep -q claude-code-dev; then
  echo "Removing existing container 'claude-code-dev'..."
  docker stop claude-code-dev 2>/dev/null || true
  docker rm claude-code-dev 2>/dev/null || true
fi

docker run -d \
  -v ${PATH_TO_CODE}:/workspace \
  -v $HOME/.claude:/home/dev/.claude \
  --dns 8.8.8.8 \
  --dns 8.8.4.4 \
  --name claude-code-dev \
  --label project=claude-code \
  claudecode:latest \
  tail -f /dev/null

echo "Container 'claude-code-dev' started in detached mode."
echo "Use 'make exec' to enter the container."

