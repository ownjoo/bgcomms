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
- **INC here / CLEAR here / HELP here** buttons, and keybindings for them (Key Bindings > AddOns >
  BG Comms), call *where you are*. "Where you are" is the sub-zone you're standing in, shortened to the node's
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

### On the map

The board also shows on Blizzard's own maps, the world map and the small battlefield map
(Shift+M): a pin on each base, marked with the call's raid icon and "INC 3 12s". Hover for who
called it; click a pin to call that base (click INC, Shift CLEAR, right-click HELP), the same as
the bar. Bases nobody has called show as faint pins you can click.

Pins sit on the game's own base markers (Arathi Basin, Eye of the Storm, Alterac Valley). Warsong
Gulch has none, so its spots are marked by standing on them: `/bgc practice wsg` (or a real match),
then `/bgc mark our base`, `/bgc mark mid`, `/bgc mark their base`. Marks are saved by sub-zone,
so they're right for either faction; `/bgc marks` lists them.

### Pings (retail and Forever)

Where the game has the ping system, BG Comms pings alongside the call:

- **INC / CLEAR / HELP here** put a Warning, Not a threat or Assist ping on you, so the team sees
  exactly where it's happening.
- **Enemy FC** buttons put an Attack ping on your target if it's an enemy; **Our FC** and **FC
  needs help** put an Assist ping on your target if it's friendly. No suitable target, no ping.

Addons can't ping on their own, so these buttons run the game's `/ping` macro from your click or
keypress. Pings are your own action, so they still work on retail where addons may not send chat.
`/bgc pings off` turns them off. TBC Anniversary has no pings; the calls work as before.

### Retail (Midnight)

Patch 12.0 stops addons from sending chat (and addon messages) to other players in restricted
situations such as PvP matches. When that's in effect, BG Comms puts the call in your chat box
and **you press Enter** to send it, which counts as you sending it. Addon messages can't be sent
then, so the team board only shows your own calls. `/bgc type` makes it always type rather than
send; `/bgc auto` (the default) sends where allowed.

### Trying it out of a battleground

`/bgc practice wsg` (or `ab`, `av`, `eots`) lays out that battleground's bar anywhere; plain
`/bgc practice` (or `/bgc`) gives generic spots. Alone, calls are only previewed in your chat
frame. In a party they go to party chat, and a friend running BG Comms sees them on their board.
Pings work too: target your friend for Our FC, a hostile mob for Enemy FC. On retail,
`/console addonChatRestrictionsForced 1` forces the chat lockdown so you can see calls typed into
your chat box (`0` turns it off).

### Commands

| Command | |
|---|---|
| `/bgc` | Show or hide the bar |
| `/bgc practice [wsg\|ab\|av\|eots]` | A battleground's bar anywhere, to try it out (generic spots without a name) |
| `/bgc mark <node>` / `/bgc marks` | Place a node's map pin where you stand / list marked spots |
| `/bgc diag` | What this client allows here: battleground, sub-zone, channel, chat lockdown, addon restrictions |
| `/bgc type` / `/bgc auto` | Always type calls / send where allowed |
| `/bgc lock` / `/bgc unlock` | Lock the bar in place |
| `/bgc auto on` / `/bgc auto off` | Show the bar when entering a battleground |
| `/bgc pings on` / `/bgc pings off` | Ping alongside calls (retail, Forever) |
| `/bgc minimap` | Hide or show the minimap button |

## Development

```
BattlegroundComms.toc   Interface 120105 (retail), 16001 (Forever), 20506 (TBC Anniversary)
Battlegrounds.lua       which battleground, its nodes, where you stand (sub-zone aliases)
Callouts.lua            call text, chat channel, sending (or typing it under chat lockdown)
Board.lua               team status board, duplicate-call check
Pings.lua               /ping macros for calls (retail, Forever)
MapNodes.lua            where nodes sit on the map (game markers, /bgc mark)
MapPins.lua, Pins.xml   board pins on the world and battlefield maps
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

## Support

BG Comms is free, with no paywalled features. If it won you a battleground, a coffee keeps the
updates coming: [Ko-fi](https://ko-fi.com/speedimus) · [Buy Me a Coffee](https://buymeacoffee.com/speedimus)

## License

MIT. See `LICENSE`.
