# MayaOS — downloads

Drive every tab in every window of every Chrome profile you have open, from
anywhere on **your own** Tailscale network.

**[Download the latest release →](../../releases/latest)**

| Platform | File |
|---|---|
| macOS (Apple Silicon) | `MayaOS-*-arm64.dmg` |
| macOS (Intel) | `MayaOS-*.dmg` |
| Linux (portable) | `MayaOS-*.AppImage` — `chmod +x` and run |
| Linux (Debian/Ubuntu/Mint) | `mayaos-gui_*.deb` |

## What happens when you open it

MayaOS walks you through the setup and asks for your password twice — once so
Chrome will load the bridge, once to install Tailscale. Then you **sign in to
your own Tailscale account**.

That last part is the important one: your machine joins *your* network, not
anyone else's. Nobody can reach it — not other people who installed this, and
not whoever sent you the link.

At the end you have two things, and they are all that anything needs to drive
this machine:

- an **endpoint URL**, like `https://your-pc.your-tailnet.ts.net`
- an **API key** — either this machine's own key, which reaches every Chrome
  profile, or one you create that can only ever see the profiles you picked

## What it can reach

Everything in the browser you are already signed into. Read a page, list every
tab across every profile, click, type, screenshot, run JavaScript. That is a lot
of power over live logged-in sessions, which is why it is off until you turn it
on, and why a key can be confined to particular profiles.

Nothing is reachable until you switch remote access on. Switch it off and the
machine is local-only again.

## The builds are unsigned

There is no Apple Developer certificate behind this yet, so macOS will refuse to
open it on the first run. Right-click the app and choose **Open**, then confirm.
You only have to do that once.

## Bugs

The source is private; open an issue here and it will get read.
