# shell/zsh/repomate.zsh
function repomate() {
  ruby ~/.local/bin/sync-repos.rb "$@"
}
