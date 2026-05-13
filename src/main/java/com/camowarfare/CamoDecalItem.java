package com.camowarfare;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.network.chat.Component;
import net.minecraft.world.InteractionResult;
import net.minecraft.world.item.Item;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.TooltipFlag;
import net.minecraft.world.item.context.UseOnContext;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.entity.BlockEntity;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.world.entity.player.Player;

public final class CamoDecalItem extends Item {
    private final String decalId;

    public CamoDecalItem(String decalId, Properties properties) {
        super(properties);
        this.decalId = decalId;
    }

    @Override
    public void appendHoverText(ItemStack stack, Item.TooltipContext context, List<Component> tooltip, TooltipFlag flag) {
        super.appendHoverText(stack, context, tooltip, flag);
        CamoTooltips.add(tooltip, largeDecalSize() == null
            ? "item.camowarfare.tooltip.decal"
            : "item.camowarfare.tooltip.decal_large");
    }

    @Override
    public InteractionResult useOn(UseOnContext context) {
        Level level = context.getLevel();
        BlockPos clickedPos = context.getClickedPos();
        BlockEntity blockEntity = level.getBlockEntity(clickedPos);
        if (!(blockEntity instanceof ConnectedCamoBlockEntity connectedCamo)) {
            return useOnWorldBlock(context);
        }

        Direction face = context.getClickedFace();
        if (!level.isClientSide) {
            Player player = context.getPlayer();
            boolean removing = context.isSecondaryUseActive()
                || (player != null && (player.isSecondaryUseActive() || player.isShiftKeyDown()));
            if (removing) {
                String removed = connectedCamo.removeLastDecal(face);
                String groupId = ConnectedCamoBlockEntity.decalGroupId(removed);
                if (!groupId.isEmpty()) {
                    removeDecalGroup(level, clickedPos, face, groupId);
                }
            } else {
                DecalSize size = largeDecalSize();
                if (size != null) {
                    placeLargeDecal(level, clickedPos, face, size);
                } else {
                    connectedCamo.addDecal(face, decalId);
                }
            }
        }
        return InteractionResult.sidedSuccess(level.isClientSide);
    }

    private InteractionResult useOnWorldBlock(UseOnContext context) {
        Level level = context.getLevel();
        BlockPos clickedPos = context.getClickedPos();
        BlockState state = level.getBlockState(clickedPos);
        if (!state.isCollisionShapeFullBlock(level, clickedPos)) {
            return InteractionResult.PASS;
        }

        Direction face = context.getClickedFace();
        if (!level.isClientSide && level instanceof ServerLevel serverLevel) {
            WorldDecalData decals = WorldDecalData.get(serverLevel);
            Player player = context.getPlayer();
            boolean removing = context.isSecondaryUseActive()
                || (player != null && (player.isSecondaryUseActive() || player.isShiftKeyDown()));
            if (removing) {
                decals.removeLastDecal(clickedPos, face);
            } else if (largeDecalSize() == null) {
                decals.addDecal(clickedPos, face, decalId);
            } else {
                return InteractionResult.PASS;
            }
            WorldDecalNetworking.syncBlock(serverLevel, clickedPos);
        }
        return InteractionResult.sidedSuccess(level.isClientSide);
    }

    static boolean removeLastDecal(Level level, BlockPos clickedPos, Direction face) {
        BlockEntity blockEntity = level.getBlockEntity(clickedPos);
        if (blockEntity instanceof ConnectedCamoBlockEntity connectedCamo) {
            String removed = connectedCamo.removeLastDecal(face);
            if (!removed.isEmpty()) {
                String groupId = ConnectedCamoBlockEntity.decalGroupId(removed);
                if (!groupId.isEmpty()) {
                    removeDecalGroup(level, clickedPos, face, groupId);
                }
                return true;
            }
        }

        if (level instanceof ServerLevel serverLevel) {
            WorldDecalData decals = WorldDecalData.get(serverLevel);
            String removed = decals.removeLastDecal(clickedPos, face);
            if (removed.isEmpty()) {
                return false;
            }
            WorldDecalNetworking.syncBlock(serverLevel, clickedPos);
            return true;
        }
        return false;
    }

    static InteractionResult removeLastDecalWithoutItem(Level level, BlockPos clickedPos, Player player, Direction face) {
        if (!player.isShiftKeyDown()) {
            return InteractionResult.PASS;
        }
        if (level.isClientSide) {
            return InteractionResult.SUCCESS;
        }
        return removeLastDecal(level, clickedPos, face) ? InteractionResult.SUCCESS : InteractionResult.PASS;
    }

    private DecalSize largeDecalSize() {
        return decalId.endsWith("_2x2") ? new DecalSize(2, 2) : null;
    }

    private void placeLargeDecal(Level level, BlockPos clickedPos, Direction face, DecalSize size) {
        Direction right = planeRight(face);
        Direction up = planeUp(face);
        List<TargetPiece> targets = new ArrayList<>(size.width() * size.height());
        for (int y = 0; y < size.height(); y++) {
            for (int x = 0; x < size.width(); x++) {
                BlockPos pos = clickedPos.relative(right, x).relative(up, y);
                if (!(level.getBlockEntity(pos) instanceof ConnectedCamoBlockEntity blockEntity)) {
                    return;
                }
                targets.add(new TargetPiece(blockEntity, x, y));
            }
        }

        String groupId = UUID.randomUUID().toString();
        for (TargetPiece target : targets) {
            float u0 = (float) target.x() / size.width();
            float u1 = (float) (target.x() + 1) / size.width();
            float v0 = (float) (size.height() - target.y() - 1) / size.height();
            float v1 = (float) (size.height() - target.y()) / size.height();
            target.blockEntity().addDecalPiece(face, decalEntry(decalId, groupId, u0, v0, u1, v1));
        }
    }

    private static void removeDecalGroup(Level level, BlockPos clickedPos, Direction face, String groupId) {
        Direction right = planeRight(face);
        Direction up = planeUp(face);
        for (int y = -3; y <= 3; y++) {
            for (int x = -3; x <= 3; x++) {
                BlockPos pos = clickedPos.relative(right, x).relative(up, y);
                if (level.getBlockEntity(pos) instanceof ConnectedCamoBlockEntity blockEntity) {
                    blockEntity.removeDecalGroup(face, groupId);
                }
            }
        }
    }

    private static String decalEntry(String decalId, String groupId, float u0, float v0, float u1, float v1) {
        return decalId + "|" + groupId + "|" + u0 + "|" + v0 + "|" + u1 + "|" + v1;
    }

    private static Direction planeRight(Direction face) {
        return switch (face) {
            case NORTH -> Direction.WEST;
            case SOUTH -> Direction.EAST;
            case EAST -> Direction.NORTH;
            case WEST -> Direction.SOUTH;
            case UP, DOWN -> Direction.EAST;
        };
    }

    private static Direction planeUp(Direction face) {
        return switch (face) {
            case NORTH, SOUTH, EAST, WEST -> Direction.UP;
            case UP -> Direction.NORTH;
            case DOWN -> Direction.SOUTH;
        };
    }

    private record DecalSize(int width, int height) {}
    private record TargetPiece(ConnectedCamoBlockEntity blockEntity, int x, int y) {}
}
