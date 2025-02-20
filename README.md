Forward SSH agent socket into a container

Still experimental -- contact eldorplus@gmail.com if you want help.


## Installation

Assuming you have a `/usr/local`

```
$ git clone git://github.com/github-clonner/docker-ssh-agent-forward
$ cd docker-ssh-agent-forward
$ make
$ make install
```

On every boot, do:

```
pinata-ssh-forward
```

and the you can run `pinata-ssh-mount` to get a Docker CLI fragment that adds
the SSH agent socket and sets `SSH_AUTH_SOCK` within the container.

```
$ pinata-ssh-mount
-v ssh-agent:/ssh-agent -e SSH_AUTH_SOCK=/ssh-agent/ssh-agent.sock

$ docker run -it $(pinata-ssh-mount) 
/ssh-agent-forward ssh -T git@github.com
The authenticity of host 'github.com (192.30.252.128)' can't be established.
RSA key fingerprint is 16:27:ac:a5:76:28:2d:36:63:1b:56:4d:eb:df:a6:48.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added 'github.com,192.30.252.128' (RSA) to the list of known hosts.
PTY allocation request failed on channel 0
Hi avsm! You've successfully authenticated, but GitHub does not provide shell access.
```

To fetch the latest image, do:

```
pinata-ssh-pull
```

## Troubleshooting

If pinata-ssh-forward fails to run, run `ssh-add -l`. If there are no identities, then run `ssh-add`.

## Developing

To build an image yourself rather than fetching from Docker Hub, run
`./pinata-ssh-build.sh` from your clone of this repo.

We didn't bother installing the build script with the Makefile since using the
hub image should be the common case.

## Environment Options
Configure the container with the following environment variables or optionally mount a custom sshd config at `/etc/ssh/sshd_config`:

### General Options

- `SSH_USERS` list of user accounts and uids/gids to create. eg `SSH_USERS=www:48:48,admin:1000:1000:/bin/bash`. The fourth argument for specifying the user shell is optional
- `SSH_ENABLE_ROOT` if "true" unlock the root account
- `SSH_ENABLE_PASSWORD_AUTH` if "true" enable password authentication (disabled by default) (excluding the root user)
- `SSH_ENABLE_ROOT_PASSWORD_AUTH` if "true" enable password authentication for all users including root
- `MOTD` change the login message

### SSH Options

- `GATEWAY_PORTS` if "true" sshd will allow gateway ports
- `TCP_FORWARDING` if "true" sshd will allow TCP forwarding
- `DISABLE_SFTP` if "true" sshd will not accept sftp connections. Note: This does not
prevent file access unless you define a restricted shell for each user that prevents executing
programs that grant file access.

### Restricted Modes

The following three restricted modes, SFTP only, SCP only and Rsync only are mutually exclusive. If no mode is defined,
then all connection types will be accepted. Only one mode can be enabled at a time:

#### SFTP Only

- `SFTP_MODE` if "true" sshd will only accept sftp connections
- `SFTP_CHROOT` if in sftp only mode sftp will be chrooted to this directory. Default "/data"

#### SCP Only

- `SCP_MODE` if "true" sshd will only accept scp connections (uses rssh)

#### Rsync Only

- `RSYNC_MODE` if "true" sshd will only accept rsync connections (uses rssh)

## SSH Host Keys

SSH uses host keys to identify the server. To avoid receiving a security warning the host keys should be mounted on an external volume.

By default this image will create new host keys in `/etc/ssh/keys` which should be mounted on an external volume. If you are using existing keys and they are mounted in `/etc/ssh` this image will use the default host key location making this image compatible with existing setups.

If you wish to configure SSH entirely with environment variables it is suggested that you externally mount `/etc/ssh/keys` instead of `/etc/ssh`.

## Authorized Keys

Mount your .ssh credentials (RSA public keys) at `/root/.ssh/` in order to
access the container via root and set `SSH_ENABLE_ROOT=true` or mount each user's key in
`/etc/authorized_keys/<username>` and set `SSH_USERS` environment config to create the user accounts.

Authorized keys must be either owned by root (uid/gid 0), or owned by the uid/gid that corresponds to the
uid/gid and user specified in `SSH_USERS`.

## SFTP mode

When in sftp only mode (activated by setting `SFTP_MODE=true`) the container will only accept sftp connections. All sftp actions will be chrooted to the `SFTP_CHROOT` directory which defaults to "/data".

Please note that all components of the pathname in the ChrootDirectory directive must be root-owned directories that are not writable by any other user or group (see `man 5 sshd_config`).

