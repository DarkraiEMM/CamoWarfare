package com.camowarfare;

import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.world.InteractionHand;
import net.minecraft.world.InteractionResult;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.level.Level;
import net.neoforged.neoforge.event.entity.player.PlayerInteractEvent;

final class CamoDecalRemovalEvents {
    private CamoDecalRemovalEvents() {}

    static void onRightClickBlock(PlayerInteractEvent.RightClickBlock event) {
        if (event.getHand() != InteractionHand.MAIN_HAND || !event.getItemStack().isEmpty()) {
            return;
        }

        Player player = event.getEntity();
        if (!player.isShiftKeyDown()) {
            return;
        }

        Direction face = event.getFace();
        if (face == null) {
            return;
        }

        Level level = event.getLevel();
        BlockPos pos = event.getPos();
        if (level.isClientSide || !CamoDecalItem.removeLastDecal(level, pos, face)) {
            return;
        }

        event.setCanceled(true);
        event.setCancellationResult(InteractionResult.SUCCESS);
    }
}
