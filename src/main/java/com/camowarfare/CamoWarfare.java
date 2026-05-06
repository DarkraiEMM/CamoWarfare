package com.camowarfare;

import com.mojang.logging.LogUtils;
import java.util.ArrayList;
import java.util.EnumMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import net.minecraft.core.registries.Registries;
import net.minecraft.network.chat.Component;
import net.minecraft.world.item.BlockItem;
import net.minecraft.world.item.CreativeModeTab;
import net.minecraft.world.item.Item;
import net.minecraft.world.level.ItemLike;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.entity.BlockEntityType;
import net.minecraft.world.level.block.state.BlockBehaviour;
import net.minecraft.world.level.material.MapColor;
import net.neoforged.bus.api.IEventBus;
import net.neoforged.fml.ModContainer;
import net.neoforged.fml.common.Mod;
import net.neoforged.neoforge.common.NeoForge;
import net.neoforged.neoforge.registries.DeferredBlock;
import net.neoforged.neoforge.registries.DeferredHolder;
import net.neoforged.neoforge.registries.DeferredItem;
import net.neoforged.neoforge.registries.DeferredRegister;
import net.neoforged.neoforge.network.event.RegisterPayloadHandlersEvent;
import org.slf4j.Logger;

@Mod(CamoWarfare.MOD_ID)
public final class CamoWarfare {
    public static final String MOD_ID = "camowarfare";
    public static final Logger LOGGER = LogUtils.getLogger();
    private static final float BLOCK_HARDNESS = 2.0F;
    private static final float BLOCK_BLAST_RESISTANCE = 12.0F;
    private static final float ADD_ON_ARMOR_BLAST_RESISTANCE = 32.0F;
    private static final float SLAT_ARMOR_HARDNESS = 1.0F;
    private static final float SLAT_ARMOR_BLAST_RESISTANCE = 8.0F;

    public static final DeferredRegister.Blocks BLOCKS = DeferredRegister.createBlocks(MOD_ID);
    public static final DeferredRegister.Items ITEMS = DeferredRegister.createItems(MOD_ID);
    public static final DeferredRegister<BlockEntityType<?>> BLOCK_ENTITY_TYPES = DeferredRegister.create(Registries.BLOCK_ENTITY_TYPE, MOD_ID);
    public static final DeferredRegister<CreativeModeTab> CREATIVE_TABS = DeferredRegister.create(Registries.CREATIVE_MODE_TAB, MOD_ID);

