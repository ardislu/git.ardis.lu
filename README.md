# git.ardis.lu

Configurations and scripts for my self-hosted git server.

Tested and running on Debian but these directions should work on any similar `systemd` distribution.

Code repository mirrors: [GitHub](https://github.com/ardislu/git.ardis.lu), [Codeberg](https://codeberg.org/ardislu/git.ardis.lu), [git.ardis.lu](https://git.ardis.lu/git.ardis.lu)

## Setup

1. Install required software:

```
sudo apt install git gitweb highlight ufw fcgiwrap
```

See [Caddy: Install](https://caddyserver.com/docs/install) for directions on installing `caddy`.

Explanation:
- `git`, `gitweb` are naturally required.
- `highlight` for code syntax highlighting on the web view.
- `ufw` for setting up firewall rules (can substitute with whatever you like).
- `fcgiwrap` to call the `gitweb` and `git-http-backend` FastCGI scripts.
- `caddy` for the web server to serve the web view and repos over HTTPS.

2. Clone this repo somewhere on the server.

3. Update `./srv/git/.ssh/authorized_keys` to include all admin SSH keys that should have **write** access to repos.

4. Run `setup.sh` to create or update the `git` user, git scripts, the git repo directory `/srv/git`, and `gitweb` configurations:

```
sudo ./setup.sh
```

5. Open port 443 to allow access over HTTPS:

```
sudo ufw allow "WWW Secure"
```

## View and clone repos

Browse existing repos using the web view: [https://git.ardis.lu](https://git.ardis.lu)

Support for read/write:

Transport protocol | Read | Write | Authorization required?
--- | --- | --- | ---
`ssh://` | Yes | Yes | Yes
`https://` | Yes | No | No
`http://` | No | No | N/A
`git://` | No | No | N/A

`http://` and `git://` are disabled because (1) it simplifies server administration and (2) the lack of integrity checks or encryption makes them subject to tampering. This configuration matches [GitHub's](https://github.blog/security/application-security/improving-git-protocol-security-github/).

URLs to clone individual repos can be found within the repo page on the web view.

## Helper scripts

A minimal set of administrative commands.

### `init`

Create a new repo and optionally set its description for the web view.

```
ssh git@git.ardis.lu init <repository_name> [repository_description]
```

### `rm`

Delete a repo.

```
ssh git@git.ardis.lu rm <repository_name>
```

## Uninstall

To reverse the steps in `setup.sh`.

3. (From another computer) Use the `rm` helper script to delete all repos:

```
ssh git@git.ardis.lu rm <repository_name>
```

4. Delete the `git` user and its home directory `/srv/git`:

```
sudo deluser --remove-home git
```

5. (Optional) Delete `git-shell` from `/etc/shells`:

```
sudo vim /etc/shells
```

### Disable `git-daemon`

These steps are for reference only, they are not needed because `git-daemon` is not enabled on the server.

1. Delete the `ufw` rule to open port 9418 for `git-daemon`:

```
sudo ufw delete limit 9418/tcp
```

2. Stop and delete `git-daemon.service`:

```
sudo systemctl stop git-daemon
sudo systemctl disable git-daemon
sudo rm /etc/systemd/system/git-daemon.service
sudo systemctl daemon-reload
sudo systemctl reset-failed
```
