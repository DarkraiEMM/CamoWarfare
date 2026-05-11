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

### 1.4.1

English:

- Added camouflage decals with per-face placement, up to three decals per face, Shift-right-click removal, and a dedicated creative-tab section.
- Added black and white Minecraft-font number decals from 0-9.
- Added red, white, and black star decals plus chevrons, arrows, warning stripes, warning triangles, identification bars, and low-visibility bars.
- Added experimental 2x2 red and white star decals that split one large decal across four connected camouflage blocks.
- Added the Suspicious Roast Chicken utility block with a hidden 27-slot container.
- Improved connected camouflage block refresh so nearby blocks update their connection state automatically after placement, neighbor changes, and decal edits.
- Kept the abandoned shell-impact decal prototype out of the release build.

中文：

- 新增水贴系统，支持按方块面放置、每面最多 3 张、Shift 右键移除，并加入独立创造栏分组。
- 新增 0-9 黑白两套 Minecraft 字体数字水贴。
- 新增红星、白星、黑星、军衔、箭头、警示条、警示三角、识别条、低可视识别条等常规标识水贴。
- 新增实验性 2x2 红星/白星水贴，可将一张大水贴分片覆盖到四个相邻迷彩方块上。
- 新增“可疑烤鸡”功能方块，内置 27 格隐藏容器。
- 改进连接迷彩方块刷新逻辑，放置、邻居变化和水贴修改后会自动刷新周围连接状态。
- 已从正式包中移除废弃的炮击破口测试水贴。

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
- Version: 1.4.1
- Release type: Release
- Required dependency: NeoForge
- Optional dependency: JEI
- License: All Rights Reserved


## License

All Rights Reserved. See [LICENSE](LICENSE) for the full project license.
