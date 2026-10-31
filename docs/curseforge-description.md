# BG Comms

**One-click battleground callouts.** Pick how many, click the base, and your team knows: INC,
CLEAR, HELP and flag carrier calls, named after exactly where you are. No typing mid-fight, no
"inc lm" that half the raid misreads.

Works on **WoW Forever**, **TBC Anniversary** and **retail**. No other addons required.

## What it does

- **The callout bar** appears when you enter a battleground, laid out for that battleground:
  - **How many:** pick `?`, `1` to `4` or `5+` first. The count resets after each call, so an old
    number never goes out by accident.
  - **One button per base:** click for **INC**, Shift+click for **CLEAR**, right-click for **HELP**.
  - **Flag calls in Warsong Gulch:** Enemy FC and Our FC going West, Mid or East, **INC flag room**
    and **FC needs help**.
- **Calls name where you are.** BG Comms reads your sub-zone and turns it into the name players
  actually use: *Stonehearth Graveyard* becomes *Stonehearth GY*, and in Warsong Gulch you get
  *our base* or *their base* depending on your faction.
- **Raid markers that read at a glance:** a square for an unknown count, stars for 1 or 2, circles
  for 3 or 4, a cross for 5+, a green triangle for CLEAR.
- **Keybindings:** INC, CLEAR and HELP *where you stand*, plus show or hide the bar. Call a base
  without taking your hands off your rotation.
- **On the map:** the board shows on the world map and the small battlefield map (Shift+M), with
  a pin on each base marked like the call. Click a pin to call that base.
- **Pings (retail and Forever):** calls about your spot also drop a ping on you, and flag carrier
  calls ping your target, so the team sees it in the world as well as in chat.
- **Team status board:** teammates running BG Comms share their calls addon-to-addon. The board
  shows the latest call for every base and both flag carriers, who made it and how long ago. If
  someone called the same thing seconds ago, BG Comms doesn't spam chat with it again.
- **Talks to the right people:** battleground chat in a battleground, raid or party elsewhere.
  Out of a battleground it's a practice bar that only previews calls to you.

## Battlegrounds

Arathi Basin, Warsong Gulch, Alterac Valley and Eye of the Storm have their own buttons. Any
other battleground gets Offense, Mid and Defense, and calls still name your sub-zone.

## On retail (Midnight)

Patch 12.0 stops addons from sending chat for you in some situations, PvP matches included.
When that's in effect, BG Comms puts the call in your chat box and **you press Enter**, so you're
the one sending it. Everything else still works. Teammates' boards only fill in where addons are
allowed to talk to each other.

## Commands

- `/bgc` shows or hides the bar.
- `/bgc practice wsg` (or `ab`, `av`, `eots`) shows that battleground's bar anywhere, to try it
  with a friend before you queue.
- `/bgc diag` shows what your client allows right now: battleground, sub-zone, channel, and any
  chat restrictions in effect.
- `/bgc type` always types calls for you to send; `/bgc auto` (the default) sends where allowed.
- `/bgc lock` / `/bgc unlock` locks the bar in place.
- `/bgc auto on` / `/bgc auto off` shows the bar automatically in battlegrounds.
- `/bgc minimap` hides or shows the minimap button (Shift+drag to move it).

## Tips

- **Bind the "where you stand" keys** (Key Bindings > AddOns > BG Comms). One key for INC at your
  base is the fastest call there is.
- **Get your premade on it.** The more of your team running BG Comms, the more the status board
  shows.
- **Something not sending?** Run `/bgc diag` in the battleground; it says whether the game is
  blocking addon chat there.

## Support

BG Comms is free, with no paywalled features, ever. If it won you a battleground, a coffee keeps
the updates coming: [Ko-fi](https://ko-fi.com/speedimus) · [Buy Me a Coffee](https://buymeacoffee.com/speedimus)
