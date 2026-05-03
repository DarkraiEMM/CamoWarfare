package com.camowarfare;

import java.util.List;
import net.minecraft.network.chat.Component;
import net.minecraft.world.item.BlockItem;
import net.minecraft.world.item.Item;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.TooltipFlag;
import net.minecraft.world.level.block.Block;

public final class CamoTooltipBlockItem extends BlockItem {
    private final String tooltipKey;

    public CamoTooltipBlockItem(Block block, Item.Properties properties, String tooltipKey) {
        super(block, properties);
        this.tooltipKey = tooltipKey;
    }

    @Override
    public void appendHoverText(ItemStack stack, Item.TooltipContext context, List<Component> tooltip, TooltipFlag flag) {
        super.appendHoverText(stack, context, tooltip, flag);
        if (!tooltipKey.isEmpty()) {
            CamoTooltips.add(tooltip, tooltipKey);
        }
    }
}
