# CamoWarfare Changelog

## 1.4.2

### English

- Reworked the decal system so standard one-block decals can be placed on vanilla and modded full cubes, while connected camouflage blocks still support larger multi-block decals.
- Added client-synced world decal rendering for ordinary full blocks and made decals visual-only, with no aviation mass, CBC armor value, or blast resistance contribution.
- Refined decal art with dirtier, worn textures; rebuilt stars, numbers, warning stripes, warning triangles, identification bars, arrows, and black tactical rank markings.
- Added eight-direction white arrow decals and black tactical bar/chevron rank decals.
- Improved decal item icons and first-person held presentation so decals read more like sticker sheets in the inventory and hand.
- Fixed decal tinting/overlay issues that made black and white star decals render red or pink.
- Added decal crafting recipes, including dye + paper + slime-ball base recipes and ordered number cycling recipes in the crafting grid.
- Reduced armor attachment break/hit particle load to avoid large particle bursts and related stutter.
- Refined spray stencil icons.
- Adjusted selected legacy/reset camouflage and solid-color palettes with clearer same-palette block variation, leaving the hand-made PLA, NATO, Turkish, EDRL, EMR, OCP, and night/low-visibility base camouflage sets untouched.

### 中文

- 重做水贴系统：普通单方块水贴现在可以贴到原版和其他 mod 的完整方块上，连接迷彩方块仍保留大尺寸多方块水贴能力。
- 新增普通完整方块的客户端同步水贴渲染；水贴保持纯视觉属性，不提供航空学质量、CBC 装甲值或抗爆贡献。
- 重绘水贴美术，整体更脏、更旧化；星徽、数字、警示条、警示三角、识别条、箭头和黑色战术军衔标识都已调整。
- 新增八方向白色箭头水贴，以及黑色战术横杠/折杠军衔水贴。
- 改进水贴物品图标和第一人称手持表现，让它在物品栏和手上更像一张贴纸。
- 修复黑星、白星水贴在世界中被叠色成红色或粉色的问题。
- 新增水贴合成配方，包括染料 + 纸 + 粘液球的基础配方，以及工作台内有序循环数字的配方。
- 降低装甲挂件破坏/击打时的粒子量，缓解大量粒子导致的卡顿。
- 精细化喷涂板物品图标。
- 调整部分旧版/重置迷彩和纯色方块色板，让单方块内也能看到更清楚的同色系差分；手工生成的 PLA、北约、土耳其、EDRL、EMR、OCP 以及夜战/低可视基础迷彩未改动。

## 1.4.1

### English

- Added camouflage decals with per-face placement, up to three decals per face, Shift-right-click removal, and a dedicated creative-tab section.
- Added black and white Minecraft-font number decals from 0-9.
- Added red, white, and black star decals plus chevrons, arrows, warning stripes, warning triangles, identification bars, and low-visibility bars.
- Added experimental 2x2 red and white star decals that split one large decal across four connected camouflage blocks.
- Added the Suspicious Roast Chicken utility block with a hidden 27-slot container.
- Improved connected camouflage block refresh so nearby blocks update their connection state automatically after placement, neighbor changes, and decal edits.
- Removed abandoned shell-impact decal test resources from the release build.

### 中文

- 新增水贴系统，支持按方块面放置、每面最多 3 张、Shift 右键移除，并加入独立创造栏分组。
- 新增 0-9 黑白两套 Minecraft 字体数字水贴。
- 新增红星、白星、黑星、军衔、箭头、警示条、警示三角、识别条、低可视识别条等常规标识水贴。
- 新增实验性 2x2 红星/白星水贴，可将一张大水贴分片覆盖到四个相邻迷彩方块上。
- 新增“可疑烤鸡”功能方块，内置 27 格隐藏容器。
- 改进连接迷彩方块刷新逻辑，放置、邻居变化和水贴修改后会自动刷新周围连接状态。
- 已从正式包中移除废弃的炮击破口测试水贴。

## 1.3.4

### English

- Added Copycats+ camouflage tile support using pre-sliced atlas tiles.
- Fixed six-face camouflage sampling so standard blocks and Copycats parts connect across all world directions.
- Fixed disappearing camouflage faces in taller builds by preserving full block positions in model data.
- Updated generated camouflage model resources for copycat atlas tile references.
- Kept ordinary camouflage blocks and Copycats camouflage parts on the same coordinate rule for mixed builds.

### 中文

- 新增 Copycats+ 迷彩切片支持，使用预切 atlas tile 资源。
- 修复六个方向的迷彩采样，使普通方块和 Copycats 零件能在所有世界方向上正确连接。
- 通过保留完整方块坐标，修复高层堆叠时部分迷彩面消失的问题。
- 更新生成的迷彩模型资源，加入 copycat atlas tile 引用。
- 普通迷彩方块和 Copycats 迷彩零件统一使用同一套坐标规则，便于混合搭建。