    public static final DeferredBlock<Block> ARMOR_PLATE = registerCustomUtilityBlock("armor_plate_block", () -> new DecalableArmorPlateBlock(armorPlateProperties()));
    public static final DeferredBlock<Block> MATTE_OLIVE_PANEL = registerCustomUtilityBlock("matte_olive_panel_block", () -> new ConnectedPreviewPanelBlock(armorPlateProperties()));
    public static final DeferredBlock<Block> DEFINITION_SAMPLE = registerCustomUtilityBlock("definition_sample_block", () -> new ConnectedCamoBlock("definition_sample", armorPlateProperties()));
    public static final DeferredBlock<Block> DEFINITION_SAMPLE_64 = registerCustomUtilityBlock("definition_sample_64_block", () -> new ConnectedCamoBlock("definition_sample_64", armorPlateProperties()));
    public static final DeferredBlock<Block> NATO_TRICOLOR_MOUNTAIN_STANDARD = registerCustomUtilityBlock("nato_tricolor_mountain_standard_block", () -> new ConnectedCamoBlock("nato_tricolor_mountain_standard", armorPlateProperties()));
    public static final DeferredBlock<Block> NATO_TRICOLOR_MOUNTAIN_LARGE = registerCustomUtilityBlock("nato_tricolor_mountain_large_block", () -> new ConnectedCamoBlock("nato_tricolor_mountain_large", armorPlateProperties()));
    public static final DeferredBlock<Block> TURKISH_MULTITERRAIN_STANDARD = registerCustomUtilityBlock("turkish_multiterrain_standard_block", () -> new ConnectedCamoBlock("turkish_multiterrain_standard", armorPlateProperties()));
    public static final DeferredBlock<Block> TURKISH_MULTITERRAIN_LARGE = registerCustomUtilityBlock("turkish_multiterrain_large_block", () -> new ConnectedCamoBlock("turkish_multiterrain_large", armorPlateProperties()));
    public static final DeferredBlock<Block> EDRL_GREEN_STANDARD = registerCustomUtilityBlock("edrl_green_standard_block", () -> new ConnectedCamoBlock("edrl_green_standard", armorPlateProperties()));
    public static final DeferredBlock<Block> EDRL_GREEN_LARGE = registerCustomUtilityBlock("edrl_green_large_block", () -> new ConnectedCamoBlock("edrl_green_large", armorPlateProperties()));
    public static final DeferredBlock<Block> RUSSIAN_EMR_STANDARD = registerCustomUtilityBlock("russian_emr_standard_block", () -> new ConnectedCamoBlock("russian_emr_standard", armorPlateProperties()));
    public static final DeferredBlock<Block> RUSSIAN_EMR_LARGE = registerCustomUtilityBlock("russian_emr_large_block", () -> new ConnectedCamoBlock("russian_emr_large", armorPlateProperties()));
    public static final DeferredBlock<Block> US_OCP_MULTICAM_STANDARD = registerCustomUtilityBlock("us_ocp_multicam_standard_block", () -> new ConnectedCamoBlock("us_ocp_multicam_standard", armorPlateProperties()));
    public static final DeferredBlock<Block> US_OCP_MULTICAM_LARGE = registerCustomUtilityBlock("us_ocp_multicam_large_block", () -> new ConnectedCamoBlock("us_ocp_multicam_large", armorPlateProperties()));
    public static final DeferredBlock<Block> ADD_ON_ARMOR_PLATE = registerCustomUtilityBlock("add_on_armor_plate_block", () -> new AddOnArmorPlateBlock(addOnArmorPlateProperties(MapColor.METAL)));
    public static final DeferredBlock<Block> SLAT_ARMOR = registerCustomUtilityBlock("slat_armor_block", () -> new SlatArmorBlock(slatArmorProperties(MapColor.METAL)));
    public static final DeferredBlock<Block> VEHICLE_HANGING_PLATE = registerCustomUtilityBlock("vehicle_hanging_plate_block", () -> new VehicleHangingPlateBlock(vehicleHangingPlateProperties(MapColor.METAL)));
    public static final DeferredBlock<Block> SUSPICIOUS_ROAST_CHICKEN = registerCustomUtilityBlock("suspicious_roast_chicken_block", () -> new SuspiciousRoastChickenBlock(suspiciousRoastChickenProperties()));

    private static final Map<AttachmentColor, DeferredBlock<Block>> COLORED_ADD_ON_ARMOR_BLOCKS = new EnumMap<>(AttachmentColor.class);
    private static final Map<AttachmentColor, DeferredBlock<Block>> COLORED_SLAT_ARMOR_BLOCKS = new EnumMap<>(AttachmentColor.class);
    private static final Map<AttachmentColor, DeferredBlock<Block>> COLORED_VEHICLE_HANGING_PLATE_BLOCKS = new EnumMap<>(AttachmentColor.class);
    private static final Map<CreativeSection, List<DeferredItem<Item>>> SECTION_DIVIDER_ITEMS = new EnumMap<>(CreativeSection.class);
    private static final Map<CreativeSection, List<DeferredItem<Item>>> SECTION_SPACERS = new EnumMap<>(CreativeSection.class);
    private static final List<java.util.function.Supplier<? extends ItemLike>> TAB_ENTRIES = new ArrayList<>();
    private static CreativeSection activeSection = CreativeSection.ATTACHMENTS;
    private static final List<SprayStencilDefinition> SPRAY_STENCILS = createSprayStencils();
    private static final Map<String, DeferredItem<Item>> SPRAY_STENCIL_ITEMS = registerSprayStencils();
    private static final List<DecalDefinition> DECALS = createDecals();
    private static final Map<String, DeferredItem<Item>> DECAL_ITEMS = registerDecals();
    private static final List<TerrainCamoDefinition> TERRAIN_CAMOS = createTerrainCamos();
    private static final Map<String, TerrainCamoBlocks> TERRAIN_CAMO_BLOCKS = registerTerrainCamos();
    private static final List<ResetCamoDefinition> RESET_CAMOS = createResetCamos();
    private static final Map<String, TerrainCamoBlocks> RESET_CAMO_BLOCKS = registerResetCamos();

