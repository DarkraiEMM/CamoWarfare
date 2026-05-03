package com.camowarfare;

import java.util.Arrays;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

public enum CreativeSection {
    ATTACHMENTS("attachments", "\u9644\u4ef6\u7cfb\u7edf", "Attachments"),
    STENCILS("stencils", "\u55b7\u6d82\u677f", "Spray Stencils"),
    DECALS("decals", "\u6c34\u8d34", "Decals"),
    WOODLAND("woodland", "\u6797\u5730\u8ff7\u5f69", "Woodland Camouflage"),
    MOUNTAIN("mountain", "\u5c71\u5730\u8ff7\u5f69", "Mountain Camouflage"),
    DESERT("desert", "\u6c99\u5730\u8ff7\u5f69", "Desert Camouflage"),
    SNOW("snow", "\u96ea\u5730\u8ff7\u5f69", "Snow Camouflage"),
    NIGHT("night", "\u591c\u6218\u8ff7\u5f69", "Night Camouflage"),
    NAVAL("naval", "\u6d77\u519b\u8ff7\u5f69", "Naval Camouflage"),
    URBAN("urban", "\u57ce\u5e02\u8ff7\u5f69", "Urban Camouflage"),
    SOLID("solid", "\u5355\u8272\u8f66\u4f53", "Solid Hull Colors");

    private static final Map<String, CreativeSection> BY_ID = Arrays.stream(values())
        .collect(Collectors.toUnmodifiableMap(CreativeSection::id, Function.identity()));

    private final String id;
    private final String zhLabel;
    private final String enLabel;

    CreativeSection(String id, String zhLabel, String enLabel) {
        this.id = id;
        this.zhLabel = zhLabel;
        this.enLabel = enLabel;
    }

    public String id() {
        return id;
    }

    public String zhLabel() {
        return zhLabel;
    }

    public String enLabel() {
        return enLabel;
    }

    public String displayLabel(boolean chineseUi) {
        return chineseUi ? zhLabel : enLabel;
    }

    public String titleItemId() {
        return "section_" + id + "_title";
    }

    public String fillItemId(int index) {
        return "section_" + id + "_fill_" + index;
    }

    public static CreativeSection fromId(String id) {
        return BY_ID.get(id);
    }
}
