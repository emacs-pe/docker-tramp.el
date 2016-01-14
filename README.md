# docker-tramp - TRAMP integration for docker containers

*Author:* Mario Rodas <marsam@users.noreply.github.com><br>
*Version:* 0.1<br>

`docker-tramp.el` offers a TRAMP method for Docker containers.

> **NOTE**: `docker-tramp.el` relies in the `docker exec` command.  Tested
> with docker version 1.6.x but should work with versions >1.3

## Usage

Offers the TRAMP method `docker` to access running containers

    C-x C-f /docker:user@container:/path/to/file

    where
      user           is the user that you want to use (optional)
      container      is the id or name of the container


---
Converted from `docker-tramp.el` by [*el2markdown*](https://github.com/Lindydancer/el2markdown).
