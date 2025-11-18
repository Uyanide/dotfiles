## Gitea with custom SSH port

Since in most cases Gitea will be deployed within containers, it cannot use the same port (`22`) as the host machine to handle git operations via SSH. In my case the port `222` is used instead. Meanwhiles, this can cause some extra steps to set the correct remote URL for local repositories, since the port is different from the default one.

There are few approaches to handle this:

1. Edit `~/.ssh/config`

like:

```
Host gitea
    HostName git.example.tld
    User git
    Port 222
    IdentityFile /path/to/private/key
```

then:

```sh
git remote add origin gitea:username/repo.git
```

2. Use full URL with port

> [!WARNING]
>
> The `scp`-like syntax `user@host:repo.git` does not support port specification. `ssh://` URL scheme must be used instead.

```sh
git remote add origin ssh://git@example.tld:222/username/repo.git
```

3. Use `GIT_SSH_COMMAND` environment variable

```sh
GIT_SSH_COMMAND='ssh -p 222'
```

4. and more...
   - aliases
   - scripts
   - etc.

## Local Repo with Multiple Remotes

> [!TIP]
>
> Check current remotes with:
>
> ```sh
> git remote -v
> ```
>
> and remove a remote with:
>
> ```sh
> git remote remove <name>
> ```

Local repositories can have multiple remotes configured. This is useful when pushing to the primary repository and also to a backup repository.

And there are multiple ways to add multiple remotes:

1. Use different names for remotes

```sh
git remote add origin ssh://git@example.tld/username/repo.git

git remote add backup ssh://git@backup.tld/username/repo.git
```

then push to both remotes:

```sh
git push origin main
git push backup main
```

Without referring to remotes explicitly, git will use `origin` by default. To fetch from all remotes, use `git fetch --all` or directly `git pull --all`.

> [!NOTE]
>
> The command `git push --all` is for pushing all local branches, not for pushing to all configured remote URLs.

2. Use `git remote set-url --add`

```sh
git remote set-url --add origin ssh://git@example.tld/username/repo.git
git remote set-url --add origin ssh://git@backup.tld/username/repo.git
```

then push to both remotes:

```sh
git push origin
```

A single `git push origin` will push to all URLs configured for the `origin` remote.

> [!IMPORTANT]
>
> By default, `git fetch` and `git pull` will only interact with the first (fetch) URL configured for a remote.
>
> The `git fetch --all` command fetches from all configured **remotes** (e.g., `origin`, `backup`), not from all URLs within a single remote.
>
> Similarly, `git pull --all` will first run `git fetch --all` and then merge the current local branch with its upstream branch. The merge action only applies to the current branch.
