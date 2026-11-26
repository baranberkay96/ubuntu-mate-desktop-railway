# NOTICE: Ubuntu MATE 26.04 Desktop in Your Browser template

## Base image and its components

The service is built `FROM ghcr.io/linuxserver/webtop:ubuntu-mate-c8975261-ls295@sha256:aaa70851e0b69dad95ee84b381bc1a77e62806ca35df82121ac739427ac645f6` (built 2026-11-17; multi-arch index digest checked on Docker Hub 2026-11-20, 1.47 GB compressed for amd64, below the 4 GB Trial/Free image limit). The image is used as published by linuxserver.io. This repository contains no copy of its source files.

| Component | Source | License | How it is used |
|---|---|---|---|
| linuxserver.io `webtop`, release `ubuntu-mate-c8975261-ls295` | https://github.com/linuxserver/docker-webtop/tree/ubuntu-mate (branch head `8d599774b1dc` checked 2026-11-20) | GPL-3.0 | Base image (`FROM`), unmodified except for the build-time edits listed below |
| linuxserver.io baseimage-selkies (`baseimage-selkies:ubunturesolute`) | https://github.com/linuxserver/docker-baseimage-selkies | GPL-3.0 | Layers of the base image: the s6 service definitions, `init-nginx`, `/defaults/default.conf` |
| Selkies | https://github.com/selkies-project/selkies | MPL-2.0 | Streaming server and web client, in the base image |
| s6-overlay 3.2.1.0 | https://github.com/just-containers/s6-overlay, https://skarnet.org/software/ | ISC | Process supervision. `railway-start` calls `s6-svscan`, `s6-rc-compile`, `s6-rc-init` and `s6-rc` from the image |
| catatonit | https://github.com/openSUSE/catatonit (distribution package in the base image) | GPL-2.0-or-later | Container init and subreaper (`ENTRYPOINT`) |
| Ubuntu 26.04 packages: MATE, Caja, MATE Terminal, Pluma, Atril, Engrampa, Xvfb, nginx, PulseAudio, Mesa and others; Chromium from the xtradeb/apps PPA | https://launchpad.net/ubuntu and https://launchpad.net/~xtradeb/+archive/ubuntu/apps | Each package's own license (see the package metadata in the image) | In the base image |

### GPL notes

- The GPL parts of the base image stay under their licenses. Their complete corresponding source is published by their authors at the repositories above, at the git revision named in the image label.
- **Modified files:** at build time, `services/desktop/patch-image.sh` edits `/defaults/default.conf` (GPL-3.0, from docker-baseimage-selkies: basic auth switched on, an Origin check, anti-framing headers and a `/healthz` location) and `/etc/nginx/nginx.conf` (2 worker processes, error log on stderr). The script and the inserted snippets (`nginx-origin-map.conf`, `nginx-server-hardening.conf`) are the complete record of these changes.  Anyone who distributes a built image of this template should keep them available with it.
- The files written for this template (`Dockerfile`, `railway-start.sh`, `pkg-restore.sh`, `patch-image.sh`, the two nginx snippets and the documentation) are offered under GPL-3.0-or-later.
- No source file of linuxserver.io, Selkies or s6-overlay was copied into this repository. `railway-start` re-implements, in its own code, the order of steps that s6-overlay's `preinit`, `stage0` and `rc.init` perform, and then calls the image's own s6 tools and service definitions.

## Upstream files checked (2026-11-20)

- `Dockerfile` and `root/` tree of the `ubuntu-mate` branch of linuxserver/docker-webtop.
- `Dockerfile` and `root/etc/s6-overlay/s6-rc.d/init-nginx/run` of the `ubunturesolute` branch of linuxserver/docker-baseimage-selkies (nginx site path and include line that `patch-image.sh` relies on).
- Docker Hub tag list of `linuxserver/webtop` for the release tag, digest and compressed size.

## Market templates reviewed

`linux-desktop-debian`, `linux-desktop-alpine` and `linux-desktop-lxqt` ("Linux Desktop | ... in the Cloud"): listings read for comparison only. Nothing copied. The template is derived from our own Debian 13 KDE Plasma, Ubuntu 26.04 XFCE and Kali Linux KDE desktop templates.

Product names belong to their owners. This is a community template, not affiliated with linuxserver.io, the Selkies project, the distribution's publishers or Railway. Ubuntu and Ubuntu MATE are trademarks of Canonical Ltd.
