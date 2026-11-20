# Ubuntu MATE 26.04 Desktop in Your Browser: composer spec

Listing: **Ubuntu MATE 26.04 Desktop in Your Browser**, "Ubuntu MATE 26.04 desktop in a browser tab with a persistent home.". Category Other. Icon `https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/ubuntu-linux.svg`.

## Service: Desktop

- Source: repo `baranberkay96/ubuntu-mate-desktop-railway`, root directory `/services/desktop` (Dockerfile).
- Base: `lscr.io/linuxserver/webtop:ubuntu-mate-c8975261-ls295@sha256:aaa70851e0b69dad95ee84b381bc1a77e62806ca35df82121ac739427ac645f6` (built 2026-11-17, 1.47 GB compressed).
- Public domain, target port 3000, healthcheck `/healthz` (600 s), restart ON_FAILURE ×10, 1 replica.
- Volume `/config`.
- Variables: `PASSWORD` = `${{secret(32)}}`, `CUSTOM_USER` = `ubuntu`, `PORT` = `3000`, `TZ` = `Etc/UTC`, `TITLE` = `Ubuntu MATE 26.04 Desktop`, `APT_PACKAGES` = `empty`, `RAILWAY_DEPLOYMENT_DRAINING_SECONDS` = `15`.

## Improvements over market templates

- Login always on (basic auth enabled at build time), generated password; an empty, short or overlong password locks the login instead of opening the desktop or failing the deploy (STANDARD 8.29).
- Works under Railway's podman-init (the image's s6 `/init` refuses to run when it is not PID 1): `railway-start` brings up the s6 tree itself.
- Origin check against cross-site WebSocket/upload requests, `SELKIES_ALLOWED_ORIGINS` same-origin, anti-framing headers, `/healthz` that checks Selkies.
- Pinned release and digest; nginx workers capped at 2; Docker-in-Docker off; packages reinstalled after redeploys from `APT_PACKAGES`.

## Resource estimate

| Service | Idle RAM | Typical | CPU |
|---|---|---|---|
| Desktop | ~0.6 GB (estimate) | 1–2 GB with Chromium | 0.1 vCPU idle, 1–2 vCPU while the screen changes |

About $6–10/month idle at Railway prices plus the volume ($0.15/GB-month); more while the desktop is in use. Minimum plan: Trial (1 GB); Free (0.5 GB) is too small.

## Verification checklist

- `/healthz` 200 without login; `/` 401 without and 200 with the generated credential.
- The desktop session starts and streams; a file on `~/Desktop` survives a redeploy.
- `PASSWORD=short` → deploy succeeds, login locked, log explains.
- `APT_PACKAGES` with a small package is installed after start (`/var/log/railway-desktop/pkg-restore.log`).

## Open questions

- Trademark: Ubuntu and Ubuntu MATE are trademarks of Canonical Ltd.
