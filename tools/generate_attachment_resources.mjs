import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const resources = path.join(root, "src", "main", "resources");
const assets = path.join(resources, "assets", "camowarfare");
const dataRoot = path.join(resources, "data", "camowarfare");
const langDir = path.join(assets, "lang");
const blockstatesDir = path.join(assets, "blockstates");
const blockModelsDir = path.join(assets, "models", "block");
const itemModelsDir = path.join(assets, "models", "item");
const lootDir = path.join(dataRoot, "loot_tables", "blocks");
const recipeDir = path.join(dataRoot, "recipe", "original");
const createCuttingDir = path.join(dataRoot, "recipe", "compat", "create", "cutting");

const colorVariants = [
  {
    id: "military_green",
    source: "solid_military_green_a_block",
    en: "Military Green",
    zh: "军绿",
    ru: "Армейский зелёный",
    de: "Militärgrün",
    fr: "Vert militaire",
  },
  {
    id: "desert_sand",
    source: "solid_desert_sand_a_block",
    en: "Desert Sand",
    zh: "沙黄",
    ru: "Песочный",
    de: "Wüstensand",
    fr: "Sable désert",
  },
  {
    id: "bluegray",
    source: "solid_bluegray_a_block",
    en: "Blue-Gray",
    zh: "蓝灰",
    ru: "Сине-серый",
    de: "Blaugrau",
    fr: "Bleu-gris",
  },
  {
    id: "night_black",
    source: "solid_night_black_a_block",
    en: "Night Black",
    zh: "夜战黑",
    ru: "Ночной чёрный",
    de: "Nachtschwarz",
    fr: "Noir nocturne",
  },
];

const attachments = [
  {
    id: "add_on_armor_plate_block",
    kind: "panel",
    texture: "add_on_armor_plate_block",
    en: "Add-On Armor Plate",
    zh: "外挂装甲板",
    ru: "Навесная бронеплита",
    de: "Zusatzpanzerplatte",
    fr: "Plaque de blindage additionnelle",
    source: null,
  },
  {
    id: "slat_armor_block",
    kind: "slat",
    texture: "slat_armor_block",
    en: "Slat Armor Block",
    zh: "格栅装甲块",
    ru: "Решётчатая броня",
    de: "Gitterpanzerblock",
    fr: "Bloc de blindage en cage",
    source: null,
  },
  ...colorVariants.flatMap((color) => [
    {
      id: `add_on_armor_plate_${color.id}_block`,
      kind: "panel",
      texture: `add_on_armor_plate_${color.id}_block`,
      en: `${color.en} Add-On Armor Plate`,
      zh: `${color.zh}外挂装甲板`,
      ru: `Навесная бронеплита ${color.ru}`,
      de: `${color.en === "Blue-Gray" ? "Blaugraue" : color.de} Zusatzpanzerplatte`,
      fr: `Plaque de blindage additionnelle ${color.fr.toLowerCase()}`,
      source: color.source,
    },
    {
      id: `slat_armor_${color.id}_block`,
      kind: "slat",
      texture: `slat_armor_${color.id}_block`,
      en: `${color.en} Slat Armor`,
      zh: `${color.zh}格栅装甲块`,
      ru: `Решётчатая броня ${color.ru}`,
      de: `${color.en === "Blue-Gray" ? "Blaugraue" : color.de} Gitterpanzerung`,
      fr: `Blindage en cage ${color.fr.toLowerCase()}`,
      source: color.source,
    },
  ]),
];

function ensureDir(dir) {
  fs.mkdirSync(dir, { recursive: true });
}

function writeJson(filePath, data) {
  ensureDir(path.dirname(filePath));
  fs.writeFileSync(filePath, `${JSON.stringify(data, null, 2)}\n`, "utf8");
}

function writeBlockstate(id) {
  writeJson(path.join(blockstatesDir, `${id}.json`), {
    variants: {
      "facing=north": { model: `camowarfare:block/${id}` },
      "facing=east": { model: `camowarfare:block/${id}`, y: 90 },
      "facing=south": { model: `camowarfare:block/${id}`, y: 180 },
      "facing=west": { model: `camowarfare:block/${id}`, y: 270 },
    },
  });
}

function writePanelModel(id, texture) {
  writeJson(path.join(blockModelsDir, `${id}.json`), {
    parent: "block/block",
    textures: {
      plate: `camowarfare:block/${texture}`,
      particle: `camowarfare:block/${texture}`,
    },
    elements: [
      {
        from: [0, 2, 12],
        to: [16, 14, 13],
        faces: {
          north: { uv: [0, 2, 16, 14], texture: "#plate" },
          south: { uv: [0, 2, 16, 14], texture: "#plate" },
          east: { uv: [11, 2, 12, 14], texture: "#plate" },
          west: { uv: [4, 2, 5, 14], texture: "#plate" },
          up: { uv: [0, 11, 16, 12], texture: "#plate" },
          down: { uv: [0, 11, 16, 12], texture: "#plate" },
        },
      },
      {
        from: [1, 3, 13],
        to: [15, 13, 16],
        faces: {
          north: { uv: [1, 3, 15, 13], texture: "#plate" },
          south: { uv: [1, 3, 15, 13], texture: "#plate" },
          east: { uv: [12, 3, 15, 13], texture: "#plate" },
          west: { uv: [1, 3, 4, 13], texture: "#plate" },
          up: { uv: [1, 12, 15, 15], texture: "#plate" },
          down: { uv: [1, 12, 15, 15], texture: "#plate" },
        },
      },
    ],
  });
}