    public static final DeferredHolder<BlockEntityType<?>, BlockEntityType<ConnectedCamoBlockEntity>> CONNECTED_CAMO_BLOCK_ENTITY =
        BLOCK_ENTITY_TYPES.register("connected_camo", () -> {
            List<Block> blocks = new ArrayList<>();
            blocks.add(ARMOR_PLATE.get());
            addConnectedCamoBlocks(blocks);
            return BlockEntityType.Builder.of(ConnectedCamoBlockEntity::new, blocks.toArray(Block[]::new)).build(null);
        });

    public static final DeferredHolder<BlockEntityType<?>, BlockEntityType<VehicleHangingPlateBlockEntity>> VEHICLE_HANGING_PLATE_BLOCK_ENTITY =
        BLOCK_ENTITY_TYPES.register("vehicle_hanging_plate", () -> {
            List<Block> blocks = new ArrayList<>();
            blocks.add(VEHICLE_HANGING_PLATE.get());
            for (AttachmentColor color : AttachmentColor.values()) {
                blocks.add(COLORED_VEHICLE_HANGING_PLATE_BLOCKS.get(color).get());
            }
            return BlockEntityType.Builder.of(VehicleHangingPlateBlockEntity::new, blocks.toArray(Block[]::new)).build(null);
        });

    public static final DeferredHolder<BlockEntityType<?>, BlockEntityType<SuspiciousRoastChickenBlockEntity>> SUSPICIOUS_ROAST_CHICKEN_BLOCK_ENTITY =
        BLOCK_ENTITY_TYPES.register("suspicious_roast_chicken", () ->
            BlockEntityType.Builder.of(SuspiciousRoastChickenBlockEntity::new, SUSPICIOUS_ROAST_CHICKEN.get()).build(null)
        );