## SCP or Rsync modes

When in scp or rsync only mode (activated by setting `SCP_MODE=true` or `RSYNC_MODE=true` respectively) the container will only accept scp or rsync connections. No chroot is provided.

This is provided by using [rssh](http://www.pizzashack.org/rssh/) restricted shell.

## Custom Scripts

Executable shell scripts and binaries can be mounted or copied in to `/etc/entrypoint.d`. These will be run when the container is launched but before sshd is started. These can be used to customise the behaviour of the container.

## Password authentication

**Password authentication is not recommended** however using `SSH_ENABLE_PASSWORD_AUTH=true` you can enable password authentication. The image doesn't provide any way to set user passwords via config but you can use the custom scripts support to run a custom script to set user passwords.
Setting `SSH_ENABLE_ROOT_PASSWORD_AUTH=true` also enables password authentification for the root account.

For example you could add the following script to `/etc/entrypoint.d/`

**setpasswd.sh**

```bash
#!/usr/bin/env bash

set -e

echo 'user1:$6$lAkdPbeeZR7YJiE3$ohWgU3LcSVit/hEZ2VOVKvxD.67.N9h5v4ML7.4X51ZK3kABbTPHkZUPzN9jxQQWXtkLctI0FJZR8CChIwz.S/' | chpasswd --encrypted

# Or if you don't pre-hash the password remove the line above and uncomment the line below.
# echo "user1:user1password" | chpasswd
```
It is strongly recommend to pre-hash passwords. Passwords that are not hashed are a security risk, other users may be able to read the `setpasswd.sh` script and see all other users passwords and keeping plain text passwords is considered bad practice.

To generate a hashed password use `mkpasswd` which is available in this image or use [https://trnubo.github.io/passwd.html](https://trnubo.github.io/passwd.html) to generate a hash in your browser. Example use of `mkpasswd` below.

```
$ docker run --rm -it --entrypoint /usr/bin/env docker.io/panubo/sshd:1.4.0 mkpasswd
Password:
$6$w0ZvF/gERVgv08DI$PTq73dIcZLfMK/Kxlw7rWDvVcYvnWJuOWtxC7sXAYZL69CnItCS.QM.nTUyMzaT0aYjDBdbCH1hDiwbQE8/BY1
```

To start sshd with the `setpasswd.sh` script

```
docker run -ti -p 2222:22 \
  -v $(pwd)/keys/:/etc/ssh/keys \
  -e SSH_USERS=user:1000:1000 \
  -e SSH_ENABLE_PASSWORD_AUTH=true \
  -v $(pwd)/entrypoint.d/:/etc/entrypoint.d/ \
  docker.io/panubo/sshd:1.4.0
```

To enable password authentication on the root account, the previous `setpasswd.sh` script must also define a password for the root user, then
the command will be:

```
docker run -ti -p 2222:22 \
  -e SSH_ENABLE_ROOT_PASSWORD_AUTH=true \
  -v $(pwd)/entrypoint.d/:/etc/entrypoint.d/ \
  docker.io/panubo/sshd:1.3.0
```

## Usage Example

The example below will run interactively and bind to port `2222`. `/data` will be
bind mounted to the host. And the ssh host keys will be persisted in a `keys`
directory.

You can access with `ssh root@localhost -p 2222` using your private key.

```
docker run -ti -p 2222:22 \
  -v ${HOME}/.ssh/id_rsa.pub:/root/.ssh/authorized_keys:ro \
  -v $(pwd)/keys/:/etc/ssh/keys \
  -v $(pwd)/data/:/data/ \
  -e SSH_ENABLE_ROOT=true \
  docker.io/panubo/sshd:1.4.0
```

Create a `www` user with gid/uid 48. You can access with `ssh www@localhost -p 2222` using your private key.

```
docker run -ti -p 2222:22 \
  -v ${HOME}/.ssh/id_rsa.pub:/etc/authorized_keys/www:ro \
  -v $(pwd)/keys/:/etc/ssh/keys \
  -v $(pwd)/data/:/data/ \
  -e SSH_USERS="www:48:48" \
  docker.io/panubo/sshd:1.4.0
```

## Releases

For production usage, please use a versioned release rather than the floating 'latest' tag.

See the [releases](https://github.com/github-clonner/docker-ssh-agent-forward/releases) for tag usage
and release notes.

## Status

Production ready and stable.

## Contributors

* Patrick LUZOLO
* https://github.com/github-clonner/docker-ssh-agent-forward/graphs/contributors

[License](LICENSE.md) is ISC.
