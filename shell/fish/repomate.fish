# shell/fish/repomate.fish
function repomate command repomate $argv
end

# Add completions for the commands
complete -c repomate -f -a "sync" -d "Synchronize all repositories"
complete -c repomate -f -a "add" -d "Add repository to sync list"
complete -c repomate -f -a "remove" -d "Remove repository from sync list"
complete -c repomate -f -a "list" -d "Show all repositories in sync list"