    static {
        for (CreativeSection section : CreativeSection.values()) {
            List<DeferredItem<Item>> dividers = new ArrayList<>();
            dividers.add(ITEMS.registerSimpleItem(section.titleItemId()));
            for (int i = 1; i <= 8; i++) {
                dividers.add(ITEMS.registerSimpleItem(section.fillItemId(i)));
            }
            SECTION_DIVIDER_ITEMS.put(section, List.copyOf(dividers));

            List<DeferredItem<Item>> spacers = new ArrayList<>();
            for (int i = 1; i <= 8; i++) {
                spacers.add(ITEMS.registerSimpleItem("section_spacer_" + section.id() + "_" + i));
            }
            SECTION_SPACERS.put(section, List.copyOf(spacers));
        }

        for (AttachmentColor color : AttachmentColor.values()) {
            DeferredBlock<Block> addOn = registerCustomUtilityBlock(
                "add_on_armor_plate_" + color.id() + "_block",
                () -> new AddOnArmorPlateBlock(addOnArmorPlateProperties(color.mapColor()))
            );
            DeferredBlock<Block> slat = registerCustomUtilityBlock(
                "slat_armor_" + color.id() + "_block",
                () -> new SlatArmorBlock(slatArmorProperties(color.mapColor()))
            );
            DeferredBlock<Block> hangingPlate = registerCustomUtilityBlock(
                "vehicle_hanging_plate_" + color.id() + "_block",
                () -> new VehicleHangingPlateBlock(vehicleHangingPlateProperties(color.mapColor()))
            );
            COLORED_ADD_ON_ARMOR_BLOCKS.put(color, addOn);
            COLORED_SLAT_ARMOR_BLOCKS.put(color, slat);
            COLORED_VEHICLE_HANGING_PLATE_BLOCKS.put(color, hangingPlate);
        }
        addAttachmentSection();
        addStencilSection();
        addDecalSection();

        addResetSection(CreativeSection.WOODLAND);
        addBasicBlocks(TURKISH_MULTITERRAIN_STANDARD, TURKISH_MULTITERRAIN_LARGE);
        addBasicBlocks(EDRL_GREEN_STANDARD, EDRL_GREEN_LARGE);
        addBasicBlocks(RUSSIAN_EMR_STANDARD, RUSSIAN_EMR_LARGE);
        addBasicBlocks(US_OCP_MULTICAM_STANDARD, US_OCP_MULTICAM_LARGE);
        addTerrainCamos(CreativeSection.WOODLAND);

        addResetSection(CreativeSection.MOUNTAIN);
        addBasicBlocks(DEFINITION_SAMPLE_64, DEFINITION_SAMPLE);
        addBasicBlocks(NATO_TRICOLOR_MOUNTAIN_STANDARD, NATO_TRICOLOR_MOUNTAIN_LARGE);
        addTerrainCamos(CreativeSection.MOUNTAIN);

        addResetSection(CreativeSection.DESERT);
        addTerrainCamos(CreativeSection.DESERT);

        addResetSection(CreativeSection.SNOW);
        addTerrainCamos(CreativeSection.SNOW);

        addResetSection(CreativeSection.NIGHT);

        addResetSection(CreativeSection.NAVAL);

        addResetSection(CreativeSection.URBAN);
        addTerrainCamos(CreativeSection.URBAN);

        addResetSection(CreativeSection.SOLID);
    }

    public static final DeferredHolder<CreativeModeTab, CreativeModeTab> CAMO_TAB = CREATIVE_TABS.register("camouflage_warfare", () ->
        CreativeModeTab.builder()
            .title(Component.translatable("itemGroup.camowarfare.camouflage_warfare"))
            .icon(() -> new ItemStack(RESET_CAMO_BLOCKS.get("woodland_blotch").standard().get()))
            .displayItems((parameters, output) -> TAB_ENTRIES.forEach(entry -> output.accept(entry.get())))
            .build()
    );

    public CamoWarfare(IEventBus modEventBus, ModContainer modContainer) {
        BLOCKS.register(modEventBus);
        ITEMS.register(modEventBus);
        BLOCK_ENTITY_TYPES.register(modEventBus);
        CREATIVE_TABS.register(modEventBus);
        modEventBus.addListener(RegisterPayloadHandlersEvent.class, WorldDecalNetworking::register);
        NeoForge.EVENT_BUS.addListener(CamoDecalRemovalEvents::onRightClickBlock);
        SophisticatedBackpacksCompat.registerInventoryHandler();
        LOGGER.info("Initializing {}", MOD_ID);
    }

    public static List<Block> attachmentArmorBlocks() {
        List<Block> blocks = new ArrayList<>();
        blocks.add(ADD_ON_ARMOR_PLATE.get());
        blocks.add(SLAT_ARMOR.get());
        blocks.add(VEHICLE_HANGING_PLATE.get());
        for (AttachmentColor color : AttachmentColor.values()) {
            blocks.add(COLORED_ADD_ON_ARMOR_BLOCKS.get(color).get());
            blocks.add(COLORED_SLAT_ARMOR_BLOCKS.get(color).get());
            blocks.add(COLORED_VEHICLE_HANGING_PLATE_BLOCKS.get(color).get());
        }
        return blocks;
    }

    private static DeferredBlock<Block> registerUtilityBlock(String name, BlockBehaviour.Properties properties) {
        DeferredBlock<Block> block = BLOCKS.register(name, () -> new Block(properties));
        ITEMS.registerItem(name, itemProperties -> new CamoTooltipBlockItem(block.get(), itemProperties, CamoTooltips.blockKey(name)));
        return block;
    }

