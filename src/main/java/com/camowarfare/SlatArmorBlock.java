package com.camowarfare;

import com.mojang.serialization.MapCodec;
import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.world.item.context.BlockPlaceContext;
import net.minecraft.world.level.BlockGetter;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.LevelAccessor;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.LevelReader;
import net.minecraft.world.level.block.state.BlockBehaviour;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.block.state.StateDefinition;
import net.minecraft.world.level.block.state.properties.BlockStateProperties;
import net.minecraft.world.level.block.state.properties.BooleanProperty;
import net.minecraft.world.level.block.state.properties.EnumProperty;
import net.minecraft.world.level.block.state.properties.Half;
import net.minecraft.world.phys.shapes.CollisionContext;
import net.minecraft.world.phys.shapes.Shapes;
import net.minecraft.world.phys.shapes.VoxelShape;

public class SlatArmorBlock extends FaceMountedAttachmentBlock {
    public static final MapCodec<SlatArmorBlock> CODEC = simpleCodec(SlatArmorBlock::new);
    public static final BooleanProperty UP = BooleanProperty.create("up");
    public static final BooleanProperty DOWN = BooleanProperty.create("down");
    public static final BooleanProperty LEFT = BooleanProperty.create("left");
    public static final BooleanProperty RIGHT = BooleanProperty.create("right");
    public static final BooleanProperty SLOPED = BooleanProperty.create("sloped");
    public static final EnumProperty<Half> HALF = BlockStateProperties.HALF;

