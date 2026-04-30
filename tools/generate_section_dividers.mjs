import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const resources = path.join(root, "src", "main", "resources");
const assets = path.join(resources, "assets", "camowarfare");
const itemModelsDir = path.join(assets, "models", "item");
const langDir = path.join(assets, "lang");

const sections = [
  { id: "attachments", zh: "附件系统", en: "Attachments" },
  { id: "woodland", zh: "林地迷彩", en: "Woodland Camouflage" },
  { id: "mountain", zh: "山地迷彩", en: "Mountain Camouflage" },
  { id: "desert", zh: "沙地迷彩", en: "Desert Camouflage" },
  { id: "snow", zh: "雪地迷彩", en: "Snow Camouflage" },
  { id: "night", zh: "夜战迷彩", en: "Night Camouflage" },
  { id: "naval", zh: "海军迷彩", en: "Naval Camouflage" },
  { id: "urban", zh: "城市迷彩", en: "Urban Camouflage" },
  { id: "solid", zh: "单色车体", en: "Solid Hull Colors" },
];

function ensureDir(dir) {
  fs.mkdirSync(dir, { recursive: true });
}

function writeJson(filePath, data) {
  ensureDir(path.dirname(filePath));
  fs.writeFileSync(filePath, `${JSON.stringify(data, null, 2)}\n`, "utf8");
}

function updateLang(fileName, valueFactory) {
  const filePath = path.join(langDir, fileName);
  const json = JSON.parse(fs.readFileSync(filePath, "utf8"));
  for (const section of sections) {
    json[`item.camowarfare.section_${section.id}_title`] = valueFactory(section, true);
    for (let i = 1; i <= 8; i++) {
      json[`item.camowarfare.section_${section.id}_fill_${i}`] = valueFactory(section, false);
    }
  }
  fs.writeFileSync(filePath, `${JSON.stringify(json, null, 2)}\n`, "utf8");
}

for (const section of sections) {
  writeJson(path.join(itemModelsDir, `section_${section.id}_title.json`), {
    parent: "minecraft:item/generated",
    textures: {
      layer0: `camowarfare:item/section_${section.id}_title`,
    },
  });

  for (let i = 1; i <= 8; i++) {
    writeJson(path.join(itemModelsDir, `section_${section.id}_fill_${i}.json`), {
      parent: "minecraft:item/generated",
      textures: {
        layer0: `camowarfare:item/section_${section.id}_fill_${i}`,
      },
    });
  }
}

updateLang("zh_cn.json", (section, isTitle) => (isTitle ? `${section.zh}分栏` : " "));
updateLang("en_us.json", (section, isTitle) => (isTitle ? `${section.en} Divider` : " "));
updateLang("ru_ru.json", (section, isTitle) => (isTitle ? section.en : " "));
updateLang("de_de.json", (section, isTitle) => (isTitle ? section.en : " "));
updateLang("fr_fr.json", (section, isTitle) => (isTitle ? section.en : " "));
