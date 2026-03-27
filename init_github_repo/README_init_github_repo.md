# init_github_repo.sh

`init_github_repo.sh` creates a clean local Git repository under `~/src/<repo-name>`, adds a first `README.md` and `.gitignore`, makes the initial commit, and can optionally prepare a repo-specific deploy key and GitHub remote.

## What it does

- creates `~/src/<repo-name>`
- runs `git init`
- creates `README.md`
- creates a basic `.gitignore`
- makes the first commit
- renames the default branch to `main`
- optionally adds a GitHub remote
- optionally creates a deploy key for that one repository
- optionally creates the GitHub repo with `gh` and pushes immediately

## Requirements

You need these installed locally:

- `git`
- `ssh-keygen`
- optionally `gh` if you want the script to create the GitHub repo automatically

Your Git identity must already be set:

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

## Download and make executable

If you saved the script in `~/Downloads`:

```bash
chmod +x ~/Downloads/init_github_repo.sh
```

If you saved it somewhere else, use that path instead.

## Basic usage

Create the local repo only:

```bash
~/Downloads/init_github_repo.sh my-project
```

Create the local repo and set the remote URL:

```bash
~/Downloads/init_github_repo.sh my-project --owner YOUR_GITHUB_USERNAME
```

Create the local repo and also generate a repo-specific deploy key:

```bash
~/Downloads/init_github_repo.sh my-project --owner YOUR_GITHUB_USERNAME --deploy-key
```

Create the local repo, create the GitHub repo with GitHub CLI, and push immediately:

```bash
~/Downloads/init_github_repo.sh my-project --owner YOUR_GITHUB_USERNAME --auto-create --private
```

## Options

```text
--owner <github-username-or-org>   GitHub owner for remote URL
--auto-create                      Create the GitHub repo with gh and push immediately
--public                           Create the repo as public when used with --auto-create
--private                          Create the repo as private when used with --auto-create (default)
--deploy-key                       Create a repo-specific deploy key locally
--readme-title <title>             README title override
-h, --help                         Show help
```

## Typical manual workflow

### 1. Run the script

```bash
~/Downloads/init_github_repo.sh my-project --owner YOUR_GITHUB_USERNAME
```

### 2. Create the GitHub repository manually

On GitHub:

- click **New repository**
- name it `my-project`
- do **not** initialize with a README, `.gitignore`, or license
- create the repository

### 3. Push the first commit

```bash
cd ~/src/my-project
git push -u origin main
```

### 4. Confirm sync

```bash
git status
git fetch origin
git branch -vv
```

You should see a clean working tree and `main` tracking `origin/main`.

## Deploy key workflow

A deploy key is usually most useful for a server, VM, CI box, or automation host. It can be limited to a single repository.

### 1. Run the script with `--deploy-key`

```bash
~/Downloads/init_github_repo.sh my-project --owner YOUR_GITHUB_USERNAME --deploy-key
```

### 2. Copy the printed public key

The script prints the public key and stores it at:

```text
~/.ssh/my-project_deploy_key.pub
```

### 3. Add it to the GitHub repository

In GitHub:

- open the repository
- go to **Settings**
- go to **Deploy keys**
- click **Add deploy key**
- paste the public key
- enable **Allow write access** only if this machine should be able to push

### 4. Push

```bash
cd ~/src/my-project
git push -u origin main
```

The script also creates an SSH config host alias like this:

```text
Host github-my-project
  HostName github.com
  User git
  IdentityFile ~/.ssh/my-project_deploy_key
  IdentitiesOnly yes
```

and points `origin` at:

```text
git@github-my-project:YOUR_GITHUB_USERNAME/my-project.git
```

## GitHub CLI automatic workflow

If you already use GitHub CLI:

```bash
gh auth login
~/Downloads/init_github_repo.sh my-project --owner YOUR_GITHUB_USERNAME --auto-create --private
```

This will:

- create the local repo
- create the GitHub repo
- set the remote
- push the first commit

## Notes

- the script refuses to use a non-empty existing directory
- the script does not overwrite an existing deploy key of the same name
- if `origin` already exists, the script updates it
- if you want a normal personal developer setup, an SSH key attached to your GitHub account is usually a better default than a deploy key

## Example commands

```bash
~/Downloads/init_github_repo.sh HomeLab --owner wrightwells
~/Downloads/init_github_repo.sh HomeLab --owner wrightwells --deploy-key
~/Downloads/init_github_repo.sh HomeLab --owner wrightwells --auto-create --private
~/Downloads/init_github_repo.sh HomeLab --owner wrightwells --readme-title "HomeLab Infrastructure"
```
