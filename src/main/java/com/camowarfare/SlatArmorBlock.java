package com.camowarfare;

import com.mojang.serialization.MapCodec;
import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.world.item.context.BlockPlaceContext;
import net.minecraft.world.level.BlockGetter;
import net.minecraft.world.level.LevelAccessor;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.LevelReader;
import net.minecraft.world.level.block.state.BlockBehaviour;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.block.state.StateDefinition;
import net.minecraft.world.level.block.state.properties.BooleanProperty;
import net.minecraft.world.phys.shapes.CollisionContext;
import net.minecraft.world.phys.shapes.Shapes;
import net.minecraft.world.phys.shapes.VoxelShape;

public class SlatArmorBlock extends FaceMountedAttachmentBlock {
    public static final MapCodec<SlatArmorBlock> CODEC = simpleCodec(SlatArmorBlock::new);
    public static final BooleanProperty UP = BooleanProperty.create("up");
    public static final BooleanProperty DOWN = BooleanProperty.create("down");
    public static final BooleanProperty LEFT = BooleanProperty.create("left");
    public static final BooleanProperty RIGHT = BooleanProperty.create("right");

    public SlatArmorBlock(BlockBehaviour.Properties properties) {
        super(
            properties,
            northShape(),
            southShape(),
            westShape(),
            eastShape()
        );
        this.registerDefaultState(this.defaultBlockState()
            .setValue(UP, false)
            .setValue(DOWN, false)
            .setValue(LEFT, false)
            .setValue(RIGHT, false));
    }

    @Override
    protected MapCodec<? extends SlatArmorBlock> codec() {
        return CODEC;
    }

    @Override
    protected boolean allowsAttachmentExtension() {
        return true;
    }

    @Override
    public boolean canSurvive(BlockState state, LevelReader level, BlockPos pos) {
        return true;
    }

    @Override
    protected void createBlockStateDefinition(StateDefinition.Builder<Block, BlockState> builder) {
        super.createBlockStateDefinition(builder);
        builder.add(UP, DOWN, LEFT, RIGHT);
    }

    @Override
    public BlockState getStateForPlacement(BlockPlaceContext context) {
        BlockState state = super.getStateForPlacement(context);
        if (state == null) {
            return null;
        }
        return updateConnections(state, context.getLevel(), context.getClickedPos());
    }

    @Override
    protected BlockState updateShape(BlockState state, Direction direction, BlockState neighborState, LevelAccessor level, BlockPos currentPos, BlockPos neighborPos) {
        return updateConnections(state, level, currentPos);
    }

    private BlockState updateConnections(BlockState state, BlockGetter level, BlockPos pos) {
        Direction facing = state.getValue(FACING);
        Direction left = leftOf(facing);
        Direction right = left.getOpposite();
        return state
            .setValue(UP, connectsTo(state, level.getBlockState(pos.above())))
            .setValue(DOWN, connectsTo(state, level.getBlockState(pos.below())))
            .setValue(LEFT, connectsTo(state, level.getBlockState(pos.relative(left))))
            .setValue(RIGHT, connectsTo(state, level.getBlockState(pos.relative(right))));
    }

    private static boolean connectsTo(BlockState state, BlockState neighborState) {
        return neighborState.getBlock() instanceof SlatArmorBlock
            && neighborState.getValue(FACING) == state.getValue(FACING);
    }

    private static Direction leftOf(Direction facing) {
        return switch (facing) {
            case NORTH -> Direction.EAST;
            case SOUTH -> Direction.WEST;
            case WEST -> Direction.NORTH;
            case EAST -> Direction.SOUTH;
            default -> Direction.EAST;
        };
    }

    private static VoxelShape northShape() {
        return slatShape(Block::box);
    }

    private static VoxelShape southShape() {
        return slatShape(SlatArmorBlock::southBox);
    }

    private static VoxelShape westShape() {
        return slatShape(SlatArmorBlock::westBox);
    }

    private static VoxelShape eastShape() {
        return slatShape(SlatArmorBlock::eastBox);
    }

