package com.camowarfare;

import net.minecraft.world.level.material.MapColor;

public enum AttachmentColor {
    MILITARY_GREEN("military_green", "solid_military_green_a_block", "Military Green", "军绿", MapColor.COLOR_GREEN),
    DESERT_SAND("desert_sand", "solid_desert_sand_a_block", "Desert Sand", "沙黄", MapColor.SAND),
    BLUEGRAY("bluegray", "solid_bluegray_a_block", "Blue-Gray", "蓝灰", MapColor.COLOR_LIGHT_BLUE),
    NIGHT_BLACK("night_black", "solid_night_black_a_block", "Night Black", "夜战黑", MapColor.COLOR_BLACK);

    private final String id;
    private final String sourceBlockId;
    private final String enName;
    private final String zhName;
    private final MapColor mapColor;

    AttachmentColor(String id, String sourceBlockId, String enName, String zhName, MapColor mapColor) {
        this.id = id;
        this.sourceBlockId = sourceBlockId;
        this.enName = enName;
        this.zhName = zhName;
        this.mapColor = mapColor;
    }

    public String id() {
        return id;
    }

    public String sourceBlockId() {
        return sourceBlockId;
    }

    public String enName() {
        return enName;
    }

    public String zhName() {
        return zhName;
    }

    public MapColor mapColor() {
        return mapColor;
    }
}
