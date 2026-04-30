package com.camowarfare;

import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.world.level.block.entity.BlockEntity;
import net.minecraft.world.level.block.state.BlockState;
import net.neoforged.neoforge.client.model.data.ModelData;

public final class ConnectedCamoBlockEntity extends BlockEntity {
    public ConnectedCamoBlockEntity(BlockPos pos, BlockState blockState) {
        super(CamoWarfare.CONNECTED_CAMO_BLOCK_ENTITY.get(), pos, blockState);
    }

    @Override
    public ModelData getModelData() {
        return ModelData.builder()
            .with(ConnectedCamoModelData.POSITION_TILE_PROPERTY, packPosition(worldPosition))
            .with(ConnectedCamoModelData.CONNECTIONS_PROPERTY, connectionBits())
            .build();
    }

    private int connectionBits() {
        if (level == null || !(getBlockState().getBlock() instanceof ConnectedCamoBlock block)) {
            return 0;
        }

        int bits = 0;
        for (Direction direction : Direction.values()) {
            BlockState neighborState = level.getBlockState(worldPosition.relative(direction));
            if (neighborState.getBlock() instanceof ConnectedCamoBlock neighbor
                    && neighbor.connectionFamily().equals(block.connectionFamily())) {
                bits |= ConnectedCamoModelData.connectionBit(direction);
            }
        }
        return bits;
    }

    private static int packPosition(BlockPos pos) {
        return Math.floorMod(pos.getX(), 16)
            | (Math.floorMod(pos.getY(), 16) << 4)
            | (Math.floorMod(pos.getZ(), 16) << 8);
    }
}
