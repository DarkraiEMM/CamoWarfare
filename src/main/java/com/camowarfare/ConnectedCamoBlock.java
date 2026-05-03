package com.camowarfare;

import java.util.EnumMap;
import java.util.Map;

import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.world.item.context.BlockPlaceContext;
import net.minecraft.world.level.BlockGetter;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.LevelAccessor;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.EntityBlock;
import net.minecraft.world.level.block.entity.BlockEntity;
import net.minecraft.world.level.block.state.BlockBehaviour;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.block.state.StateDefinition;
import net.minecraft.world.level.block.state.properties.BlockStateProperties;
import net.minecraft.world.level.block.state.properties.BooleanProperty;

public class ConnectedCamoBlock extends Block implements EntityBlock {
    public static final BooleanProperty NORTH = BlockStateProperties.NORTH;
    public static final BooleanProperty SOUTH = BlockStateProperties.SOUTH;
    public static final BooleanProperty EAST = BlockStateProperties.EAST;
    public static final BooleanProperty WEST = BlockStateProperties.WEST;
    public static final BooleanProperty UP = BlockStateProperties.UP;
    public static final BooleanProperty DOWN = BlockStateProperties.DOWN;

    private static final Map<Direction, BooleanProperty> PROPERTIES_BY_DIRECTION = createPropertiesByDirection();

    private final String connectionKey;
    private final String connectionFamily;

    public ConnectedCamoBlock(String connectionKey, BlockBehaviour.Properties properties) {
        super(properties);
        this.connectionKey = connectionKey;
        this.connectionFamily = normalizeConnectionFamily(connectionKey);
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
    protected void onPlace(BlockState state, Level level, BlockPos pos, BlockState oldState, boolean movedByPiston) {
        super.onPlace(state, level, pos, oldState, movedByPiston);
        refreshAtAndAround(level, pos);
    }

    @Override
    protected void neighborChanged(BlockState state, Level level, BlockPos pos, Block neighborBlock, BlockPos neighborPos, boolean movedByPiston) {
        super.neighborChanged(state, level, pos, neighborBlock, neighborPos, movedByPiston);
        refreshAtAndAround(level, pos);
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

    BlockState updateConnections(BlockGetter level, BlockPos pos, BlockState state) {
        for (Direction direction : Direction.values()) {
            state = state.setValue(PROPERTIES_BY_DIRECTION.get(direction), connectsTo(level.getBlockState(pos.relative(direction))));
        }
        return state;
    }

    private boolean connectsTo(BlockState state) {
        return state.getBlock() instanceof ConnectedCamoBlock other && other.connectionFamily.equals(this.connectionFamily);
    }

    public String connectionFamily() {
        return connectionFamily;
    }

    @Override
    public BlockEntity newBlockEntity(BlockPos pos, BlockState state) {
        return new ConnectedCamoBlockEntity(pos, state);
    }

    private static void refreshAtAndAround(Level level, BlockPos pos) {
        if (level.isClientSide) {
            return;
        }

        refreshBlockEntity(level, pos);
        for (Direction direction : Direction.values()) {
            refreshBlockEntity(level, pos.relative(direction));
        }
    }

    private static void refreshBlockEntity(Level level, BlockPos pos) {
        if (level.getBlockEntity(pos) instanceof ConnectedCamoBlockEntity blockEntity) {
            blockEntity.refreshConnectionsAndClient();
        }
    }

    private static String normalizeConnectionFamily(String key) {
        if (key.endsWith("_standard")) {
            return key.substring(0, key.length() - "_standard".length());
        }
        if (key.endsWith("_large")) {
            return key.substring(0, key.length() - "_large".length());
        }
        if (key.endsWith("_64")) {
            return key.substring(0, key.length() - "_64".length());
        }
        return key;
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