    private static VoxelShape slatShape(BoxFactory box) {
        return Shapes.or(
            box.create(0, 1, 11.2, 1, 15, 12.2),
            box.create(15, 1, 11.2, 16, 15, 12.2),
            box.create(3.3, 1.2, 10.8, 3.7, 14.8, 11.4),
            box.create(6.3, 1.2, 10.8, 6.7, 14.8, 11.4),
            box.create(9.3, 1.2, 10.8, 9.7, 14.8, 11.4),
            box.create(12.3, 1.2, 10.8, 12.7, 14.8, 11.4),
            box.create(1, 11.2, 10.5, 15, 11.6, 11.2),
            box.create(1, 8.45, 10.5, 15, 8.85, 11.2),
            box.create(1, 5.7, 10.5, 15, 6.1, 11.2),
            box.create(1, 2.95, 10.5, 15, 3.35, 11.2)
        );
    }

    private static VoxelShape leftConnectionShape(BoxFactory box) {
        return Shapes.or(
            box.create(0, 3.1, 12, 1, 3.55, 16),
            box.create(0, 8.55, 12, 1, 9, 16),
            box.create(0, 13.45, 12, 1, 13.9, 16)
        );
    }

    private static VoxelShape rightConnectionShape(BoxFactory box) {
        return Shapes.or(
            box.create(15, 3.1, 12, 16, 3.55, 16),
            box.create(15, 8.55, 12, 16, 9, 16),
            box.create(15, 13.45, 12, 16, 13.9, 16)
        );
    }

    private static VoxelShape upConnectionShape(BoxFactory box) {
        return Shapes.or(
            box.create(1.2, 15.25, 10.55, 14.8, 15.55, 11.05),
            box.create(0, 15, 11.2, 1, 16, 12.2),
            box.create(3.3, 14.8, 10.8, 3.7, 16, 11.4),
            box.create(6.3, 14.8, 10.8, 6.7, 16, 11.4),
            box.create(9.3, 14.8, 10.8, 9.7, 16, 11.4),
            box.create(12.3, 14.8, 10.8, 12.7, 16, 11.4),
            box.create(15, 15, 11.2, 16, 16, 12.2)
        );
    }

    private static VoxelShape downConnectionShape(BoxFactory box) {
        return Shapes.or(
            box.create(1.2, 0.45, 10.55, 14.8, 0.75, 11.05),
            box.create(0, 0, 11.2, 1, 1, 12.2),
            box.create(3.3, 0, 10.8, 3.7, 1.2, 11.4),
            box.create(6.3, 0, 10.8, 6.7, 1.2, 11.4),
            box.create(9.3, 0, 10.8, 9.7, 1.2, 11.4),
            box.create(12.3, 0, 10.8, 12.7, 1.2, 11.4),
            box.create(15, 0, 11.2, 16, 1, 12.2)
        );
    }

    @Override
    protected VoxelShape getShape(BlockState state, BlockGetter level, BlockPos pos, CollisionContext context) {
        BoxFactory box = boxFactoryFor(state.getValue(FACING));
        VoxelShape shape = slatShape(box);
        if (state.getValue(LEFT)) {
            shape = Shapes.or(shape, leftConnectionShape(box));
        }
        if (state.getValue(RIGHT)) {
            shape = Shapes.or(shape, rightConnectionShape(box));
        }
        if (state.getValue(UP)) {
            shape = Shapes.or(shape, upConnectionShape(box));
        }
        if (state.getValue(DOWN)) {
            shape = Shapes.or(shape, downConnectionShape(box));
        }
        return shape;
    }

    @Override
    protected VoxelShape getCollisionShape(BlockState state, BlockGetter level, BlockPos pos, CollisionContext context) {
        return getShape(state, level, pos, context);
    }

    private static BoxFactory boxFactoryFor(Direction facing) {
        return switch (facing) {
            case SOUTH -> SlatArmorBlock::southBox;
            case WEST -> SlatArmorBlock::westBox;
            case EAST -> SlatArmorBlock::eastBox;
            default -> Block::box;
        };
    }

    private static VoxelShape southBox(double minX, double minY, double minZ, double maxX, double maxY, double maxZ) {
        return Block.box(16 - maxX, minY, 16 - maxZ, 16 - minX, maxY, 16 - minZ);
    }

    private static VoxelShape westBox(double minX, double minY, double minZ, double maxX, double maxY, double maxZ) {
        return Block.box(minZ, minY, 16 - maxX, maxZ, maxY, 16 - minX);
    }

    private static VoxelShape eastBox(double minX, double minY, double minZ, double maxX, double maxY, double maxZ) {
        return Block.box(16 - maxZ, minY, minX, 16 - minZ, maxY, maxX);
    }

    @FunctionalInterface
    private interface BoxFactory {
        VoxelShape create(double minX, double minY, double minZ, double maxX, double maxY, double maxZ);
    }
}