function writeSlatModel(id, texture, source = null) {
  const modelTexture = source ? source.replace(/_block$/, "/a") : texture;
  writeJson(path.join(blockModelsDir, `${id}.json`), {
    parent: "camowarfare:block/slat_armor_template",
    textures: {
      frame: source ? `camowarfare:block/${modelTexture}` : "camowarfare:block/slat_armor_frame",
      bar: source ? `camowarfare:block/${modelTexture}` : "camowarfare:block/slat_armor_bar",
      lip: source ? `camowarfare:block/${modelTexture}` : "camowarfare:block/slat_armor_lip",
      particle: source ? `camowarfare:block/${modelTexture}` : "camowarfare:block/slat_armor_frame",
    },
  });
}

function writeItemModel(id) {
  writeJson(path.join(itemModelsDir, `${id}.json`), {
    parent: `camowarfare:block/${id}`,
  });
}

function writeLoot(id) {
  writeJson(path.join(lootDir, `${id}.json`), {
    type: "minecraft:block",
    pools: [
      {
        rolls: 1,
        entries: [{ type: "minecraft:item", name: `camowarfare:${id}` }],
        conditions: [{ condition: "minecraft:survives_explosion" }],
      },
    ],
  });
}

function writeRecipe(attachment) {
  if (attachment.id === "add_on_armor_plate_block") {
    writeJson(path.join(recipeDir, `${attachment.id}.json`), {
      type: "minecraft:crafting_shapeless",
      category: "building",
      ingredients: [
        { item: "minecraft:tnt" },
        { item: "camowarfare:armor_plate_block" },
      ],
      result: {
        id: "camowarfare:add_on_armor_plate_block",
        count: 2,
      },
    });
    return;
  }

  if (attachment.id === "slat_armor_block") {
    writeJson(path.join(recipeDir, `${attachment.id}.json`), {
      type: "minecraft:crafting_shaped",
      category: "building",
      pattern: [
        "XXX",
        "XXX",
      ],
      key: {
        X: { item: "camowarfare:armor_plate_block" },
      },
      result: {
        id: "camowarfare:slat_armor_block",
        count: 16,
      },
    });

    writeJson(path.join(createCuttingDir, `${attachment.id}.json`), {
      "neoforge:conditions": [
        {
          type: "neoforge:mod_loaded",
          modid: "create",
        },
      ],
      type: "create:cutting",
      ingredients: [
        {
          item: "camowarfare:armor_plate_block",
        },
      ],
      processing_time: 50,
      results: [
        {
          id: "camowarfare:slat_armor_block",
          count: 8,
        },
      ],
    });
    return;
  }

  if (!attachment.source) return;
  if (attachment.kind === "slat") {
    writeJson(path.join(recipeDir, `${attachment.id}.json`), {
      type: "minecraft:crafting_shaped",
      category: "building",
      pattern: [
        "XXX",
        "XXX",
      ],
      key: {
        X: { item: `camowarfare:${attachment.source}` },
      },
      result: {
        id: `camowarfare:${attachment.id}`,
        count: 16,
      },
    });

    writeJson(path.join(createCuttingDir, `${attachment.id}.json`), {
      "neoforge:conditions": [
        {
          type: "neoforge:mod_loaded",
          modid: "create",
        },
      ],
      type: "create:cutting",
      ingredients: [
        {
          item: `camowarfare:${attachment.source}`,
        },
      ],
      processing_time: 50,
      results: [
        {
          id: `camowarfare:${attachment.id}`,
          count: 8,
        },
      ],
    });
    return;
  }

  writeJson(path.join(recipeDir, `${attachment.id}.json`), {
    type: "minecraft:crafting_shapeless",
    category: "building",
    ingredients: [
      { item: "camowarfare:add_on_armor_plate_block" },
      { item: `camowarfare:${attachment.source}` },
    ],
    result: {
      id: `camowarfare:${attachment.id}`,
      count: 1,
    },
  });
}

function updateLang(fileName, valueKey) {
  const filePath = path.join(langDir, fileName);
  const json = JSON.parse(fs.readFileSync(filePath, "utf8"));
  for (const attachment of attachments) {
    json[`block.camowarfare.${attachment.id}`] = attachment[valueKey];
  }
  fs.writeFileSync(filePath, `${JSON.stringify(json, null, 2)}\n`, "utf8");
}

for (const attachment of attachments) {
  writeBlockstate(attachment.id);
  if (attachment.kind === "panel") writePanelModel(attachment.id, attachment.texture);
  else writeSlatModel(attachment.id, attachment.texture, attachment.source);
  writeItemModel(attachment.id);
  writeLoot(attachment.id);
  writeRecipe(attachment);
}

updateLang("en_us.json", "en");
updateLang("zh_cn.json", "zh");
updateLang("ru_ru.json", "ru");
updateLang("de_de.json", "de");
updateLang("fr_fr.json", "fr");
