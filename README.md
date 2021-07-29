# docker-tramp - TRAMP integration for docker containers

*Author:* Mario Rodas <marsam@users.noreply.github.com><br>
*Version:* 0.1<br>

`docker-tramp.el` offers a TRAMP method for Docker containers.

> **NOTE**: `docker-tramp.el` relies in the `docker exec` command.  Tested
> with docker version 1.6.x but should work with versions >1.3.  Podman
> also works.

## Usage

Offers the TRAMP method `docker` to access running containers

    C-x C-f /docker:user@container:/path/to/file

    where
      user           is the user that you want to use inside the container (optional)
      container      is the id or name of the container

### [Multi-hop][] examples

If you container is hosted on `vm.example.net`:

    /ssh:vm-user@vm.example.net|docker:user@container:/path/to/file

If you need to run the `docker` command as, say, the `root` user:

    /sudo:root@localhost|docker:user@container:/path/to/file

## Troubleshooting

### Tramp hangs on Alpine container

Busyboxes built with the `ENABLE_FEATURE_EDITING_ASK_TERMINAL` config option
send also escape sequences, which `tramp-wait-for-output` doesn't ignores
correctly.  Tramp upstream fixed in [98a5112][] and is available since
Tramp>=2.3.

For older versions of Tramp you can dump [docker-tramp-compat.el][] in your
`load-path` somewhere and add the following to your `init.el`, which
overwrites `tramp-wait-for-output` with the patch applied:

        (require 'docker-tramp-compat)

### Tramp does not respect remote `PATH`

This is a known issue with Tramp, but is not a bug so much as a poor default
setting.  Adding `tramp-own-remote-path` to `tramp-remote-path` will make
Tramp use the remote's `PATH` environment varialbe.

        (add-to-list 'tramp-remote-path 'tramp-own-remote-path)

[Multi-hop]: https://www.gnu.org/software/emacs/manual/html_node/tramp/Ad_002dhoc-multi_002dhops.html
[98a5112]: http://git.savannah.gnu.org/cgit/tramp.git/commit/?id=98a511248a9405848ed44de48a565b0b725af82c
[docker-tramp-compat.el]: https://github.com/emacs-pe/docker-tramp.el/raw/master/docker-tramp-compat.el


---
Converted from `docker-tramp.el` by [*el2markdown*](https://github.com/Lindydancer/el2markdown).