    private static final VoxelShape BOTTOM_NORTH_SLOPED_SHAPE = slopedSlatShape(Half.BOTTOM, Direction.NORTH);
    private static final VoxelShape BOTTOM_SOUTH_SLOPED_SHAPE = slopedSlatShape(Half.BOTTOM, Direction.SOUTH);
    private static final VoxelShape BOTTOM_WEST_SLOPED_SHAPE = slopedSlatShape(Half.BOTTOM, Direction.WEST);
    private static final VoxelShape BOTTOM_EAST_SLOPED_SHAPE = slopedSlatShape(Half.BOTTOM, Direction.EAST);
    private static final VoxelShape TOP_NORTH_SLOPED_SHAPE = slopedSlatShape(Half.TOP, Direction.NORTH);
    private static final VoxelShape TOP_SOUTH_SLOPED_SHAPE = slopedSlatShape(Half.TOP, Direction.SOUTH);
    private static final VoxelShape TOP_WEST_SLOPED_SHAPE = slopedSlatShape(Half.TOP, Direction.WEST);
    private static final VoxelShape TOP_EAST_SLOPED_SHAPE = slopedSlatShape(Half.TOP, Direction.EAST);

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
            .setValue(RIGHT, false)
            .setValue(SLOPED, false)
            .setValue(HALF, Half.BOTTOM));
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
        builder.add(UP, DOWN, LEFT, RIGHT, SLOPED, HALF);
    }

    @Override
    public BlockState getStateForPlacement(BlockPlaceContext context) {
        CopycatSurfaceSupport support = CopycatSurfaceSupport.findForPlacement(context);
        if (support != null) {
            return updateConnections(this.defaultBlockState()
                .setValue(SLOPED, true)
                .setValue(FACING, support.facing())
                .setValue(HALF, support.half()), context.getLevel(), context.getClickedPos());
        }

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

    @Override
    protected void onPlace(BlockState state, Level level, BlockPos pos, BlockState oldState, boolean movedByPiston) {
        super.onPlace(state, level, pos, oldState, movedByPiston);
        if (oldState.getBlock() != state.getBlock()) {
            refreshNearbyConnections(level, pos);
        }
    }

    @Override
    protected void onRemove(BlockState state, Level level, BlockPos pos, BlockState newState, boolean movedByPiston) {
        super.onRemove(state, level, pos, newState, movedByPiston);
        if (newState.getBlock() != state.getBlock()) {
            refreshNearbyConnections(level, pos);
        }
    }

    private BlockState updateConnections(BlockState state, BlockGetter level, BlockPos pos) {
        Direction facing = state.getValue(FACING);
        Direction left = leftOf(facing);
        Direction right = left.getOpposite();
        if (state.getValue(SLOPED)) {
            return state
                .setValue(UP, connectsAlongSlope(state, level, pos, facing.getOpposite()))
                .setValue(DOWN, connectsAlongSlope(state, level, pos, facing))
                .setValue(LEFT, connectsTo(state, level.getBlockState(pos.relative(left))))
                .setValue(RIGHT, connectsTo(state, level.getBlockState(pos.relative(right))));
        }

        return state
            .setValue(UP, connectsTo(state, level.getBlockState(pos.above())))
            .setValue(DOWN, connectsTo(state, level.getBlockState(pos.below())))
            .setValue(LEFT, connectsTo(state, level.getBlockState(pos.relative(left))))
            .setValue(RIGHT, connectsTo(state, level.getBlockState(pos.relative(right))));
    }

    private void refreshNearbyConnections(Level level, BlockPos pos) {
        if (level.isClientSide) {
            return;
        }

        for (int dx = -1; dx <= 1; dx++) {
            for (int dy = -1; dy <= 1; dy++) {
                for (int dz = -1; dz <= 1; dz++) {
                    BlockPos targetPos = pos.offset(dx, dy, dz);
                    BlockState targetState = level.getBlockState(targetPos);
                    if (!(targetState.getBlock() instanceof SlatArmorBlock)) {
                        continue;
                    }

                    BlockState updatedState = updateConnections(targetState, level, targetPos);
                    if (updatedState != targetState) {
                        level.setBlock(targetPos, updatedState, 3);
                    }
                }
            }
        }
    }

    private static boolean connectsAlongSlope(BlockState state, BlockGetter level, BlockPos pos, Direction direction) {
        BlockPos straight = pos.relative(direction);
        return connectsTo(state, level.getBlockState(straight))
            || connectsTo(state, level.getBlockState(straight.above()))
            || connectsTo(state, level.getBlockState(straight.below()));
    }

    private static boolean connectsTo(BlockState state, BlockState neighborState) {
        return neighborState.getBlock() instanceof SlatArmorBlock
            && neighborState.getValue(FACING) == state.getValue(FACING)
            && neighborState.getValue(SLOPED) == state.getValue(SLOPED)
            && neighborState.getValue(HALF) == state.getValue(HALF);
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

    private static VoxelShape slatCollisionShape(BoxFactory box) {
        return Shapes.or(
            box.create(3.45, 2.0, 10.95, 3.55, 14.0, 11.15),
            box.create(6.45, 2.0, 10.95, 6.55, 14.0, 11.15),
            box.create(9.45, 2.0, 10.95, 9.55, 14.0, 11.15),
            box.create(12.45, 2.0, 10.95, 12.55, 14.0, 11.15)
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
        if (state.getValue(SLOPED)) {
            Direction facing = state.getValue(FACING);
            Half half = state.getValue(HALF);
            VoxelShape shape = slopedShapeFor(facing, half);
            if (state.getValue(LEFT)) {
                shape = Shapes.or(shape, slopedLeftConnectionShape(half, facing));
            }
            if (state.getValue(RIGHT)) {
                shape = Shapes.or(shape, slopedRightConnectionShape(half, facing));
            }
            if (state.getValue(UP)) {
                shape = Shapes.or(shape, slopedUpConnectionShape(half, facing));
            }
            if (state.getValue(DOWN)) {
                shape = Shapes.or(shape, slopedDownConnectionShape(half, facing));
            }
            return shape;
        }

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
        if (state.getValue(SLOPED)) {
            return getShape(state, level, pos, context);
        }
        return slatCollisionShape(boxFactoryFor(state.getValue(FACING)));
    }

    private static VoxelShape slopedShapeFor(Direction facing, Half half) {
        if (half == Half.TOP) {
            return switch (facing) {
                case SOUTH -> TOP_SOUTH_SLOPED_SHAPE;
                case WEST -> TOP_WEST_SLOPED_SHAPE;
                case EAST -> TOP_EAST_SLOPED_SHAPE;
                default -> TOP_NORTH_SLOPED_SHAPE;
            };
        }
        return switch (facing) {
            case SOUTH -> BOTTOM_SOUTH_SLOPED_SHAPE;
            case WEST -> BOTTOM_WEST_SLOPED_SHAPE;
            case EAST -> BOTTOM_EAST_SLOPED_SHAPE;
            default -> BOTTOM_NORTH_SLOPED_SHAPE;
        };
    }

    private static VoxelShape slopedSlatShape(Half half, Direction facing) {
        VoxelShape shape = Shapes.empty();
        shape = addSlopedLongBox(shape, half, facing, 0, 0.45, 5.2, 16, 1.95, 18.6, 4);
        return shape;
    }

    private static VoxelShape slopedUpConnectionShape(Half half, Direction facing) {
        VoxelShape shape = Shapes.empty();
        shape = addSlopedLongBox(shape, half, facing, 0, 0.45, 18.35, 16, 1.95, 28.9, 2);
        return shape;
    }

    private static VoxelShape slopedDownConnectionShape(Half half, Direction facing) {
        VoxelShape shape = Shapes.empty();
        shape = addSlopedLongBox(shape, half, facing, 0, 0.45, -7.2, 16, 1.95, 5.45, 2);
        return shape;
    }

    private static VoxelShape slopedLeftConnectionShape(Half half, Direction facing) {
        VoxelShape shape = Shapes.empty();
        shape = addSlopedLongBox(shape, half, facing, -2.5, 0.45, 7.55, 0.1, 1.25, 15.4, 2);
        return shape;
    }

    private static VoxelShape slopedRightConnectionShape(Half half, Direction facing) {
        VoxelShape shape = Shapes.empty();
        shape = addSlopedLongBox(shape, half, facing, 15.9, 0.45, 7.55, 18.5, 1.25, 15.4, 2);
        return shape;
    }

    private static VoxelShape addSlopedLongBox(
        VoxelShape shape,
        Half half,
        Direction facing,
        double minX,
        double minY,
        double minZ,
        double maxX,
        double maxY,
        double maxZ,
        int segments
    ) {
        double length = maxZ - minZ;
        for (int i = 0; i < segments; i++) {
            double z0 = minZ + length * i / segments;
            double z1 = minZ + length * (i + 1) / segments;
            shape = Shapes.or(shape, slopedLocalBox(half, facing, minX, minY, z0, maxX, maxY, z1));
        }
        return shape;
    }

    private static VoxelShape slopedLocalBox(
        Half half,
        Direction facing,
        double minX,
        double minY,
        double minZ,
        double maxX,
        double maxY,
        double maxZ
    ) {
        double originY = half == Half.TOP ? 16.0 : 0.0;
        double angle = half == Half.TOP ? -45.0 : 45.0;
        double radians = Math.toRadians(angle);
        double cos = Math.cos(radians);
        double sin = Math.sin(radians);
        double[] bounds = { Double.POSITIVE_INFINITY, Double.POSITIVE_INFINITY, Double.POSITIVE_INFINITY,
            Double.NEGATIVE_INFINITY, Double.NEGATIVE_INFINITY, Double.NEGATIVE_INFINITY };

        for (double x : new double[] { minX, maxX }) {
            for (double y : new double[] { minY, maxY }) {
                for (double z : new double[] { minZ, maxZ }) {
                    double localY = y - originY;
                    double rotatedY = originY + localY * cos - z * sin;
                    double rotatedZ = localY * sin + z * cos;
                    bounds[0] = Math.min(bounds[0], x);
                    bounds[1] = Math.min(bounds[1], rotatedY);
                    bounds[2] = Math.min(bounds[2], rotatedZ);
                    bounds[3] = Math.max(bounds[3], x);
                    bounds[4] = Math.max(bounds[4], rotatedY);
                    bounds[5] = Math.max(bounds[5], rotatedZ);
                }
            }
        }

        return rotatedBox(facing, bounds[0], bounds[1], bounds[2], bounds[3], bounds[4], bounds[5]);
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

    private static VoxelShape rotatedBox(Direction facing, double minX, double minY, double minZ, double maxX, double maxY, double maxZ) {
        return switch (facing) {
            case SOUTH -> Block.box(16.0 - maxX, minY, 16.0 - maxZ, 16.0 - minX, maxY, 16.0 - minZ);
            case WEST -> Block.box(minZ, minY, 16.0 - maxX, maxZ, maxY, 16.0 - minX);
            case EAST -> Block.box(16.0 - maxZ, minY, minX, 16.0 - minZ, maxY, maxX);
            default -> Block.box(minX, minY, minZ, maxX, maxY, maxZ);
        };
    }

    @FunctionalInterface
    private interface BoxFactory {
        VoxelShape create(double minX, double minY, double minZ, double maxX, double maxY, double maxZ);
    }
}
