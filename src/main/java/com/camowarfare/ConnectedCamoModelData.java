package com.camowarfare;

import net.minecraft.core.Direction;
import net.neoforged.neoforge.client.model.data.ModelProperty;

public final class ConnectedCamoModelData {
    public static final ModelProperty<Boolean> COPYCAT_ATLAS_PROPERTY = new ModelProperty<>();
    public static final ModelProperty<Integer> POSITION_TILE_PROPERTY = new ModelProperty<>();
    public static final ModelProperty<net.minecraft.core.BlockPos> POSITION_PROPERTY = new ModelProperty<>();
    public static final ModelProperty<Integer> CONNECTIONS_PROPERTY = new ModelProperty<>();

    private ConnectedCamoModelData() {
    }

    public static int connectionBit(Direction direction) {
        return switch (direction) {
            case NORTH -> 1;
            case SOUTH -> 1 << 1;
            case EAST -> 1 << 2;
            case WEST -> 1 << 3;
            case UP -> 1 << 4;
            case DOWN -> 1 << 5;
        };
    }
}