    private static DeferredBlock<Block> registerCustomUtilityBlock(String name, java.util.function.Supplier<Block> supplier) {
        DeferredBlock<Block> block = BLOCKS.register(name, supplier);
        ITEMS.registerItem(name, itemProperties -> new CamoTooltipBlockItem(block.get(), itemProperties, CamoTooltips.blockKey(name)));
        return block;
    }

    private static Map<String, TerrainCamoBlocks> registerTerrainCamos() {
        Map<String, TerrainCamoBlocks> blocks = new LinkedHashMap<>();
        for (TerrainCamoDefinition definition : TERRAIN_CAMOS) {
            DeferredBlock<Block> standard = registerCustomUtilityBlock(
                definition.id() + "_standard_block",
                () -> new ConnectedCamoBlock(definition.id() + "_standard", armorPlateProperties())
            );
            DeferredBlock<Block> large = registerCustomUtilityBlock(
                definition.id() + "_large_block",
                () -> new ConnectedCamoBlock(definition.id() + "_large", armorPlateProperties())
            );
            blocks.put(definition.id(), new TerrainCamoBlocks(standard, large));
        }
        return Map.copyOf(blocks);
    }

    private static Map<String, TerrainCamoBlocks> registerResetCamos() {
        Map<String, TerrainCamoBlocks> blocks = new LinkedHashMap<>();
        for (ResetCamoDefinition definition : RESET_CAMOS) {
            DeferredBlock<Block> standard = registerCustomUtilityBlock(
                definition.id() + "_standard_block",
                () -> new ConnectedCamoBlock(definition.id() + "_standard", armorPlateProperties())
            );
            DeferredBlock<Block> large = null;
            if (definition.hasLarge()) {
                large = registerCustomUtilityBlock(
                    definition.id() + "_large_block",
                    () -> new ConnectedCamoBlock(definition.id() + "_large", armorPlateProperties())
                );
            }
            blocks.put(definition.id(), new TerrainCamoBlocks(standard, large));
        }
        return Map.copyOf(blocks);
    }

    private static Map<String, DeferredItem<Item>> registerSprayStencils() {
        Map<String, DeferredItem<Item>> items = new LinkedHashMap<>();
        for (SprayStencilDefinition definition : SPRAY_STENCILS) {
            items.put(definition.id(), ITEMS.registerItem(
                definition.itemId(),
                properties -> new CamoTooltipItem(properties, "item.camowarfare.tooltip.spray_stencil")
            ));
        }
        return Map.copyOf(items);
    }

    private static Map<String, DeferredItem<Item>> registerDecals() {
        Map<String, DeferredItem<Item>> items = new LinkedHashMap<>();
        for (DecalDefinition definition : DECALS) {
            items.put(definition.id(), ITEMS.registerItem(
                definition.itemId(),
                properties -> new CamoDecalItem(definition.id(), properties)
            ));
        }
        return Map.copyOf(items);
    }

    private static void addSectionDivider(CreativeSection section) {
        List<DeferredItem<Item>> dividerItems = SECTION_DIVIDER_ITEMS.get(section);
        TAB_ENTRIES.addAll(dividerItems);
    }

    private static void addAttachmentSection() {
        beginSection(CreativeSection.ATTACHMENTS);
        TAB_ENTRIES.add(ARMOR_PLATE);
        TAB_ENTRIES.add(MATTE_OLIVE_PANEL);
        TAB_ENTRIES.add(ADD_ON_ARMOR_PLATE);
        TAB_ENTRIES.add(SLAT_ARMOR);
        TAB_ENTRIES.add(VEHICLE_HANGING_PLATE);
        TAB_ENTRIES.add(SUSPICIOUS_ROAST_CHICKEN);
        for (AttachmentColor color : AttachmentColor.values()) {
            TAB_ENTRIES.add(COLORED_ADD_ON_ARMOR_BLOCKS.get(color));
            TAB_ENTRIES.add(COLORED_SLAT_ARMOR_BLOCKS.get(color));
            TAB_ENTRIES.add(COLORED_VEHICLE_HANGING_PLATE_BLOCKS.get(color));
        }
    }

