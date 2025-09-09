#!/bin/sh

git_shell_path="$(command -v git-shell || true)"

if [ -z "$git_shell_path" ]; then
  echo "Error: git-shell not found in PATH. Install git or check its path." >&2
  exit 1
fi

# Add git-shell to /etc/shells if not already there
if ! grep -qxF "$git_shell_path" /etc/shells; then
  echo "$git_shell_path" >> /etc/shells
fi

# Setup files in /srv/git
mkdir -p /srv/git/.ssh
cp -rf ./srv/git /srv

# Create git user if it does not already exist
id -u git &>/dev/null || useradd --home-dir /srv/git --shell "$git_shell_path" --no-create-home --skel /dev/null git

# Set permissions for /srv/git
chown -R git:git /srv/git
chmod -R 755 /srv/git
chmod 700 /srv/git/.ssh
chmod 600 /srv/git/.ssh/authorized_keys

# Globally disable safe directory checks because only I will be writing to this server. This step is required
# or else there will be "fatal: detected dubious ownership" errors when the web server attempts to
# serve the repos as a user other than "git".
# See https://stackoverflow.com/a/71904131/21084807
git config --system safe.directory '*'

# Otherwise HEAD will point to "master" when using init, even if the pushed repo has renamed main branch
git config --system init.defaultBranch main

# Setup gitweb
cp -f ./etc/gitweb.conf /etc
cp -f ./etc/caddy/Caddyfile /etc/caddy
systemctl enable --now fcgiwrap
systemctl restart caddy

# Below steps for configuring git-daemon are for reference only.
# It is commented out because the git:// protocol's lack of encryption or integrity checks make it
# subject to tampering.

# Add or update git-daemon.service, which enables read-only access via git:// protocol (port 9418)
# cp -f ./etc/systemd/system/git-daemon.service /etc/systemd/system
# systemctl daemon-reload
# systemctl enable --now git-daemon.service

# Configure ufw to open port 9418 with rate limiting
# ufw limit 9418/tcp comment 'rate-limited git-daemon'
