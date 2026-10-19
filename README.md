# Bears Boon Viewer

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
![Size](https://img.shields.io/github/repo-size/N6REJ/Bears-boon-viewer)
[![Build Release](https://github.com/N6REJ/Bears-boon-viewer/actions/workflows/release.yml/badge.svg)](https://github.com/N6REJ/Bears-boon-viewer/actions/workflows/release.yml)
[![GitHub release](https://img.shields.io/github/release/N6REJ/Bears-boon-viewer.svg)](https://github.com/N6REJ/Bears-boon-viewer/releases/)

![Ready for 12.0.5](https://img.shields.io/badge/Ready_for-12.0.5-darkgreen)

Bears Boon Viewer is a World of Warcraft addon intended to make boon values easier
to see and use, especially for players with visual impairments. It is designed to
display the values from spell ID `1280098` in a dedicated on-screen frame that
can be dragged to a preferred location. The frame automatically resizes to fit
the spell values at the selected font size. It focuses on the boon percentages
for maximum health, primary stat, haste, critical strike, mastery, versatility,
movement speed, and damage reduction.
The display is shown only while you are in a Delve or Lair (the in-game activity
the API identifies as a Lair); it hides automatically when you leave.

## Display settings

- Choose from fonts registered with LibSharedMedia, including fonts supplied by
  ElvUI and other media addons.
- Adjust font size from 8 to 72 pixels; the default is 13 pixels.
- Choose a font color with the color picker; the default is white.
- The frame starts to the left of the minimap and below the buff bar when those
  frames are available. Drag it to reposition; its location is saved per profile.

Open the settings under **Options > AddOns > Bears Boon Viewer** or use `/boon`.

## Interface compatibility

The release package includes its Ace3 and LibSharedMedia libraries; it does not
require another addon to provide them. WoW addons can share Ace3 libraries
through LibStub, so a newer compatible copy loaded by another addon may be used
at runtime. ElvUI is optional and can style the frame if its Ace3 skin is enabled.

## Installation

Install the addon into your World of Warcraft `Interface/AddOns` directory, or
use a compatible addon manager. Once installed, enable **Bears Boon Viewer**
from the AddOns list at the character selection screen.

The development checkout can be tested directly through the AddOns folder junction
at `C:\Gaming\World of Warcraft\_retail_\Interface\AddOns\Bears_Boon_Viewer`.
Its ignored local `Libs` folders are development-only junctions; release builds
populate the libraries from the sources declared in `.pkgmeta`.
