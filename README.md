# Bears Boon Viewer

[![WoW Version](https://img.shields.io/badge/WoW-12.1.5-darkgreen)](https://worldofwarcraft.blizzard.com/) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT) [![GitHub](https://img.shields.io/badge/GitHub-Source-blue?logo=github)](https://github.com/N6REJ/Bears-boon-viewer)

Bears Boon Viewer makes the active boon values easier to see, with customizable text designed to support readability and accessibility. It also tracks boons by marking the Mislaid Curiosity chests that hold them on your minimap and world map while you're in a Delve or Labyrinth.

The movable on-screen viewer reads boon percentages from the aura tooltip and automatically fits its size to the displayed values. It shows while you’re in a Delve or Labyrinth when readable boon values are available, refreshes as values change, and hides when you leave or the values are unavailable.

## Features

*   Displays boon values for maximum health, primary stat, haste, critical strike, mastery, versatility, movement speed, incoming damage, and damage reduction.
*   Automatically opens when boon values become available, including after gaining a boon while the viewer is closed.
*   Choose from fonts registered with LibSharedMedia, adjust font size from 8–48 px, and set the text color. Changes apply immediately.
*   Resizes and positions the display automatically to fit its text; drag it to save a preferred position.
*   Close the viewer with the X, then reopen it using the minimap button.
*   The minimap button and addon-list entry use the Boons spell icon.
*   Inside Delves and Labyrinths only, maps **Mislaid Curiosity** treasure chests with chest pins (color chosen with a color picker) for identified curiosities, on both the minimap and the world map.

## Mislaid Curiosity pins

While scanning is active the addon watches for Mislaid Curiosity vignettes, records each location across the related maps of the current Delve or Labyrinth, and shows chest pins:

*   **Minimap pins** appear for locations near you, projected onto the minimap and clamped to its edge when out of view. Pins fade when pushed to the edge.
*   **World map pins** appear for chests the addon has been detected in this Delve or Labyrinth. The game only reports chests within its vignette range, so chests in areas you haven't approached yet or are in another chamber won't show.
*   Chest pins mark vignettes the game identifies as Mislaid Curiosities. Their color is chosen with the **Pin color** option (red, green, blue, or yellow).
*   A pin is removed when you pick up its boon. The pin closest to you is dropped when your boon values change, and that chest stays hidden for the rest of the delve.

Scanning only runs inside a Delve or Labyrinth. Three options control it:

*   **Show Mislaid Curiosity treasure chest pins** — turns minimap/world map pins on or off.
*   **Pin color** — color of the chest pins (color picker).
*   **Scan interval (seconds)** — how often to re-scan for Mislaid Curiosities (0.5 to 10 seconds, default 2.0).

Hover a pin for a tooltip reading “Potential Mislaid Curiosity”.

**Compatibility note:** SilverDragon’s minimap range extender can surface extra
“Mystery” (brown circle) vignettes beyond normal range. These may appear over
or alongside our pins; disable that range extender while delving if you want
only the game-identified Mislaid Curiosity pins.

## Usage

Type `/boon` to open the options. Use the minimap button to show the viewer again when boon values are available.

Commands:

*   `/boon` — opens the options panel. Unrecognized `/boon` arguments also open the panel.
*   `/boon debug` — turns vignette logging on or off. Turning it on opens the Bears Boon Viewer Debug window.
*   `/boon exclude x y` — adds an exclusion at the given map percent, for example `/boon exclude 26.80, 33.20`. Commas, brackets, and extra spaces are fine. `/boon exclusion x y` works the same way.

The options panel also includes a **Live Preview** button that toggles a sample display using localized placeholder values.

### Excluded hidden chests

Inside the Labyrinth, some hidden vignettes are false matches at the fire hexmask rooms. The addon ignores hidden chests within 0.5 map-percent of any saved exclusion point on the Labyrinth map. Chests the game gives full info for are never excluded.

The exclusion list is shown at the bottom of `/boon`, as `[x, y]` pairs in map percent. If no saved list exists, it starts with a built-in default list of known false-match locations. The **Use exclusions** checkbox under the pin option turns exclusion matching on or off. You can change the list with:

*   **Exclude Current Location** — adds your current map position.
*   **Include Current Location** — removes exclusions within 2 map-percent of your position.
*   **Clear Exclusions** — empties the list.
*   `/boon exclude x y` — adds a point by coordinates, for example `/boon exclude 26.80, 33.20`. The alias `/boon exclusion x y` also works.

Each change rescans right away when you're in a delve, and reports how many chests were excluded.

### Vignette debug window

`/boon debug` toggles vignette logging. While it's on, the **Bears Boon Viewer Debug** window shows each new vignette once, with its GUID, whether the game returned info, its `vignetteID`, whether it was classified as a Mislaid Curiosity, its name, and for Mislaid Curiosities its map position and your position. The window keeps the last 500 lines and has a **Clear** button. Use it to find exact coordinates for exclusions.

## Libraries

The release includes standard Ace3 and LibSharedMedia libraries. ElvUI is supported as an optional dependency: when it's installed, the addon uses the fonts ElvUI registers through LibSharedMedia. ElvUI is not required, and the addon does not use ElvUI library forks.

## Installation

Install the addon into your World of Warcraft `Interface/AddOns` directory, or use a compatible addon manager. Once installed, enable **Bears Boon Viewer** from the AddOns list at the character selection screen.

## Demo

[Demo](https://www.youtube.com/watch?v=K592afad2jY)