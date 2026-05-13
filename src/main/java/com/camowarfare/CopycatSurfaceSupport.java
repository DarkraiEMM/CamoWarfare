package com.camowarfare;

import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.core.registries.BuiltInRegistries;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.world.item.context.BlockPlaceContext;
import net.minecraft.world.level.LevelReader;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.block.state.properties.BlockStateProperties;
import net.minecraft.world.level.block.state.properties.DirectionProperty;
import net.minecraft.world.level.block.state.properties.Half;
import net.minecraft.world.level.block.state.properties.StairsShape;

record CopycatSurfaceSupport(Direction facing, Half half) {
    static CopycatSurfaceSupport findForPlacement(BlockPlaceContext context) {
        Direction clickedFace = context.getClickedFace();
        LevelReader level = context.getLevel();
        BlockPos pos = context.getClickedPos();

        if (clickedFace == Direction.UP) {
            CopycatSurfaceSupport support = read(level.getBlockState(pos.below()));
            return support != null && support.half() == Half.BOTTOM ? support : null;
        }
        if (clickedFace == Direction.DOWN) {
            CopycatSurfaceSupport support = read(level.getBlockState(pos.above()));
            return support != null && support.half() == Half.TOP ? support : null;
        }

        return null;
    }

    static CopycatSurfaceSupport read(BlockState state) {
        ResourceLocation id = BuiltInRegistries.BLOCK.getKey(state.getBlock());
        if (!"copycats".equals(id.getNamespace())) {
            return null;
        }

        String path = id.getPath();
        boolean slope = path.equals("copycat_slope") || path.equals("copycat_slope_layer");
        boolean stairs = path.equals("copycat_stairs");
        if (!slope && !stairs) {
            return null;
        }

        Direction facing = readHorizontalFacing(state);
        if (facing == null || !state.hasProperty(BlockStateProperties.HALF)) {
            return null;
        }
        if (stairs
            && state.hasProperty(BlockStateProperties.STAIRS_SHAPE)
            && state.getValue(BlockStateProperties.STAIRS_SHAPE) != StairsShape.STRAIGHT) {
            return null;
        }

        return new CopycatSurfaceSupport(facing, state.getValue(BlockStateProperties.HALF));
    }

    boolean matches(Direction facing, Half half) {
        return this.facing == facing && this.half == half;
    }

    private static Direction readHorizontalFacing(BlockState state) {
        if (state.hasProperty(BlockStateProperties.HORIZONTAL_FACING)) {
            return state.getValue(BlockStateProperties.HORIZONTAL_FACING);
        }

        for (var property : state.getProperties()) {
            if (property instanceof DirectionProperty directionProperty && property.getName().equals("facing")) {
                Direction direction = state.getValue(directionProperty);
                return direction.getAxis().isHorizontal() ? direction : null;
            }
        }
        return null;
    }
}
