# Claude Code Docker Environment

A containerized development environment for using Claude Code with multi-language projects. This setup provides an isolated, reproducible environment with Claude Code, Go, Python, Rust, Node.js, and common development tools.

## Overview

This project provides a Docker-based environment that includes:

- Debian Trixie Slim base
- Go 1.24.1
- Python 3 with pip and venv
- Rust (latest stable via rustup)
- Node.js 20.x
- Claude Code CLI
- ripgrep (for Claude Code search functionality)
- Common development tools (git, curl, jq, tree, protobuf-compiler, etc.)
- Non-root user for security

## Prerequisites

- Docker installed on your system
- Your code repository or project directory
- Claude Code authentication set up on your host machine

## Initial Setup

### 1. Authenticate Claude Code on Your Host

Before using the Docker container, you need to authenticate Claude Code on your host machine:

```bash
# Install npm packages in user directory (avoids sudo)
mkdir -p ~/.npm-global
npm config set prefix '~/.npm-global'
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.zshrc  # or ~/.bashrc
source ~/.zshrc  # or source ~/.bashrc

# Install and authenticate Claude Code
npm install -g @anthropic-ai/claude-code
claude

# Complete the authentication in your browser
# This creates ~/.claude directory with your credentials
```

### 2. Build the Docker Image

```bash
make build
```

This builds the Docker image tagged as `claudecode:latest`.

## Usage

### Quick Start

The easiest way to get started:

```bash
# Build the image
make build

# Run Claude Code (will prompt for your project path)
make run
```

### Running Claude Code on Your Project

#### Option 1: One-Step Run (Recommended)

```bash
make run
```

This command will:

1. Prompt you for your project directory path
2. Stop and remove any existing container
3. Start a new container in detached mode with:
   - Your project mounted at `/workspace`
   - Your `~/.claude` authentication directory mounted
   - Google DNS servers configured (8.8.8.8, 8.8.4.4)
4. Automatically launch Claude Code with `--dangerously-skip-permissions` flag (safe in Docker)

**First-time users**: You may be prompted to authenticate again inside the container. Follow the link provided and enter the code to complete authentication.

#### Option 2: Manual Steps

**Step 1: Start the Container**

You can start the container using the `code.sh` script with either method:

**Interactive mode** (prompts for path):

```bash
./code.sh
```

**Direct path argument**:

```bash
./code.sh /path/to/your/project
```

The script will:

- Check for Claude authentication in `~/.claude`
- Check if a container is already running and clean it up
- Mount your project directory to `/workspace` inside the container
- Mount your `~/.claude` directory for authentication persistence
- Configure DNS for reliable API connectivity
- Start the container in detached mode with label `project=claude-code`

**Step 2: Enter the Container**

Use Claude Code directly:

```bash
make exec
```

Or open a bash shell:

```bash
make shell
```

**Step 3: Stop the Container**

When you're done:

```bash
make stop
```

### Additional Container Management

**Check container status:**

```bash
make status
```

**View container logs:**

```bash
make logs
```

**Restart the container:**

```bash
make restart
```

**Full cleanup (stop, remove container and image):**

```bash
make clean
```

## Makefile Commands

- `make help` - Display all available commands
- `make build` - Build the Docker image
- `make run` - Start container and launch Claude Code (interactive)
- `make exec` - Attach to running container with Claude Code
- `make shell` - Open bash shell in running container
- `make stop` - Stop the container
- `make start` - Start the container (non-interactive)
- `make restart` - Stop and restart the container
- `make status` - Show container status
- `make logs` - Show and follow container logs
- `make clean` - Remove container and image (full cleanup)

## Project Structure

```
.
├── Makefile                 # Build and deployment commands
├── claudecode.dockerfile    # Docker image definition
├── code.sh                  # Convenience script to run Claude Code
├── .gitignore              # Git ignore patterns
└── README.md               # This file
```

## Environment Details

- **Working Directory**: `/workspace`
- **User**: `dev` (non-root)
- **Go Path**: `/home/dev/go`
- **Rust Path**: `/home/dev/.cargo`
- **Python**: System Python 3 with pip and venv
- **Base Image**: `debian:trixie-slim`
- **Authentication**: Mounted from `~/.claude` on host

## Security Notes

- The container runs as a non-root user (`dev`) for security
- Your authentication credentials are mounted from your host's `~/.claude` directory
- The `--dangerously-skip-permissions` flag is used safely within the Docker sandbox
- The container is labeled with `project=claude-code` for easy identification
- Use `make stop` to properly clean up the container when done

## Troubleshooting

### Authentication Issues

If you get "Request timed out" errors:

1. Ensure you've authenticated on your host: `claude` (outside Docker)
2. Check that `~/.claude` directory exists on your host
3. If prompted in the container, complete the authentication flow
4. Restart the container: `make restart`

### Container Already Running

If you see `Container 'claude-code-dev' is already running`:

- Use `make exec` to enter the existing container
- Or use `make restart` to stop and restart with fresh configuration

### Permission Issues

The container runs as user `dev` (UID 1001). If you encounter permission issues:

- Ensure your project directory has appropriate read/write permissions
- The `~/.claude` directory is mounted read-write for state persistence

### Network/DNS Issues

The container is configured with Google DNS (8.8.8.8, 8.8.4.4) for reliable connectivity. If you still experience issues:

```bash
# Test from inside the container
make shell
curl -I https://api.anthropic.com
ping api.anthropic.com
```

### Docker Build Fails

If the build fails:

- Check your internet connection (required for downloading packages)
- Ensure Docker has sufficient disk space
- Try cleaning Docker cache: `docker system prune`

### Read-Only File System Errors

If you see `EROFS: read-only file system` errors, ensure the `.claude` directory is mounted read-write (not `:ro`).

## Customization

### Adding More Tools

To add additional tools to the container, edit `claudecode.dockerfile` and add them to the `apt-get install` command or add new `RUN` commands. Remember to rebuild:

```bash
make build
```

### Changing Language Versions

**Go**: Update the download URL in `claudecode.dockerfile`:

```dockerfile
RUN curl -OL https://go.dev/dl/go1.25.0.linux-amd64.tar.gz && \
```

**Node.js**: Update the setup script version:

```dockerfile
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
```

**Rust**: Rust is installed via rustup. To update Rust inside the container, run:

```bash
rustup update
```

### Mounting Additional Volumes

Edit `code.sh` to add more volume mounts:

```bash
docker run -d \
  -v ${PATH_TO_CODE}:/workspace \
  -v $HOME/.claude:/home/dev/.claude \
  -v /path/to/other/data:/data \  # Add additional mounts here
  --dns 8.8.8.8 \
  --dns 8.8.4.4 \
  --name claude-code-dev \
  --label project=claude-code \
  claudecode:latest \
  tail -f /dev/null
```

## Known Issues

- OAuth tokens may expire during long-running sessions, requiring re-authentication
- First run in container may require interactive authentication even with host credentials mounted

## License

This project configuration is provided as-is for development purposes.