    private static void addStencilSection() {
        beginSection(CreativeSection.STENCILS);
        for (SprayStencilDefinition definition : SPRAY_STENCILS) {
            TAB_ENTRIES.add(SPRAY_STENCIL_ITEMS.get(definition.id()));
        }
        TAB_ENTRIES.add(SECTION_SPACERS.get(CreativeSection.STENCILS).get(0));
    }

    private static void addDecalSection() {
        beginSection(CreativeSection.DECALS);
        for (DecalDefinition definition : DECALS) {
            TAB_ENTRIES.add(DECAL_ITEMS.get(definition.id()));
        }
        alignToNextRow(CreativeSection.DECALS);
    }

    private static void addConnectedCamoBlocks(List<Block> blocks) {
        addBlock(blocks, DEFINITION_SAMPLE);
        addBlock(blocks, DEFINITION_SAMPLE_64);
        addBlock(blocks, NATO_TRICOLOR_MOUNTAIN_STANDARD);
        addBlock(blocks, NATO_TRICOLOR_MOUNTAIN_LARGE);
        addBlock(blocks, TURKISH_MULTITERRAIN_STANDARD);
        addBlock(blocks, TURKISH_MULTITERRAIN_LARGE);
        addBlock(blocks, EDRL_GREEN_STANDARD);
        addBlock(blocks, EDRL_GREEN_LARGE);
        addBlock(blocks, RUSSIAN_EMR_STANDARD);
        addBlock(blocks, RUSSIAN_EMR_LARGE);
        addBlock(blocks, US_OCP_MULTICAM_STANDARD);
        addBlock(blocks, US_OCP_MULTICAM_LARGE);
        for (TerrainCamoBlocks camoBlocks : TERRAIN_CAMO_BLOCKS.values()) {
            addCamoPair(blocks, camoBlocks);
        }
        for (TerrainCamoBlocks camoBlocks : RESET_CAMO_BLOCKS.values()) {
            addCamoPair(blocks, camoBlocks);
        }
    }

    private static void addCamoPair(List<Block> blocks, TerrainCamoBlocks camoBlocks) {
        addBlock(blocks, camoBlocks.standard());
        if (camoBlocks.large() != null) {
            addBlock(blocks, camoBlocks.large());
        }
    }

    private static void addBlock(List<Block> blocks, DeferredBlock<Block> block) {
        blocks.add(block.get());
    }

    @SafeVarargs
    private static void addBasicBlocks(java.util.function.Supplier<? extends ItemLike>... entries) {
        for (java.util.function.Supplier<? extends ItemLike> entry : entries) {
            TAB_ENTRIES.add(entry);
        }
    }

    private static void addTerrainCamos(CreativeSection section) {
        for (TerrainCamoDefinition definition : TERRAIN_CAMOS) {
            if (definition.section() == section) {
                TerrainCamoBlocks blocks = TERRAIN_CAMO_BLOCKS.get(definition.id());
                TAB_ENTRIES.add(blocks.standard());
                TAB_ENTRIES.add(blocks.large());
            }
        }
    }

    private static void addResetSection(CreativeSection section) {
        beginSection(section);
        for (ResetCamoDefinition definition : RESET_CAMOS) {
            if (definition.section() == section) {
                TerrainCamoBlocks blocks = RESET_CAMO_BLOCKS.get(definition.id());
                TAB_ENTRIES.add(blocks.standard());
                if (blocks.large() != null) {
                    TAB_ENTRIES.add(blocks.large());
                }
            }
        }
    }

    private static void beginSection(CreativeSection section) {
        alignToNextRow(activeSection);
        activeSection = section;
        addSectionDivider(section);
    }

