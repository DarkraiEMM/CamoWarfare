package com.camowarfare;

import java.util.List;
import net.minecraft.ChatFormatting;
import net.minecraft.network.chat.Component;

final class CamoTooltips {
    private CamoTooltips() {}

    static void add(List<Component> tooltip, String key) {
        tooltip.add(Component.translatable(key + ".summary").withStyle(ChatFormatting.GRAY));
        tooltip.add(Component.translatable(key + ".use").withStyle(ChatFormatting.DARK_GRAY));
        tooltip.add(Component.translatable(key + ".mechanic").withStyle(ChatFormatting.DARK_GRAY));
    }

    static String blockKey(String itemId) {
        if (itemId.contains("vehicle_hanging_plate")) {
            return "item.camowarfare.tooltip.attachment.hanging_plate";
        }
        if (itemId.contains("slat_armor")) {
            return "item.camowarfare.tooltip.attachment.slat_armor";
        }
        if (itemId.contains("add_on_armor_plate")) {
            return "item.camowarfare.tooltip.attachment.add_on_armor";
        }
        if (itemId.equals("armor_plate_block")) {
            return "item.camowarfare.tooltip.attachment.armor_plate";
        }
        return "";
    }
}
