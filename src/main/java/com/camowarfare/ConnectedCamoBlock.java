package com.camowarfare;

import java.util.EnumMap;
import java.util.Map;

import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.world.item.context.BlockPlaceContext;
import net.minecraft.world.level.BlockGetter;
import net.minecraft.world.level.LevelAccessor;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.state.BlockBehaviour;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.block.state.StateDefinition;
import net.minecraft.world.level.block.state.properties.BlockStateProperties;
import net.minecraft.world.level.block.state.properties.BooleanProperty;

public class ConnectedCamoBlock extends Block {
    public static final BooleanProperty NORTH = BlockStateProperties.NORTH;
    public static final BooleanProperty SOUTH = BlockStateProperties.SOUTH;
    public static final BooleanProperty EAST = BlockStateProperties.EAST;
    public static final BooleanProperty WEST = BlockStateProperties.WEST;
    public static final BooleanProperty UP = BlockStateProperties.UP;
    public static final BooleanProperty DOWN = BlockStateProperties.DOWN;

    private static final Map<Direction, BooleanProperty> PROPERTIES_BY_DIRECTION = createPropertiesByDirection();

    private final String connectionKey;

    public ConnectedCamoBlock(String connectionKey, BlockBehaviour.Properties properties) {
        super(properties);
        this.connectionKey = connectionKey;
        registerDefaultConnectionState();
    }

    private void registerDefaultConnectionState() {
        BlockState defaultState = this.stateDefinition.any()
            .setValue(NORTH, false)
            .setValue(SOUTH, false)
            .setValue(EAST, false)
            .setValue(WEST, false)
            .setValue(UP, false)
            .setValue(DOWN, false);
        this.registerDefaultState(defaultState);
    }

    @Override
    protected void createBlockStateDefinition(StateDefinition.Builder<Block, BlockState> builder) {
        builder.add(NORTH, SOUTH, EAST, WEST, UP, DOWN);
    }

    @Override
    public BlockState getStateForPlacement(BlockPlaceContext context) {
        return updateConnections(context.getLevel(), context.getClickedPos(), this.defaultBlockState());
    }

    @Override
    protected BlockState updateShape(
            BlockState state,
            Direction direction,
            BlockState neighborState,
            LevelAccessor level,
            BlockPos currentPos,
            BlockPos neighborPos) {
        return state.setValue(PROPERTIES_BY_DIRECTION.get(direction), connectsTo(neighborState));
    }

    private BlockState updateConnections(BlockGetter level, BlockPos pos, BlockState state) {
        for (Direction direction : Direction.values()) {
            state = state.setValue(PROPERTIES_BY_DIRECTION.get(direction), connectsTo(level.getBlockState(pos.relative(direction))));
        }
        return state;
    }

    private boolean connectsTo(BlockState state) {
        return state.getBlock() instanceof ConnectedCamoBlock other && other.connectionKey.equals(this.connectionKey);
    }

    private static Map<Direction, BooleanProperty> createPropertiesByDirection() {
        Map<Direction, BooleanProperty> result = new EnumMap<>(Direction.class);
        result.put(Direction.NORTH, NORTH);
        result.put(Direction.SOUTH, SOUTH);
        result.put(Direction.EAST, EAST);
        result.put(Direction.WEST, WEST);
        result.put(Direction.UP, UP);
        result.put(Direction.DOWN, DOWN);
        return Map.copyOf(result);
    }
}
