# Bears Boon Viewer

[![WoW Version](https://img.shields.io/badge/WoW-12.1.5-darkgreen)](https://worldofwarcraft.blizzard.com/) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT) [![GitHub](https://img.shields.io/badge/GitHub-Source-blue?logo=github)](https://github.com/N6REJ/Bears-boon-viewer)

Bears Boon Viewer makes the active boon values easier to see, with customizable text designed to support readability and accessibility.

The movable on-screen viewer reads boon percentages from the aura tooltip and automatically fits its size to the displayed values. It shows while you’re in a Delve or Lair when readable boon values are available, refreshes as values change, and hides when you leave or the values are unavailable.

## Features

*   Displays boon values for maximum health, primary stat, haste, critical strike, mastery, versatility, movement speed, incoming damage, and damage reduction.
*   Automatically opens when boon values become available, including after gaining a boon while the viewer is closed.
*   Choose from fonts registered with LibSharedMedia, adjust font size from 8–48 px, and set the text color. Changes apply immediately.
*   Resize and position the display automatically to fit its text; drag it to save a preferred position.
*   Close the viewer with the X, then reopen it using the minimap button.
*   The minimap button and addon-list entry use the Boons spell icon.
*   Inside Delves and Labyrinths only, maps **Mislaid Curiosity** treasure chests with red chest pins for identified curiosities and orange chest pins for mystery (brown circle) vignettes, on both the minimap and the world map.

## Mislaid Curiosity pins

While scanning is active the addon watches for Mislaid Curiosity vignettes, records each location across the related maps of the current Delve or Labyrinth, and shows chest pins:

*   **Minimap pins** appear for locations near you, projected onto the minimap and clamped to its edge when out of view. Pins fade when pushed to the edge.
*   **World map pins** appear for every mapped location on the world map, so you can plan a route before walking to them.
*   Identified curiosities use **red** pins; mystery vignettes that show as brown circles with no tooltip use **orange** pins.
*   Pins are removed automatically once you get close enough to loot the chest.

Scanning only runs inside a Delve or Labyrinth. Two options control it:

*   **Show Mislaid Curiosity treasure chest pins** — turns minimap/world map pins on or off.
*   **Scan interval (seconds)** — how often to re-scan for Mislaid Curiosities (0.5 to 10 seconds, default 2.0).

Hover a pin for a tooltip reading “Potential Mislaid Curiosity”.

## Usage

Type `/boon` to open the options. Use the minimap button to show the viewer again when boon values are available.

The options panel also includes a **Live Preview** button that toggles a sample display using localized placeholder values.

## Libraries

The release includes standard Ace3 and LibSharedMedia libraries. ElvUI is not required, and the addon does not use ElvUI library forks.

## Installation

Install the addon into your World of Warcraft `Interface/AddOns` directory, or use a compatible addon manager. Once installed, enable **Bears Boon Viewer** from the AddOns list at the character selection screen.

## Demo

[Demo](https://www.youtube.com/watch?v=K592afad2jY)