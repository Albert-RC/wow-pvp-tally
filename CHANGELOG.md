# Changelog

## v1.4.0 (2026-11-13)

- Players already in your list now have a skull left of their name on their nameplate, friend or foe, in the open world and in battlegrounds. Turn on enemy and friendly nameplates in the game options to see it.
- In case another addon replaces the nameplates, the portrait of your target and focus is covered with a skull too when they are in your list.
- New Skull section in Options > AddOns > PvP Tally: turn the nameplate skull on or off, pick its size (small, medium or large), and turn the portrait skull on or off.
- New `/tally skull First Last` (or `/tally skull` with a player targeted): adds that player as a test player, to see the skull without fighting them. `/tally test clear` removes them.

## v1.3.0 (2026-11-13)

- Translated into every client language: German, French, Italian, Brazilian Portuguese, Russian, Korean and Chinese (Simplified and Traditional), besides English and Spanish. Each language has its own file in `Locales/`.
- Dates follow the order of the client language (month first in US English, day first in most of Europe, year first in Korean and Chinese).
- Class names in tooltips use the feminine form for female players where the language has one.
- Races imported from Spy are now recognized in their feminine form in every language (Zwergin, Naine, Anã, Гномка...), not only Spanish, so their icons show.

## v1.2.0 (2026-11-13)

- New Chat section in Options > AddOns > PvP Tally: choose whether to see a chat message for each kill (yours or your group's) and for each death. Fights are still recorded either way. Your previous setting is kept.
- `/tally notify` still turns all chat messages on or off at once.
- The "First fight" column is wider, so the whole date and time fit. The window is now at least 732 pixels wide.

## v1.1.0 (2026-11-12)

- Kills by your group now count when you took part in the fight (target, focus, targeted by the enemy, or in combat with them in sight). They are marked "group" in the fight details.
- No dependencies: Spy is only read, when loaded, to offer a one-time import.

## v1.0.0 (2026-11-12)

First release.

- One row per enemy player with kills, deaths and the details of every world PvP fight (zone, both levels, local time).
- English and Spanish (esES, esMX) texts.