    private static List<TerrainCamoDefinition> createTerrainCamos() {
        List<TerrainCamoDefinition> definitions = new ArrayList<>();
        for (TerrainCamoBase base : TerrainCamoBase.values()) {
            definitions.add(new TerrainCamoDefinition(base.prefix() + "_woodland", CreativeSection.WOODLAND));
            definitions.add(new TerrainCamoDefinition(base.prefix() + "_mountain", CreativeSection.MOUNTAIN));
            definitions.add(new TerrainCamoDefinition(base.prefix() + "_desert", CreativeSection.DESERT));
            definitions.add(new TerrainCamoDefinition(base.prefix() + "_snow", CreativeSection.SNOW));
            definitions.add(new TerrainCamoDefinition(base.prefix() + "_urban", CreativeSection.URBAN));
        }
        return List.copyOf(definitions);
    }

    private static List<SprayStencilDefinition> createSprayStencils() {
        return List.of(
            new SprayStencilDefinition("blotch"),
            new SprayStencilDefinition("splinter"),
            new SprayStencilDefinition("digital"),
            new SprayStencilDefinition("stripe"),
            new SprayStencilDefinition("tiger"),
            new SprayStencilDefinition("multiterrain"),
            new SprayStencilDefinition("whitewash"),
            new SprayStencilDefinition("lowvis")
        );
    }

    private static List<DecalDefinition> createDecals() {
        List<DecalDefinition> decals = new ArrayList<>();
        decals.add(new DecalDefinition("mark_red_star"));
        decals.add(new DecalDefinition("mark_red_star_2x2"));
        decals.add(new DecalDefinition("mark_white_star"));
        decals.add(new DecalDefinition("mark_white_star_2x2"));
        decals.add(new DecalDefinition("mark_black_star"));
        decals.add(new DecalDefinition("mark_tactical_bar_black"));
        decals.add(new DecalDefinition("mark_tactical_double_bar_black"));
        decals.add(new DecalDefinition("mark_tactical_chevron_black"));
        decals.add(new DecalDefinition("mark_tactical_double_chevron_black"));
        decals.add(new DecalDefinition("mark_arrow_white_up"));
        decals.add(new DecalDefinition("mark_arrow_white_up_right"));
        decals.add(new DecalDefinition("mark_arrow_white_right"));
        decals.add(new DecalDefinition("mark_arrow_white_down_right"));
        decals.add(new DecalDefinition("mark_arrow_white_down"));
        decals.add(new DecalDefinition("mark_arrow_white_down_left"));
        decals.add(new DecalDefinition("mark_arrow_white_left"));
        decals.add(new DecalDefinition("mark_arrow_white_up_left"));
        decals.add(new DecalDefinition("mark_warning_triangle_red"));
        decals.add(new DecalDefinition("mark_warning_stripes"));
        decals.add(new DecalDefinition("mark_identification_bar_white"));
        decals.add(new DecalDefinition("mark_lowvis_bars"));
        decals.add(new DecalDefinition("mark_medical_red"));
        decals.add(new DecalDefinition("mark_radar_green"));
        decals.add(new DecalDefinition("mark_ammo_yellow"));
        decals.add(new DecalDefinition("mark_fuel_white"));
        for (String color : List.of("white", "black")) {
            for (int digit = 0; digit <= 9; digit++) {
                decals.add(new DecalDefinition("number_" + color + "_" + digit));
            }
        }
        return List.copyOf(decals);
    }

