#!/bin/sh
# Install MayaOS from the terminal — no browser, no download page.
#
#   curl -fsSL https://raw.githubusercontent.com/kingmeers/mayaos-releases/main/get.sh | sh
#
# Fetches the latest release for this machine's OS and architecture and
# installs it: the .deb on Debian-family Linux (one sudo prompt), the AppImage
# everywhere else on Linux, and the app bundle into /Applications on macOS.
# A copy that is already running is quit first and the new one opened after,
# so "run the command again" is also the upgrade path.
#
# A terminal download has one extra virtue on macOS: curl does not set the
# quarantine flag a browser sets, so the unsigned app opens normally instead
# of demanding the right-click -> Open dance.
#
#   sh get.sh --download-only   fetch the right file into the current
#                               directory and stop, for anyone who would
#                               rather do the installing themselves.

set -eu

REPO="kingmeers/mayaos-releases"

say() { printf '\033[1m%s\033[0m\n' "$*"; }
ok()  { printf '  \033[32m+\033[0m %s\n' "$*"; }
die() { printf '  \033[31mx\033[0m %s\n' "$*" >&2; exit 1; }

DOWNLOAD_ONLY=0
for a in "$@"; do
  case "$a" in
    --download-only) DOWNLOAD_ONLY=1 ;;
    -h|--help) sed -n '2,18p' "$0" 2>/dev/null || true; exit 0 ;;
    *) die "unknown option: $a" ;;
  esac
done

command -v curl >/dev/null 2>&1 || die "curl is required"

OS="$(uname -s)"
ARCH="$(uname -m)"

# Every asset URL of the latest release, straight off the GitHub API. No jq:
# the one machine this must not fail on is the fresh one that has nothing.
ASSETS="$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" |
  grep -o '"browser_download_url": *"[^"]*"' | cut -d'"' -f4)" || die "could not reach github.com/$REPO"
[ -n "$ASSETS" ] || die "the latest release of $REPO has no files"

# One asset for this machine. The x64 patterns must exclude the arm64 files —
# "MayaOS-0.2.3.AppImage" is a substring away from its -arm64 sibling.
pick() {
  found="$(printf '%s\n' "$ASSETS" | grep "$1" | { [ -n "${2:-}" ] && grep -v "$2" || cat; } | head -n 1)"
  [ -n "$found" ] || die "no $3 in the latest release — see https://github.com/$REPO/releases/latest"
  printf '%s' "$found"
}

case "$OS" in
  Linux)
    case "$ARCH" in
      x86_64|amd64)   DEB="$(pick '_amd64\.deb$' '' 'Linux amd64 build')"
                      APPIMG="$(pick '\.AppImage$' 'arm64' 'Linux AppImage')" ;;
      aarch64|arm64)  DEB="$(pick '_arm64\.deb$' '' 'Linux arm64 build')"
                      APPIMG="$(pick 'arm64\.AppImage$' '' 'Linux arm64 AppImage')" ;;
      *) die "unsupported architecture: $ARCH" ;;
    esac ;;
  Darwin)
    case "$ARCH" in
      arm64)          ZIP="$(pick 'arm64-mac\.zip$' '' 'macOS Apple Silicon build')" ;;
      x86_64)         ZIP="$(pick 'mac\.zip$' 'arm64' 'macOS Intel build')" ;;
      *) die "unsupported architecture: $ARCH" ;;
    esac ;;
  *) die "unsupported platform: $OS. macOS and Linux only." ;;
esac

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

fetch() {
  say "Downloading $(basename "$1")"
  curl -fL --progress-bar -o "$2" "$1"
}

if [ "$OS" = Linux ]; then
  if [ "$DOWNLOAD_ONLY" = 1 ]; then
    URL="$DEB"; command -v dpkg >/dev/null 2>&1 || URL="$APPIMG"
    fetch "$URL" "./$(basename "$URL")"
    ok "saved $(basename "$URL") — install it yourself when ready"
    exit 0
  fi

  # A copy that is already running would keep serving the old code after the
  # files change under it. Quit it; it is reopened at the end.
  pkill -x mayaos-gui 2>/dev/null && sleep 1 || true

  if command -v dpkg >/dev/null 2>&1; then
    FILE="$TMP/$(basename "$DEB")"
    fetch "$DEB" "$FILE"
    say "Installing (this is the one password prompt)"
    if [ "$(id -u)" = 0 ]; then
      apt-get install -y "$FILE" 2>/dev/null || dpkg -i "$FILE"
    elif command -v sudo >/dev/null 2>&1; then
      sudo apt-get install -y "$FILE" 2>/dev/null || sudo dpkg -i "$FILE"
    else
      die "need root to install a .deb — rerun as root, or use --download-only"
    fi
    ok "installed $(basename "$DEB")"
    BIN=mayaos-gui
  else
    # Not a dpkg system: the portable build, on this user's own PATH.
    mkdir -p "$HOME/.local/bin"
    fetch "$APPIMG" "$HOME/.local/bin/MayaOS.AppImage"
    chmod +x "$HOME/.local/bin/MayaOS.AppImage"
    ok "installed to ~/.local/bin/MayaOS.AppImage"
    BIN="$HOME/.local/bin/MayaOS.AppImage"
  fi

  # Into the graphical session if there is one; a headless box gets told.
  if [ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]; then
    say "Opening MayaOS"
    nohup "$BIN" >/dev/null 2>&1 &
  else
    ok "no graphical session here — open MayaOS from the desktop when you have one"
  fi
fi

if [ "$OS" = Darwin ]; then
  if [ "$DOWNLOAD_ONLY" = 1 ]; then
    fetch "$ZIP" "./$(basename "$ZIP")"
    ok "saved $(basename "$ZIP") — unzip and drag MayaOS.app to Applications"
    exit 0
  fi

  FILE="$TMP/$(basename "$ZIP")"
  fetch "$ZIP" "$FILE"
  say "Installing to /Applications"
  # ditto preserves the bundle exactly the way Archive Utility would.
  ditto -xk "$FILE" "$TMP/unpacked"
  APP="$(find "$TMP/unpacked" -maxdepth 2 -name 'MayaOS.app' | head -n 1)"
  [ -n "$APP" ] || die "the zip did not contain MayaOS.app"
  osascript -e 'tell application "MayaOS" to quit' >/dev/null 2>&1 || true
  rm -rf /Applications/MayaOS.app
  ditto "$APP" /Applications/MayaOS.app
  # curl does not quarantine, but clear the flag in case this zip ever came
  # through something that does.
  xattr -dr com.apple.quarantine /Applications/MayaOS.app 2>/dev/null || true
  ok "installed /Applications/MayaOS.app"
  say "Opening MayaOS"
  open /Applications/MayaOS.app
fi

say "Done. MayaOS walks you through the rest — about two minutes."
