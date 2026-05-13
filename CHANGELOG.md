# CamoWarfare Changelog

## 1.4.5

### English

- Rebalanced camouflage hull and armor attachment durability for Create Big Cannons combat, with stronger full-block armor values and revised blast resistance.
- Added optional Create Big Cannons compatibility in a dedicated mixin config so CamoWarfare can still run without CBC installed.
- Added reactive armor behavior for add-on armor plates: CBC projectiles now break the reactive plate, trigger a small non-destructive blast effect, and are consumed before normal penetration or over-penetration can damage armor behind it.
- Changed slat armor CBC behavior so cannon projectiles pass through cleanly, with a chance to reduce projectile mass and slightly reduce velocity instead of invoking normal block penetration.
- Reduced slat armor collision coverage so projectiles only interact with the sparse bars instead of the full visual panel.
- Restored Create Creative Worldshaper sampling for the decalable armor plate by marking it as safe for NBT-aware block selection.
- Added vehicle deck hatches with trapdoor-style placement, metal hatch sounds, redstone opening, waterlogging, color variants, loot tables, recipes, translations, and tooltips.
- Added Copycats+ slope, slope-layer, and straight-stair placement support for add-on armor plates and slat armor so attachments can follow sloped vehicle hulls.
- Added sloped slat armor models with matching lightweight collision and neighbor-refreshing connector logic for continuous grille runs across slopes.
- Added colored crafting recipes for add-on armor plates, slat armor, vehicle hanging plates, and vehicle deck hatches.
- Refactored Copycats surface detection into shared attachment support code and removed obsolete vehicle hatch texture leftovers.

### 中文

- 重新平衡迷彩车体方块和装甲附件在 Create Big Cannons 战斗中的耐久表现，提高完整装甲方块的抗穿能力并调整爆炸抗性。
- 将 Create Big Cannons 兼容逻辑拆分到独立的可选 mixin 配置中，未安装 CBC 时迷彩战车仍可正常加载。
- 为附加装甲板加入爆反行为：CBC 炮弹命中后会击碎爆反板，触发小型非破坏性爆炸效果，并在进入普通穿深或过穿结算前抵消炮弹。
- 调整格栅装甲的 CBC 行为：炮弹会顺畅穿过格栅，并有概率削减炮弹质量和少量速度，不再触发普通方块穿透结算。
- 缩小格栅装甲碰撞判定，让炮弹只与稀疏杆件交互，而不是碰到完整视觉面板就进入碰撞。
- 将可贴花基础装甲板标记为 Create 安全 NBT 方块，恢复创造环境改造枪对该方块的取样识别。
- 新增车厢舱盖，支持原版活板门式放置、金属舱盖声音、红石开合、水含水状态，并补齐颜色变体、掉落表、配方、翻译和提示文本。
- 为附加装甲板和格栅装甲新增 Copycats+ 斜坡、斜坡层、直楼梯贴附支持，让附件可以跟随倾斜车体表面。
- 新增斜面格栅装甲模型、轻量碰撞和邻近刷新连接逻辑，使格栅能在连续斜面上衔接。
- 补齐附加装甲板、格栅装甲、车体挂载板和车厢舱盖的不同颜色合成配方。
- 将 Copycats 斜面识别抽成共用附件支撑逻辑，并移除不再引用的舱盖残留贴图。

## 1.4.4test18

### English

