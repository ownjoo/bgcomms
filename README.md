# BG Comms

[![License](https://img.shields.io/github/license/ownjoo/bgcomms)](LICENSE)

One-click battleground callouts for WoW Forever, TBC Anniversary and retail: **INC** with how
many, **CLEAR**, **HELP**, and flag carrier calls, named after where you are. Teammates running
BG Comms also get each call on a **team status board**.

## Using it

The bar appears when you enter a battleground (`/bgc` shows or hides it anywhere; outside a
battleground it's a practice bar that talks to your party or raid).

- **How many**: pick `?`, `1`–`4` or `5+`, then click a node. The count resets to `?` after each
  call, so an old number isn't repeated by accident.
- **Node buttons** (the current battleground's bases): click = **INC**, Shift+click = **CLEAR**,
  right-click = **HELP**.
- **Flag battlegrounds** (Warsong Gulch): Enemy FC and Our FC with West / Mid / East, **INC flag
  room** and **FC needs help**.
- **Keybindings** (Key Bindings > AddOns > BG Comms): INC / CLEAR / HELP *where you are*, and
  show/hide the bar. "Where you are" is the sub-zone you're standing in, shortened to the node's
  callout name (e.g. Stonehearth Graveyard → Stonehearth GY; in Warsong Gulch, "our base" or
  "their base" by your faction).
- **Team status board**: the latest call per node (and per flag carrier), who made it and how long
  ago. Calls from teammates running BG Comms arrive as addon messages. If a teammate made the same
  call a few seconds ago, yours isn't repeated in chat.
- Calls go to the battleground's instance chat (else raid, else party). Alone, they're only
  previewed in your chat frame.

Battlegrounds with their own spots: Arathi Basin, Warsong Gulch, Alterac Valley, Eye of the
Storm. Any other battleground gets generic Offense / Mid / Defense buttons, and calls still name
your sub-zone.

### Retail (Midnight)

Patch 12.0 stops addons from sending chat (and addon messages) to other players in restricted
situations such as PvP matches. When that's in effect, BG Comms puts the call in your chat box
and **you press Enter** to send it, which counts as you sending it. Addon messages can't be sent
then, so the team board only shows your own calls. `/bgc type` makes it always type rather than
send; `/bgc auto` (the default) sends where allowed.

### Commands

| Command | |
|---|---|
| `/bgc` | Show or hide the bar |
| `/bgc diag` | What this client allows here: battleground, sub-zone, channel, chat lockdown, addon restrictions |
| `/bgc type` / `/bgc auto` | Always type calls / send where allowed |
| `/bgc lock` / `/bgc unlock` | Lock the bar in place |
| `/bgc auto on` / `/bgc auto off` | Show the bar when entering a battleground |
| `/bgc minimap` | Hide or show the minimap button |

## Development

```
BattlegroundComms.toc   Interface 120105 (retail), 16001 (Forever), 20506 (TBC Anniversary)
Battlegrounds.lua       which battleground, its nodes, where you stand (sub-zone aliases)
Callouts.lua            call text, chat channel, sending (or typing it under chat lockdown)
Board.lua               team status board, duplicate-call check
UI.lua                  the bar
MinimapButton.lua       minimap button
Core.lua                events, addon messages, slash commands, keybinding functions
Bindings.xml            keybindings
```

Specs run on LuaJIT via lupa (no luarocks needed); `Load_spec.lua` loads the whole addon on a
retail, a Forever and a TBC client stub and plays through a battleground:

```bash
pip install lupa
python tools/run_specs.py
python tools/install.py          # copy into every local WoW client's AddOns folder
```

## Releases

Push a `v*` tag: CI runs the specs, the BigWigs packager builds the zip (contents per
`.pkgmeta`) and attaches it to a GitHub Release, and uploads it to CurseForge (project 1762970) when the
`CF_API_KEY` repo secret is set.
`assets/logo-400.png` is the project logo (from `assets/logo.svg`).

## License

MIT. See `LICENSE`.
