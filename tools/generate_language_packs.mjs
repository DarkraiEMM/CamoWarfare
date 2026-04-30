import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const javaRoot = path.join(root, "src", "main", "java", "com", "camowarfare");
const langRoot = path.join(root, "src", "main", "resources", "assets", "camowarfare", "lang");

const camoFamilySource = fs.readFileSync(path.join(javaRoot, "CamoFamily.java"), "utf8");
const attachmentColorSource = fs.readFileSync(path.join(javaRoot, "AttachmentColor.java"), "utf8");
const creativeSectionSource = fs.readFileSync(path.join(javaRoot, "CreativeSection.java"), "utf8");

const zhFamilyNames = {
  nato_woodland: "林地斑驳",
  nato_woodland_riveted: "林地斑驳铆接",
  nato_woodland_stained: "林地斑驳污渍",
  nato_woodland_weathered: "林地斑驳风化",
  woodland_macro: "宽斑林地",
  woodland_macro_riveted: "宽斑林地铆接",
  woodland_macro_stained: "宽斑林地污渍",
  woodland_macro_weathered: "宽斑林地风化",

  russian_green_splinter: "深绿裂斑",
  russian_desert: "沙地裂斑",
  nato_desert: "沙漠斑驳",
  nato_desert_riveted: "沙漠斑驳铆接",
  nato_desert_stained: "沙漠斑驳污渍",
  nato_desert_weathered: "沙漠斑驳风化",
  desert_modern: "现代沙漠迷彩",
  desert_brush: "沙漠条斑迷彩",

  woodland_digital: "林地数码",
  desert_digital: "沙漠数码",
  urban_digital: "城市数码",
  urban_digital_hull: "城市数码舱体",

  naval_bluegray: "蓝灰迷彩",
  naval_bluegray_camo: "蓝灰斑驳迷彩",
  naval_bluegray_digital: "蓝灰数码迷彩",
  naval_bluegray_splinter: "蓝灰舱体迷彩",
  coastal_blue_digital: "近海蓝数码",
  ocean_blue_digital: "海洋蓝数码",
  pla_05_naval_blue: "深海蓝迷彩",
  pla_05_naval_blue_hull: "深海蓝舱体",
  pla_05_naval_blue_riveted: "深海蓝铆接",
  pla_05_naval_blue_stained: "深海蓝污渍",
  pla_05_naval_blue_weathered: "深海蓝风化",

  winter_whitewash: "冬季白洗",
  winter_whitewash_hull: "冬季白洗舱体",
  snow_graywhite_camo: "雪地灰白迷彩",
  snow_graywhite_digital: "雪地灰白数码",
  snow_graywhite_splinter: "雪地灰白舱体",

  black_night: "夜战迷彩",
  black_night_hull: "夜战舱体",
  night_lowvis_camo: "低可视夜战",
  night_lowvis_digital: "低可视夜战数码",
  night_lowvis_splinter: "低可视夜战舱体",

  solid_military_green: "军绿纯色",
  solid_desert_sand: "沙色纯色",
  solid_bluegray: "蓝灰纯色",
  solid_night_black: "夜黑纯色",

  stryker_deep_olive: "深橄榄绿",
  stryker_deep_olive_riveted: "深橄榄绿铆接",
  stryker_deep_olive_stained: "深橄榄绿污渍",
  stryker_deep_olive_weathered: "深橄榄绿风化",

  ukrainian_yellow_green: "黄绿混合迷彩",
  ukrainian_yellow_green_riveted: "黄绿混合迷彩铆接",
  ukrainian_yellow_green_stained: "黄绿混合迷彩污渍",
  ukrainian_yellow_green_weathered: "黄绿混合迷彩风化",

  pla_woodland: "山林斑块",
  pla_woodland_riveted: "山林斑块铆接",
  pla_woodland_stained: "山林斑块污渍",
  pla_woodland_weathered: "山林斑块风化",
  pla_mountain: "山地斑块",
  pla_mountain_digital: "山地数码",
  pla_mountain_tiger: "山地虎斑",
  pla_mountain_riveted: "山地斑块铆接",
  pla_mountain_stained: "山地斑块污渍",
  pla_mountain_weathered: "山地斑块风化",

  urban_gray_camo: "城市灰迷彩",
  urban_gray_digital: "城市灰数码",
  urban_gray_splinter: "城市灰舱体",
};

