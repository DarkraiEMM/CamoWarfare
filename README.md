# CamoWarfare

CamoWarfare is a NeoForge mod for Minecraft 1.21.1 that gives vehicle builders a focused toolbox for camouflage hulls, armor detailing, decals, and military-style surface decoration.

Build armored vehicles with standard and large camouflage blocks, add-on armor plates, slat armor, vehicle hanging plates, deck hatches, spray stencils, and worn tactical decals. The creative inventory is organized into themed sections for woodland, mountain, desert, snow, night, naval, urban, and solid-color builds, making large vehicle projects easier to browse and assemble.

迷彩战车是面向 Minecraft 1.21.1 NeoForge 的载具装饰与装甲细节模组，为战车、装甲车、舰船和军事风格建筑提供迷彩车体、外挂装甲、水贴和表面标识工具。

你可以使用标准/大块迷彩车体方块、附加装甲板、格栅装甲、车体挂载板、车厢舱盖、喷涂模板和旧化战术水贴来搭建更有层次的载具外观。创造栏按林地、山地、沙漠、雪地、夜战、海军、城市和纯色等主题整理，适合大型载具工程快速查找和搭配。

## Features

- Camouflage hull blocks in standard and large variants
- Add-on armor plates, slat armor, vehicle hanging plates, and deck hatches
- Tactical decals and spray stencil items for markings and identification
- Grouped creative inventory sections for easier browsing
- Multiplayer-safe NeoForge mod for Minecraft 1.21.1
- Optional JEI, Copycats+, and Create Big Cannons compatibility
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
- Version: 1.4.7
- Release type: Release
- Required dependency: NeoForge
- Optional dependencies: JEI, Copycats+, Create Big Cannons
- License: All Rights Reserved


## License

All Rights Reserved. See [LICENSE](LICENSE) for the full project license.
