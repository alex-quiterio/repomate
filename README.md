# RepoMate 🧉

A command-line tool to manage and synchronize multiple git repositories. This tool helps you maintain a list of git repositories and keep them up to date with their remote sources.

## Features

- Maintain a list of repositories to sync
- Add and remove repositories from the sync list
- Automatically clone new repositories
- Update existing repositories
- Configurable paths for code and configuration storage

## Installation

1. Ensure you have Ruby installed on your system
2. Copy `repomate.rb` to `~/.local/bin/`:
```bash
mkdir -p ~/.local/bin
cp repomate.rb ~/.local/bin/
chmod +x ~/.local/bin/repomate.rb
```

3. Add the fish function to your fish config:
```bash
mkdir -p ~/.config/fish/functions
cp repomate.fish ~/.config/fish/functions/
```

## Usage

The tool can be used either directly through Ruby or via the fish shell function.

### Basic Commands

```bash
# List all repositories in the sync list
repomate list

# Sync all repositories
repomate sync

# Sync one repository
repomate sync -l "git@github.com:alex-quiterio/repomate.git"

# Add a repository to the sync list
repomate add -l "git@github.com:alex-quiterio/repomate.git"

# Remove a repository from the sync list
repomate remove -l "git@github.com:alex-quiterio/repomate.git"
```

### For the future

- Automatically pick `.subscribed-repos` under the current directory.
- Set a default repomate configuration for the config file and code paths.

```bash
# Set custom code directory in the default config
repomate --set-default-config $HOME/.repomate-config
```

And this is what the default repomate config could look like
```
default_code_path=$HOME/project_y/code
default_config_file_path=$HOME/.subscribed-repos
```

## Repositories Configuration File

The configuration file is a simple text file with one repository URL per line. For example:

```text
https://github.com/user/repo1.git
https://github.com/user/repo2.git
https://github.com/organization/repo3.git
```

The file will be automatically created at `$HOME/code/.subscribed-repos` if it doesn't exist.

## Behavior

- When syncing repositories:
  - If a repository doesn't exist locally, it will be cloned
  - If a repository exists locally, it will be updated (git pull)
  - Updates are performed on the 'main' branch

- When adding repositories:
  - Duplicate repositories are not allowed
  - The URL is validated before adding

- When removing repositories:
  - Only the repository URL is removed from the sync list
  - The local repository files are not deleted

## Requirements

- Ruby
- Git
- Fish shell (for fish function integration)


## Help

To see all available options and commands:

```bash
repomate --help
```
