# PvP Tally

Keeps a tally of every **world PvP** kill and death in **World of Warcraft: Forever**, with one row per enemy player.

## Features

- **One row per enemy:** class icon, race (with faction badge for Skyborne), level, guild, **Kills**, **Deaths** and date of first encounter.
- **Fight details:** click a row to see each encounter: result, local date and time, zone and subzone, and both levels.
- **Group kills:** a killing blow by your party or raid counts if you took part in the fight.
- **Sort, search and manage:** sort by any column, search by name, guild or zone, right-click to delete a player, resize the window.
- **Blizzard-style UI**, minimap button and its own panel in Options > AddOns.
- **Chat notifications:** choose in the options whether to see a message for each kill, each death, both or neither.
- **Import from Spy:** if Spy is loaded, you can import what it recorded.
- **No dependencies:** no other addon or library required.
- **Localized:** English, German, Spanish (EU and Latin America), French, Italian, Brazilian Portuguese, Russian, Korean and Chinese (Simplified and Traditional). Dates follow each language's order.

## Commands

| Command | Action |
| --- | --- |
| `/tally` | Open or close the window |
| `/tally settings` | Open the options |
| `/tally import` | Import data from Spy |
| `/tally notify` | Turn all chat notifications on or off |
| `/tally minimap` | Show or hide the minimap button |
| `/tally reset` | Delete all data for this character |

## Notes

- Only open-world PvP is recorded: no battlegrounds, arenas or instances.
- Kills are detected through `PARTY_KILL` and deaths through `PLAYER_DEAD` and the death recap, since the combat log is closed to addons.
- Each group member needs PvP Tally installed to track their own data.