    private static List<ResetCamoDefinition> createResetCamos() {
        return List.of(
            new ResetCamoDefinition("woodland_blotch", CreativeSection.WOODLAND, true),
            new ResetCamoDefinition("russian_green_splinter", CreativeSection.WOODLAND, true),
            new ResetCamoDefinition("ukrainian_yellow_green", CreativeSection.WOODLAND, true),
            new ResetCamoDefinition("afrika_korps", CreativeSection.MOUNTAIN, true),
            new ResetCamoDefinition("russian_desert", CreativeSection.DESERT, true),
            new ResetCamoDefinition("desert_brush", CreativeSection.DESERT, true),
            new ResetCamoDefinition("winter_whitewash", CreativeSection.SNOW, true),
            new ResetCamoDefinition("snow_graywhite_digital", CreativeSection.SNOW, true),
            new ResetCamoDefinition("solid_night_black", CreativeSection.NIGHT, false),
            new ResetCamoDefinition("night_lowvis_digital", CreativeSection.NIGHT, true),
            new ResetCamoDefinition("solid_bluegray", CreativeSection.NAVAL, false),
            new ResetCamoDefinition("coastal_blue_digital", CreativeSection.NAVAL, true),
            new ResetCamoDefinition("ocean_blue_digital", CreativeSection.NAVAL, true),
            new ResetCamoDefinition("urban_digital", CreativeSection.URBAN, true),
            new ResetCamoDefinition("urban_gray_splinter", CreativeSection.URBAN, false),
            new ResetCamoDefinition("solid_military_green", CreativeSection.SOLID, false),
            new ResetCamoDefinition("us_carc_green383", CreativeSection.SOLID, false),
            new ResetCamoDefinition("us_carc_desert_tan", CreativeSection.SOLID, false),
            new ResetCamoDefinition("us_carc_blackgray", CreativeSection.SOLID, false)
        );
    }

    private static void alignToNextRow(CreativeSection section) {
        int remainder = TAB_ENTRIES.size() % 9;
        if (remainder == 0) {
            return;
        }

        int padding = 9 - remainder;
        List<DeferredItem<Item>> spacers = SECTION_SPACERS.get(section);
        for (int i = 0; i < padding; i++) {
            TAB_ENTRIES.add(spacers.get(i));
        }
    }

    private static BlockBehaviour.Properties armorPlateProperties() {
        return BlockBehaviour.Properties.of()
            .mapColor(MapColor.METAL)
            .strength(BLOCK_HARDNESS, BLOCK_BLAST_RESISTANCE)
            .requiresCorrectToolForDrops();
    }

    private static BlockBehaviour.Properties addOnArmorPlateProperties(MapColor mapColor) {
        return BlockBehaviour.Properties.of()
            .mapColor(mapColor)
            .strength(BLOCK_HARDNESS, ADD_ON_ARMOR_BLAST_RESISTANCE)
            .requiresCorrectToolForDrops();
    }

    private static BlockBehaviour.Properties slatArmorProperties(MapColor mapColor) {
        return BlockBehaviour.Properties.of()
            .mapColor(mapColor)
            .strength(SLAT_ARMOR_HARDNESS, SLAT_ARMOR_BLAST_RESISTANCE)
            .requiresCorrectToolForDrops()
            .noOcclusion();
    }

    private static BlockBehaviour.Properties vehicleHangingPlateProperties(MapColor mapColor) {
        return BlockBehaviour.Properties.of()
            .mapColor(mapColor)
            .strength(SLAT_ARMOR_HARDNESS, SLAT_ARMOR_BLAST_RESISTANCE)
            .requiresCorrectToolForDrops()
            .noOcclusion();
    }

    private static BlockBehaviour.Properties suspiciousRoastChickenProperties() {
        return BlockBehaviour.Properties.of()
            .mapColor(MapColor.COLOR_ORANGE)
            .strength(0.8F, 4.0F)
            .noOcclusion();
    }

    private record TerrainCamoDefinition(String id, CreativeSection section) {}
    private record TerrainCamoBlocks(DeferredBlock<Block> standard, DeferredBlock<Block> large) {}
    private record ResetCamoDefinition(String id, CreativeSection section, boolean hasLarge) {}
    private record SprayStencilDefinition(String id) {
        private String itemId() {
            return "spray_stencil_" + id;
        }
    }
    private record DecalDefinition(String id) {
        private String itemId() {
            return "decal_" + id;
        }
    }

    private enum TerrainCamoBase {
        PLA("pla"),
        NATO("nato"),
        TURKISH("turkish"),
        EDRL("edrl"),
        EMR("emr"),
        OCP("ocp");

        private final String prefix;

        TerrainCamoBase(String prefix) {
            this.prefix = prefix;
        }

        private String prefix() {
            return prefix;
        }
    }
}
