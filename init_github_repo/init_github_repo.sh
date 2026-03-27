#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  init_github_repo.sh <repo-name> [options]

Options:
  --owner <github-username-or-org>   GitHub owner for remote URL
  --auto-create                      Create the GitHub repo with gh and push immediately
  --public                           Create the repo as public when used with --auto-create
  --private                          Create the repo as private when used with --auto-create (default)
  --deploy-key                       Create a repo-specific deploy key locally
  --readme-title <title>             README title override
  -h, --help                         Show this help

Examples:
  init_github_repo.sh my-project --owner wrightwells
  init_github_repo.sh my-project --owner wrightwells --deploy-key
  init_github_repo.sh my-project --owner wrightwells --auto-create --private
USAGE
}

err() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || err "Required command not found: $1"
}

repo_name=""
owner=""
auto_create=false
visibility="private"
create_deploy_key=false
readme_title=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --owner)
      shift
      [[ $# -gt 0 ]] || err "--owner requires a value"
      owner="$1"
      ;;
    --auto-create)
      auto_create=true
      ;;
    --public)
      visibility="public"
      ;;
    --private)
      visibility="private"
      ;;
    --deploy-key)
      create_deploy_key=true
      ;;
    --readme-title)
      shift
      [[ $# -gt 0 ]] || err "--readme-title requires a value"
      readme_title="$1"
      ;;
    --*)
      err "Unknown option: $1"
      ;;
    *)
      if [[ -z "$repo_name" ]]; then
        repo_name="$1"
      else
        err "Unexpected argument: $1"
      fi
      ;;
  esac
  shift || true
done

[[ -n "$repo_name" ]] || {
  usage
  exit 1
}

need_cmd git
need_cmd ssh-keygen

if ! git config --global user.name >/dev/null 2>&1; then
  err 'Git user.name is not set. Run: git config --global user.name "Your Name"'
fi
if ! git config --global user.email >/dev/null 2>&1; then
  err 'Git user.email is not set. Run: git config --global user.email "you@example.com"'
fi

repo_dir="$HOME/src/$repo_name"
mkdir -p "$HOME/src"

if [[ -e "$repo_dir" && -n "$(find "$repo_dir" -mindepth 1 -maxdepth 1 2>/dev/null | head -n 1)" ]]; then
  err "Directory already exists and is not empty: $repo_dir"
fi
mkdir -p "$repo_dir"
cd "$repo_dir"

if [[ ! -d .git ]]; then
  git init
fi

if [[ -z "$readme_title" ]]; then
  readme_title="$repo_name"
fi

cat > README.md <<EOF2
# $readme_title

Initial repository setup.
EOF2

cat > .gitignore <<'EOF2'
# OS / editor
.DS_Store
Thumbs.db
*.swp
*.swo
.vscode/
.idea/

# Environment / secrets
.env
.env.*
*.local

# Logs
*.log
EOF2

git add README.md .gitignore

if git diff --cached --quiet; then
  echo "Nothing new to commit."
else
  git commit -m "Initial commit"
fi

git branch -M main

remote_added=false
if [[ -n "$owner" ]]; then
  remote_url="git@github.com:${owner}/${repo_name}.git"
  if git remote get-url origin >/dev/null 2>&1; then
    git remote set-url origin "$remote_url"
  else
    git remote add origin "$remote_url"
  fi
  remote_added=true
fi

deploy_key_path="$HOME/.ssh/${repo_name}_deploy_key"
if [[ "$create_deploy_key" == true ]]; then
  if [[ -e "$deploy_key_path" || -e "${deploy_key_path}.pub" ]]; then
    echo "Deploy key already exists at ${deploy_key_path}"
  else
    ssh-keygen -t ed25519 -C "${repo_name} deploy key" -f "$deploy_key_path" -N ""
    chmod 600 "$deploy_key_path"
    chmod 644 "${deploy_key_path}.pub"
    echo
    echo "Deploy public key created at: ${deploy_key_path}.pub"
    echo "Add this in GitHub: Repo -> Settings -> Deploy keys -> Add deploy key"
    echo
    cat "${deploy_key_path}.pub"
    echo
  fi

  ssh_config="$HOME/.ssh/config"
  mkdir -p "$HOME/.ssh"
  touch "$ssh_config"
  chmod 600 "$ssh_config"
  host_alias="github-${repo_name}"
  if ! grep -q "^Host ${host_alias}$" "$ssh_config"; then
    cat >> "$ssh_config" <<EOF2

Host ${host_alias}
  HostName github.com
  User git
  IdentityFile ${deploy_key_path}
  IdentitiesOnly yes
EOF2
  fi

  if [[ -n "$owner" ]]; then
    deploy_remote_url="git@${host_alias}:${owner}/${repo_name}.git"
    if git remote get-url origin >/dev/null 2>&1; then
      git remote set-url origin "$deploy_remote_url"
    else
      git remote add origin "$deploy_remote_url"
    fi
    remote_added=true
  fi
fi

if [[ "$auto_create" == true ]]; then
  [[ -n "$owner" ]] || err "--auto-create requires --owner"
  need_cmd gh

  if ! gh auth status >/dev/null 2>&1; then
    err "GitHub CLI is not authenticated. Run: gh auth login"
  fi

  if gh repo view "$owner/$repo_name" >/dev/null 2>&1; then
    echo "GitHub repo already exists: $owner/$repo_name"
  else
    gh repo create "$owner/$repo_name" --source . --remote origin "$visibility" --push
    echo "GitHub repo created and initial push completed."
    exit 0
  fi
fi

echo
echo "Repository prepared at: $repo_dir"
echo
if [[ "$remote_added" == true ]]; then
  echo "Remote origin: $(git remote get-url origin)"
else
  echo "No remote set yet. Re-run with --owner <github-username-or-org> to set origin."
fi

echo
echo "Next steps:"
if [[ "$auto_create" == false ]]; then
  if [[ -n "$owner" ]]; then
    cat <<EOF2
1. Create the empty GitHub repository named '$repo_name' under '$owner'.
2. Do not add a README, .gitignore, or license on GitHub.
3. If you used --deploy-key, add the printed public key as a deploy key in the repo settings.
4. Push with:
   cd "$repo_dir"
   git push -u origin main
EOF2
  else
    cat <<EOF2
1. Create the empty GitHub repository named '$repo_name'.
2. Add the remote:
   cd "$repo_dir"
   git remote add origin git@github.com:YOUR_GITHUB_USERNAME/$repo_name.git
3. Push with:
   git push -u origin main
EOF2
  fi
fi
