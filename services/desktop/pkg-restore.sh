#!/usr/bin/env bash
# railway-pkg-restore: reinstalls distribution packages after a redeploy.
#
# Only /config (the home directory) is on the Railway volume. Packages
# installed with apt, apk, dnf or pacman live in the image and are gone after
# every redeploy. This script, started in the background by railway-start once
# the desktop is up, reinstalls the packages listed in:
#   - the APT_PACKAGES (Debian, Ubuntu, Kali), APK_PACKAGES (Alpine),
#     DNF_PACKAGES (Fedora) or PACMAN_PACKAGES (Arch) variable, space or
#     comma separated, and
#   - ~/.config/railway-desktop/packages (one or more per line, '#' comments).
# The home-directory list is ignored when HARDEN_DESKTOP or DISABLE_SUDO is
# on, because there the desktop user must not be able to install packages.
#
# Arch is a rolling release and the image is pinned, so installing from the
# live mirrors would be a partial upgrade (newer libraries than the rest of
# the system). On Arch the packages come from the Arch Linux Archive snapshot
# of the day the image was built (/etc/pacman-railway-snapshot.conf, written
# at build time), which matches the installed system. Without that file the
# live mirrors are used with a full upgrade (pacman -Syu).
set -Eeuo pipefail

readonly LIST_FILE="/config/.config/railway-desktop/packages"
readonly LOG_DIR="/var/log/railway-desktop"
readonly LOG_FILE="${LOG_DIR}/pkg-restore.log"
readonly DPKG_LOCK_TIMEOUT=600
readonly NAME_PATTERN='^[a-z0-9][a-z0-9+._-]+(=[A-Za-z0-9.+:~_-]+)?$'
readonly PACMAN_SNAPSHOT_CONF="/etc/pacman-railway-snapshot.conf"

log() { printf '[railway-pkg-restore] %s\n' "$*" >&2; }

is_true() {
  case "$(printf '%s' "${1:-}" | tr '[:upper:]' '[:lower:]')" in
    1 | true | yes | on) return 0 ;;
    *) return 1 ;;
  esac
}

# Prints "apt", "apk", "dnf" or "pacman", whichever package manager the image has.
package_manager() {
  if command -v apt-get > /dev/null 2>&1; then
    printf 'apt\n'
  elif command -v apk > /dev/null 2>&1; then
    printf 'apk\n'
  elif command -v dnf > /dev/null 2>&1; then
    printf 'dnf\n'
  elif command -v pacman > /dev/null 2>&1; then
    printf 'pacman\n'
  else
    return 1
  fi
}

# Name of the package variable for a package manager.
package_variable() {
  case "$1" in
    apt) printf 'APT_PACKAGES\n' ;;
    apk) printf 'APK_PACKAGES\n' ;;
    dnf) printf 'DNF_PACKAGES\n' ;;
    pacman) printf 'PACMAN_PACKAGES\n' ;;
  esac
}

# Prints the requested packages, one per line, without duplicates.
# $1 = the value of the package variable.
collect_packages() {
  local requested="$1"
  local -a words=() parts=()
  local -A seen=()
  local line word

  if [[ -n "$requested" ]]; then
    read -r -a words <<< "${requested//,/ }"
  fi
  if is_true "${HARDEN_DESKTOP:-}" || is_true "${DISABLE_SUDO:-}"; then
    if [[ -e "$LIST_FILE" ]]; then
      log "Desktop is hardened: ignoring ${LIST_FILE}."
    fi
  elif [[ -f "$LIST_FILE" && ! -L "$LIST_FILE" ]]; then
    while IFS= read -r line || [[ -n "$line" ]]; do
      line="${line%%#*}"
      read -r -a parts <<< "$line"
      words+=("${parts[@]}")
    done < "$LIST_FILE"
  fi

  for word in "${words[@]}"; do
    if [[ ! "$word" =~ $NAME_PATTERN ]]; then
      log "Skipping invalid package name: '${word:0:64}'"
      continue
    fi
    if [[ -z "${seen[$word]:-}" ]]; then
      seen[$word]=1
      printf '%s\n' "$word"
    fi
  done
}

install_packages() {
  local manager="$1"
  shift
  case "$manager" in
    apt)
      DEBIAN_FRONTEND=noninteractive apt-get -o DPkg::Lock::Timeout="$DPKG_LOCK_TIMEOUT" update &&
        DEBIAN_FRONTEND=noninteractive apt-get -o DPkg::Lock::Timeout="$DPKG_LOCK_TIMEOUT" \
          install -y --no-install-recommends "$@"
      ;;
    apk) apk add --no-cache "$@" ;;
    dnf) dnf install -y --setopt=install_weak_deps=False "$@" ;;
    pacman)
      # pacman has no version pins on the command line: drop "=version".
      local -a names=("${@%%=*}")
      if [[ -s "$PACMAN_SNAPSHOT_CONF" ]]; then
        pacman --config "$PACMAN_SNAPSHOT_CONF" -Sy --needed --noconfirm "${names[@]}"
      else
        pacman -Syu --needed --noconfirm "${names[@]}"
      fi
      ;;
  esac
}

main() {
  local manager requested variable
  local -a pkgs=()

  manager="$(package_manager)" || { log "No apt-get, apk, dnf or pacman in this image."; exit 0; }
  variable="$(package_variable "$manager")"
  requested="${!variable:-}"
  mapfile -t pkgs < <(collect_packages "$requested")
  (( ${#pkgs[@]} > 0 )) || exit 0

  install -d -m 0755 "$LOG_DIR"
  log "Reinstalling ${#pkgs[@]} package(s) with ${manager}: ${pkgs[*]} (log: ${LOG_FILE})"
  if install_packages "$manager" "${pkgs[@]}" > "$LOG_FILE" 2>&1; then
    log "Packages restored."
  else
    log "WARNING: package restore failed. See ${LOG_FILE} (tail below)."
    tail -n 15 "$LOG_FILE" >&2 || true
  fi
}

main "$@"
