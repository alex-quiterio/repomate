# RepoMate 🧉

A command-line tool to manage and synchronize multiple git repositories. This tool helps you maintain a list of git repositories and keep them up to date with their remote sources.

## Features

- Maintain a list of repositories to sync
- Add and remove repositories from the sync list
- Automatically clone new repositories
- Update existing repositories
- Pattern-based filtering for selective syncing
- Support for multiple shells (bash, fish, zsh)
- Configurable paths for code and configuration storage

## Installation

### As a Gem (Recommended)

```bash
gem install repomate
```

### From Source

1. Clone the repository:

```bash
git clone git@github.com:alex-quiterio/repomate.git
cd repomate
```

2. Install dependencies:

```bash
bundle install
```

3. Build and install the gem:

```bash
gem build repomate.gemspec
gem install repomate-*.gem
```

### Shell Integration (Optional)

Choose the appropriate shell integration for enhanced functionality:

#### Fish Shell

```bash
mkdir -p ~/.config/fish/functions
cp shell/fish/repomate.fish ~/.config/fish/functions/
```

#### Zsh

```bash
# Add to your ~/.zshrc
source /path/to/repomate/shell/zshell/repomate.zshell
```

#### Bash

```bash
# Add to your ~/.bashrc or ~/.bash_profile
source /path/to/repomate/shell/bash/repomate.bash
```

## Usage

The tool can be used directly from the command line after installation.

### Basic Commands

```bash
# List all repositories in the sync list
repomate list

# Sync all repositories
repomate sync

# Sync repositories matching a pattern
repomate sync -p "myproject"

# Add a repository to the sync list
repomate add -l "git@github.com:alex-quiterio/repomate.git"

# Remove a repository from the sync list
repomate remove -l "git@github.com:alex-quiterio/repomate.git"
```

### Available Options

- `-l, --repo-url URL`: Specify a repository URL for add/remove/sync operations
- `-p, --pattern PATTERN`: Filter repositories by pattern (for sync/list)
- `-h, --help`: Show help information
- `-v, --version`: Show version information

## Repositories Configuration File

The configuration file is a simple text file with one repository URL per line. For example:

```text
git@github.com:user/repo1.git
git@github.com:user/repo2.git
git@github.com:organization/repo3.git
```

The file will be automatically created at `$HOME/code/.subscribed-repos` if it doesn't exist.

## Behavior

- When syncing repositories:
  - If a repository doesn't exist locally, it will be cloned
  - If a repository exists locally, it will be updated (git pull)
  - Updates are performed on the default branch (main/master)
  - Handles uncommitted changes by stashing them temporarily during updates
  - Supports pattern-based filtering to sync only matching repositories

- When adding repositories:
  - Duplicate repositories are not allowed
  - The URL is validated before adding
  - Repository is automatically cloned after being added to the list

- When removing repositories:
  - Repository URL is removed from the sync list
  - Local repository files are also deleted from disk

- Configuration:
  - Default code directory: `$HOME/code`
  - Default config file: `$HOME/code/.subscribed-repos`
  - Directories are created automatically if they don't exist

## Requirements

- Ruby 2.6.0 or higher
- Git
- Optional: Fish, Zsh, or Bash shell (for enhanced shell integration)


## Help

To see all available options and commands:

```bash
repomate --help
```
