# Tick

A minimal macOS countdown timer with menu bar integration.

## Features

- Circular progress ring with preset timers (5 / 10 / 15 / 25 min)
- Custom time input + optional note
- Menu bar live countdown with quick-start popover
- Desktop alert with looping sound on completion
- Always-on-top mode, keyboard shortcuts, Dock badge

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| Space | Pause / Resume |
| Esc | Cancel |
| Return | Start (custom input) |

## Build

```bash
git clone https://github.com/qingchejun/Tick.git
cd Tick
./build.sh
open /Applications/Tick.app
```

Requires macOS 13+ and Xcode Command Line Tools.

## Install

Download `Tick.dmg` from [Releases](https://github.com/qingchejun/Tick/releases), open it, drag `Tick.app` to `/Applications`.

## License

MIT