- Tuned full camouflage and armor plate block blast resistance from 32 to 24 and raised their Create Big Cannons penetration resistance from 16 to 36, while keeping CBC hardness at 2 and leaving add-on armor plate blast resistance higher.
- Restored add-on armor plate CBC values to the proven reactive-armor setup after test5 incorrectly swapped hardness and toughness.
- Lowered add-on armor plate CBC tag toughness from 1 to 0.1 for reactive-armor testing.
- Set add-on armor plate CBC values to hardness 0.1 and toughness 56, and set full armor block CBC values to hardness 3 and toughness 56.
- Swapped add-on armor plate CBC test values to hardness 56 and toughness 0.1.
- Set add-on armor plate CBC values to hardness 512 and toughness 0.1, and set full armor block CBC values to hardness 64 and toughness 3.
- Corrected the CBC value orientation for this test: add-on armor plates now use hardness 0.1 and toughness 512, while full armor blocks use hardness 3 and toughness 64.
- Moved Create Big Cannons compatibility into a dedicated optional mixin config that only applies when CBC is present.
- Added reactive armor interception against CBC projectiles: add-on armor plates break without drops and consume the projectile before normal penetration or over-penetration handling runs.
- Fixed the CBC compatibility mixin gate so it checks for CBC class resources without loading CBC classes during early mixin preparation.
- Added a small non-destructive explosion effect when reactive armor consumes a CBC projectile.
- Changed slat armor CBC handling so hits pass through cleanly, with a chance to reduce projectile mass and slightly reduce velocity instead of invoking normal block penetration.
- Reduced slat armor collision coverage so cannon projectiles only collide with sparse thin bars instead of the full visual grille.
- Added Create Big Cannons compatibility for slat armor so non-intercepting slat hits pass through without the projectile stutter caused by full impact handling.
- Marked the decalable armor plate as safe for Create's NBT-aware worldshaper selection, restoring block sampling with the Creative Worldshaper.

### 中文

- 将完整迷彩方块和基础装甲板方块的爆炸抗性从 32 调整为 24，并将其 Create Big Cannons 抗穿数值从 16 提高到 36；CBC 硬度保持 2，外挂装甲板仍保留较高爆炸抗性。
- 将外挂装甲板 CBC 数值恢复为此前验证可用的爆反配置；test5 中误将硬度和韧性对调，已撤回。
- 将外挂装甲板 CBC 标签韧性从 1 调到 0.1，用于爆反行为测试。
- 将外挂装甲板 CBC 数值设为硬度 0.1、韧性 56；将所有完整装甲方块 CBC 数值设为硬度 3、韧性 56。
- 将外挂装甲板 CBC 测试数值对调为硬度 56、韧性 0.1。
- 将外挂装甲板 CBC 数值设为硬度 512、韧性 0.1；将所有完整装甲方块 CBC 数值设为硬度 64、韧性 3。
- 缩小格栅装甲碰撞判定范围，让炮弹只会命中少量细判定杆，而不是擦到完整视觉格栅就进入碰撞结算。
- 新增 Create Big Cannons 格栅装甲兼容：未触发拦截的格栅命中会直接穿过，避免进入完整命中结算造成炮弹卡顿。
- 将可贴花基础装甲板标记为 Create 安全 NBT 方块，恢复创造环境改造枪对该方块的取样识别。

## 1.4.3

### English

- Added four utility marking decals: medical, radar, ammunition, and fuel.
- Added item models, worn decal textures, creative-tab entries, translations, and basic dye + paper + slime-ball recipes for the new utility decals.
- Rebuilt utility decal item icons from a saved shared decal-sheet backing extracted from the existing decal set, instead of approximating the backing procedurally.
- Changed the medical marking to a red cross inside a white roundel and tuned utility decal wear to readable block damage.
- Added usage and mechanism tooltips for attachment blocks, spray stencils, and decals.
- Fixed decal removal so Shift + empty-hand right-click removes the last decal from the clicked face.

### 中文

- 新增四种功能标识水贴：医疗、雷达、弹药、燃油。
- 为这些功能标识补齐物品模型、旧化水贴贴图、创造栏条目、语言文本，以及染料 + 纸 + 粘液球基础配方。
- 将功能标识水贴图标改为使用从现有水贴组提取并保存的共用底板，不再用程序近似仿造底板。
- 将医疗标识改为白色圆底包裹红十字，并将旧化调整为清楚可读的块状磨损。
- 为附件方块、喷涂板和水贴新增用途与机制说明。
- 修复水贴移除操作：现在 Shift + 空手右键目标面即可移除该面最后一张水贴。

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
