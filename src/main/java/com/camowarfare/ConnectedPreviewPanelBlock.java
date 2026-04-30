package com.camowarfare;

import java.util.EnumMap;
import java.util.Map;
import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.world.item.context.BlockPlaceContext;
import net.minecraft.world.level.BlockGetter;
import net.minecraft.world.level.LevelAccessor;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.Rotation;
import net.minecraft.world.level.block.state.BlockBehaviour;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.block.state.StateDefinition;
import net.minecraft.world.level.block.state.properties.BooleanProperty;
import net.minecraft.world.level.block.state.properties.BlockStateProperties;
import net.minecraft.world.level.block.state.properties.EnumProperty;

public final class ConnectedPreviewPanelBlock extends Block {
    public static final EnumProperty<Direction.Axis> AXIS = BlockStateProperties.AXIS;
    private static final Map<Direction, BooleanProperty> PROPERTIES_BY_DIRECTION = createPropertiesByDirection();

    public ConnectedPreviewPanelBlock(BlockBehaviour.Properties properties) {
        super(properties);
        this.registerDefaultState(this.stateDefinition.any()
            .setValue(AXIS, Direction.Axis.Y)
            .setValue(ConnectedCamoBlock.NORTH, false)
            .setValue(ConnectedCamoBlock.SOUTH, false)
            .setValue(ConnectedCamoBlock.EAST, false)
            .setValue(ConnectedCamoBlock.WEST, false)
            .setValue(ConnectedCamoBlock.UP, false)
            .setValue(ConnectedCamoBlock.DOWN, false));
    }

    @Override
    protected void createBlockStateDefinition(StateDefinition.Builder<Block, BlockState> builder) {
        builder.add(
            AXIS,
            ConnectedCamoBlock.NORTH,
            ConnectedCamoBlock.SOUTH,
            ConnectedCamoBlock.EAST,
            ConnectedCamoBlock.WEST,
            ConnectedCamoBlock.UP,
            ConnectedCamoBlock.DOWN
        );
    }

    @Override
    public BlockState getStateForPlacement(BlockPlaceContext context) {
        BlockState placedState = this.defaultBlockState().setValue(AXIS, context.getClickedFace().getAxis());
        return updateConnections(context.getLevel(), context.getClickedPos(), placedState);
    }

    @Override
    protected BlockState updateShape(
        BlockState state,
        Direction direction,
        BlockState neighborState,
        LevelAccessor level,
        BlockPos currentPos,
        BlockPos neighborPos
    ) {
        return state.setValue(PROPERTIES_BY_DIRECTION.get(direction), connectsTo(state, neighborState));
    }

    @Override
    public BlockState rotate(BlockState state, Rotation rotation) {
        if (rotation == Rotation.CLOCKWISE_90 || rotation == Rotation.COUNTERCLOCKWISE_90) {
            Direction.Axis axis = state.getValue(AXIS);
            if (axis == Direction.Axis.X) {
                return state.setValue(AXIS, Direction.Axis.Z);
            }
            if (axis == Direction.Axis.Z) {
                return state.setValue(AXIS, Direction.Axis.X);
            }
        }
        return state;
    }

    private BlockState updateConnections(BlockGetter level, BlockPos pos, BlockState state) {
        for (Direction direction : Direction.values()) {
            state = state.setValue(PROPERTIES_BY_DIRECTION.get(direction), connectsTo(state, level.getBlockState(pos.relative(direction))));
        }
        return state;
    }

    private boolean connectsTo(BlockState state, BlockState neighborState) {
        return neighborState.getBlock() instanceof ConnectedPreviewPanelBlock
            && neighborState.getValue(AXIS) == state.getValue(AXIS);
    }

    private static Map<Direction, BooleanProperty> createPropertiesByDirection() {
        Map<Direction, BooleanProperty> result = new EnumMap<>(Direction.class);
        result.put(Direction.NORTH, ConnectedCamoBlock.NORTH);
        result.put(Direction.SOUTH, ConnectedCamoBlock.SOUTH);
        result.put(Direction.EAST, ConnectedCamoBlock.EAST);
        result.put(Direction.WEST, ConnectedCamoBlock.WEST);
        result.put(Direction.UP, ConnectedCamoBlock.UP);
        result.put(Direction.DOWN, ConnectedCamoBlock.DOWN);
        return Map.copyOf(result);
    }
}
