# PvP Tally

Keeps a tally of every **world PvP** kill and death in **World of Warcraft: Forever**, with one row per enemy player.

## Features

- **One row per enemy:** class icon, race (with faction badge for Skyborne), level, guild, **Kills**, **Deaths** and date of first encounter.
- **Fight details:** click a row to see each encounter: result, local date and time, zone and subzone, and both levels.
- **Group kills:** a killing blow by your party or raid counts if you took part in the fight.
- **Skull on nameplates:** players already in your list get a skull next to their name on their nameplate, friend or foe, in the open world and in battlegrounds. Its size (small, medium or large) and whether it shows are chosen in the options.
- **Skull on the portrait:** in case another addon replaces the nameplates, the portrait of your target and focus is covered with a skull when they are in your list. Can be turned off in the options.
- **Sort, search and manage:** sort by any column, search by name, guild or zone, right-click to delete a player, resize the window.
- **Blizzard-style UI**, minimap button and its own panel in Options > AddOns.
- **Chat notifications:** choose in the options whether to see a message for each kill, each death, both or neither.
- **Import from Spy:** if Spy is loaded, you can import what it recorded, whatever your client language.
- **No dependencies:** no other addon or library required.
- **In your language:** English, German, Spanish (EU and Latin America), French, Italian, Portuguese, Russian, Korean and Chinese (Simplified and Traditional). Dates follow your language's order, and class names use the feminine form for female players.

## Commands

| Command | Action |
| --- | --- |
| `/tally` | Open or close the window |
| `/tally settings` | Open the options |
| `/tally import` | Import data from Spy |
| `/tally notify` | Turn all chat notifications on or off |
| `/tally minimap` | Show or hide the minimap button |
| `/tally reset` | Delete all data for this character |
| `/tally test` | Add sample players to preview the window (`/tally test clear` removes them) |
| `/tally skull First Last` | Add that player (or your target, without a name) as a test player, to see the skull without fighting them (`/tally test clear` removes them) |
| `/tally debug` | Show why the last kill or death was or wasn't counted |

## Notes

- Only open-world PvP is recorded: no battlegrounds, arenas or instances. The nameplate skull does show in battlegrounds, since it records nothing.
- The skull only appears on the nameplates the game shows: turn on enemy and friendly nameplates in the game options.
- Kills are detected through `PARTY_KILL` and deaths through `PLAYER_DEAD` and the death recap, since the combat log is closed to addons.
- Each group member needs PvP Tally installed to track their own data.
