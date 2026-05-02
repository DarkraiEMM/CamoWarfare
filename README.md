# CamoWarfare

CamoWarfare adds modular camouflage hull blocks, armor attachments, slat armor, vehicle hanging plates, and organized creative-tab sections for Minecraft vehicle builders.

The mod focuses on military vehicle decoration and hull detailing. It includes camouflage families for woodland, mountain, desert, snow, night, naval, and urban builds, plus several attachment colors for extra armor detailing.

## Features

- Camouflage coating blocks in standard and large variants
- Add-on armor plates, slat armor, and vehicle hanging plates
- Grouped creative inventory sections for easier browsing
- Multiplayer-safe NeoForge mod for Minecraft 1.21.1
- Optional JEI integration to keep divider helper items out of ingredient listings
- Localizations for English, Simplified Chinese, German, French, and Russian

## Requirements

- Minecraft 1.21.1
- NeoForge 21.1.227 or newer in the 1.21.1 line
- Java 21

## Installation

1. Install NeoForge for Minecraft 1.21.1.
2. Download the CamoWarfare jar for your Minecraft version.
3. Place the jar in your `mods` folder.
4. Launch the game.

## Build From Source

```powershell
.\gradlew.bat build
```

The built jar is written to `build/libs/`.

## Changelog

### 1.3.4

- Added Copycats+ camouflage tile support using pre-sliced atlas tiles.
- Fixed six-face camouflage sampling so standard blocks and Copycats parts connect across all world directions.
- Fixed disappearing camouflage faces in taller builds by preserving full block positions in model data.
- Updated generated camouflage model resources for copycat atlas tile references.
- Kept ordinary camouflage blocks and Copycats camouflage parts on the same coordinate rule for mixed builds.

## Publishing Notes

For Modrinth and CurseForge, use:

- Name: CamoWarfare
- Mod loader: NeoForge
- Minecraft version: 1.21.1
- Version: 1.3.4
- Release type: Release
- Required dependency: NeoForge
- Optional dependency: JEI
- License: All Rights Reserved


## License

All Rights Reserved.