const zhAttachmentNames = {
  military_green: "军绿",
  desert_sand: "沙色",
  bluegray: "蓝灰",
  night_black: "夜黑",
};

const zhSectionNames = {
  attachments: "附件系统",
  woodland: "林地迷彩",
  mountain: "山地迷彩",
  desert: "沙漠迷彩",
  snow: "雪地迷彩",
  night: "夜战迷彩",
  naval: "蓝灰迷彩",
  urban: "城市迷彩",
  solid: "纯色车体",
};

const directUtilityNames = {
  armor_plate_block: { en: "Armor Plate", zh: "装甲底板" },
  add_on_armor_plate_block: { en: "Add-On Armor Plate", zh: "外挂装甲板" },
  slat_armor_block: { en: "Slat Armor Block", zh: "栅栏装甲块" },
};

const familyMatches = [...camoFamilySource.matchAll(
  /^\s*[A-Z0-9_]+\("([^"]+)",\s*"([^"]+)",\s*"([^"]+)",\s*MapColor\.[A-Z_]+,\s*(null|"[^"]+")\)[,;]?$/gm,
)];

const families = familyMatches.map((match) => ({
  id: match[1],
  en: match[3],
  legacy: match[4] === "null" ? null : match[4].slice(1, -1),
}));

const attachmentMatches = [...attachmentColorSource.matchAll(
  /^\s*[A-Z0-9_]+\("([^"]+)",\s*"([^"]+)",\s*"([^"]+)",\s*"([^"]+)",\s*MapColor\.[A-Z_]+\),?$/gm,
)];

const attachments = attachmentMatches.map((match) => ({
  id: match[1],
  en: match[3],
}));

const sectionMatches = [...creativeSectionSource.matchAll(
  /^\s*[A-Z_]+\("([^"]+)",\s*"([^"]+)",\s*"([^"]+)"\),?$/gm,
)];

const sections = sectionMatches.map((match) => ({
  id: match[1],
  en: match[3],
}));

function familyVariantKey(id, variant) {
  return `block.camowarfare.${id}_${variant}_block`;
}

function createBaseLanguage(mode) {
  const out = {};
  out["itemGroup.camowarfare.camouflage_warfare"] = mode === "zh" ? "迷彩战车" : "Camouflage Warfare";

  for (const [blockId, names] of Object.entries(directUtilityNames)) {
    out[`block.camowarfare.${blockId}`] = names[mode];
  }

  for (const attachment of attachments) {
    const zhName = zhAttachmentNames[attachment.id] ?? attachment.en;
    out[`block.camowarfare.add_on_armor_plate_${attachment.id}_block`] =
      mode === "zh" ? `${zhName}外挂装甲板` : `${attachment.en} Add-On Armor Plate`;
    out[`block.camowarfare.slat_armor_${attachment.id}_block`] =
      mode === "zh" ? `${zhName}栅栏装甲` : `${attachment.en} Slat Armor`;
  }

  for (const family of families) {
    const familyName = mode === "zh"
      ? (zhFamilyNames[family.id] ?? family.en)
      : family.en;

    for (const variant of ["a", "b", "c", "d"]) {
      const suffix = variant.toUpperCase();
      out[familyVariantKey(family.id, variant)] =
        mode === "zh" ? `${familyName}方块 ${suffix}` : `${familyName} Block ${suffix}`;
    }
  }

  for (const section of sections) {
    const zhName = zhSectionNames[section.id] ?? section.en;
    out[`item.camowarfare.section_${section.id}_title`] =
      mode === "zh" ? `${zhName}分栏` : `${section.en} Divider`;
    for (let i = 1; i <= 8; i++) {
      out[`item.camowarfare.section_${section.id}_fill_${i}`] = " ";
      out[`item.camowarfare.section_spacer_${section.id}_${i}`] = " ";
    }
  }

  return out;
}

const en = createBaseLanguage("en");
const zh = createBaseLanguage("zh");

const locales = {
  "en_us.json": en,
  "zh_cn.json": zh,
  "ru_ru.json": en,
  "de_de.json": en,
  "fr_fr.json": en,
};

fs.mkdirSync(langRoot, { recursive: true });
for (const [fileName, payload] of Object.entries(locales)) {
  fs.writeFileSync(path.join(langRoot, fileName), `${JSON.stringify(payload, null, 2)}\n`, "utf8");
}

console.log("language packs regenerated");
