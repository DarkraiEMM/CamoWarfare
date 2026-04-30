package com.camowarfare;

import java.util.HashSet;
import java.util.Set;
import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.world.item.context.BlockPlaceContext;
import net.minecraft.world.level.BlockGetter;
import net.minecraft.world.level.LevelAccessor;
import net.minecraft.world.level.LevelReader;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.Blocks;
import net.minecraft.world.level.block.HorizontalDirectionalBlock;
import net.minecraft.world.level.block.Mirror;
import net.minecraft.world.level.block.Rotation;
import net.minecraft.world.level.block.state.BlockBehaviour;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.block.state.StateDefinition;
import net.minecraft.world.level.block.state.properties.BlockStateProperties;
import net.minecraft.world.level.block.state.properties.DirectionProperty;
import net.minecraft.world.phys.AABB;
import net.minecraft.world.phys.shapes.CollisionContext;
import net.minecraft.world.phys.shapes.VoxelShape;

public abstract class FaceMountedAttachmentBlock extends HorizontalDirectionalBlock {
    public static final DirectionProperty FACING = BlockStateProperties.HORIZONTAL_FACING;

    private final VoxelShape northShape;
    private final VoxelShape southShape;
    private final VoxelShape westShape;
    private final VoxelShape eastShape;

    protected FaceMountedAttachmentBlock(BlockBehaviour.Properties properties, VoxelShape northShape, VoxelShape southShape, VoxelShape westShape, VoxelShape eastShape) {
        super(properties);
        this.northShape = northShape;
        this.southShape = southShape;
        this.westShape = westShape;
        this.eastShape = eastShape;
        this.registerDefaultState(this.stateDefinition.any().setValue(FACING, Direction.NORTH));
    }

    @Override
    protected void createBlockStateDefinition(StateDefinition.Builder<Block, BlockState> builder) {
        builder.add(FACING);
    }

    @Override
    public BlockState getStateForPlacement(BlockPlaceContext context) {
        Direction facing = context.getClickedFace().getAxis().isHorizontal()
            ? context.getClickedFace()
            : context.getHorizontalDirection().getOpposite();
        BlockState state = this.defaultBlockState().setValue(FACING, facing);
        return state.canSurvive(context.getLevel(), context.getClickedPos()) ? state : null;
    }

    @Override
    public BlockState rotate(BlockState state, Rotation rotation) {
        return state.setValue(FACING, rotation.rotate(state.getValue(FACING)));
    }

    @Override
    public BlockState mirror(BlockState state, Mirror mirror) {
        return state.rotate(mirror.getRotation(state.getValue(FACING)));
    }

    @Override
    protected BlockState updateShape(BlockState state, Direction direction, BlockState neighborState, LevelAccessor level, BlockPos currentPos, BlockPos neighborPos) {
        return state.canSurvive(level, currentPos) ? state : Blocks.AIR.defaultBlockState();
    }

    @Override
    public boolean canSurvive(BlockState state, LevelReader level, BlockPos pos) {
        if (hasDirectSupport(state, level, pos)) {
            return true;
        }
        return allowsAttachmentExtension()
            && hasConnectedSupport(state, level, pos, new HashSet<>());
    }

    protected boolean allowsAttachmentExtension() {
        return false;
    }

    private boolean hasDirectSupport(BlockState state, LevelReader level, BlockPos pos) {
        Direction supportSide = state.getValue(FACING).getOpposite();
        BlockPos supportPos = pos.relative(supportSide);
        BlockState supportState = level.getBlockState(supportPos);
        if (supportState.getBlock() instanceof ConnectedCamoBlock) {
            return true;
        }
        if (supportState.isFaceSturdy(level, supportPos, state.getValue(FACING))) {
            return true;
        }
        return hasCollisionContactOnFace(supportState, level, supportPos, state.getValue(FACING));
    }

    private boolean hasConnectedSupport(BlockState state, LevelReader level, BlockPos pos, Set<BlockPos> visited) {
        if (!visited.add(pos)) {
            return false;
        }

        for (Direction neighborDirection : extensionDirections()) {
            BlockPos neighborPos = pos.relative(neighborDirection);
            BlockState neighborState = level.getBlockState(neighborPos);
            if (!isCompatibleExtension(state, neighborState)) {
                continue;
            }
            if (hasDirectSupport(neighborState, level, neighborPos)) {
                return true;
            }
            FaceMountedAttachmentBlock neighborBlock = (FaceMountedAttachmentBlock) neighborState.getBlock();
            if (neighborBlock.allowsAttachmentExtension()
                && neighborBlock.hasConnectedSupport(neighborState, level, neighborPos, visited)) {
                return true;
            }
        }

        return false;
    }

    protected boolean isCompatibleExtension(BlockState state, BlockState neighborState) {
        return neighborState.getBlock() == state.getBlock();
    }

    private static Direction[] extensionDirections() {
        return Direction.values();
    }

    private static boolean hasCollisionContactOnFace(BlockState supportState, BlockGetter level, BlockPos supportPos, Direction face) {
        VoxelShape shape = supportState.getCollisionShape(level, supportPos);
        if (shape.isEmpty()) {
            return false;
        }

        AABB bounds = shape.bounds();
        double epsilon = 1.0E-6;
        return switch (face) {
            case NORTH -> bounds.minZ <= epsilon;
            case SOUTH -> bounds.maxZ >= 1.0 - epsilon;
            case WEST -> bounds.minX <= epsilon;
            case EAST -> bounds.maxX >= 1.0 - epsilon;
            case DOWN -> bounds.minY <= epsilon;
            case UP -> bounds.maxY >= 1.0 - epsilon;
        };
    }

    @Override
    protected VoxelShape getShape(BlockState state, BlockGetter level, BlockPos pos, CollisionContext context) {
        return switch (state.getValue(FACING)) {
            case SOUTH -> southShape;
            case WEST -> westShape;
            case EAST -> eastShape;
            default -> northShape;
        };
    }

    @Override
    protected VoxelShape getCollisionShape(BlockState state, BlockGetter level, BlockPos pos, CollisionContext context) {
        return getShape(state, level, pos, context);
    }

    @Override
    protected boolean useShapeForLightOcclusion(BlockState state) {
        return true;
    }
}
