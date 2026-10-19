# Bears Boon Viewer

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
![Size](https://img.shields.io/github/repo-size/N6REJ/Bears-boon-viewer)
[![Build Release](https://github.com/N6REJ/Bears-boon-viewer/actions/workflows/release.yml/badge.svg)](https://github.com/N6REJ/Bears-boon-viewer/actions/workflows/release.yml)
[![GitHub release](https://img.shields.io/github/release/N6REJ/Bears-boon-viewer.svg)](https://github.com/N6REJ/Bears-boon-viewer/releases/)

![Ready for 12.0.5](https://img.shields.io/badge/Ready_for-12.0.5-darkgreen)

Bears Boon Viewer is a World of Warcraft addon intended to make boon values easier
to see and use, especially for players with visual impairments. It is designed to
display the values from spell ID `1280098` in a dedicated on-screen frame that
can be dragged to a preferred location. It reads the values from the boon aura's
tooltip and automatically sizes and lays out the frame to fit the current text
and font settings. It displays the boon percentages for maximum health, primary
stat, haste, critical strike, mastery, versatility, movement speed, incoming
damage, and damage reduction.
The display is shown only while you are in a Delve or Lair (the in-game activity
the API identifies as a Lair) and the boon aura has readable values. It hides
when you leave or when those values are unavailable, and appears when values
become available. Values refresh when the player aura, talents, specialization,
equipment, or spell data changes.

## Display settings

- Choose from fonts currently registered with LibSharedMedia. The font list is
  populated dynamically when the options panel requests its choices, so fonts
  registered by media addons can be selected without a fixed list in this addon.
- The default font is 2002 Bold at 12 pixels; adjust the size from 8 to 48 pixels
  with the size slider or the Smaller and Larger buttons.
- Choose a font color with the color picker; the default is white.
- Font, size, and color changes take effect immediately. The display frame
  recalculates its dimensions and text layout after each change.
- The frame starts to the left of the minimap and below the buff bar when those
  frames are available. Drag it to reposition; its location is saved per profile.

Open the settings under **Options > AddOns > Bears Boon Viewer** or use `/boon`.
The viewer has an X in its upper-right corner to hide it. Click the Bears Boon
Viewer minimap button to refresh and show the display again. The addon-list icon
and minimap button use the Boons spell icon; the minimap button has a gold-tinted
tracking ring.

## Interface compatibility

The release package includes standard Ace3 and LibSharedMedia libraries; it does
not require another addon to provide them or use ElvUI library forks. WoW addons
can share Ace3 libraries through LibStub, so a newer compatible standard copy
loaded by another addon may be used at runtime.

## Installation

Install the addon into your World of Warcraft `Interface/AddOns` directory, or
use a compatible addon manager. Once installed, enable **Bears Boon Viewer**
from the AddOns list at the character selection screen.
