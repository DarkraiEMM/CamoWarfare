package com.camowarfare;

import com.mojang.serialization.MapCodec;
import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.world.item.context.BlockPlaceContext;
import net.minecraft.world.level.BlockGetter;
import net.minecraft.world.level.LevelReader;
import net.minecraft.world.level.block.Block;
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

public class AddOnArmorPlateBlock extends FaceMountedAttachmentBlock {
    public static final MapCodec<AddOnArmorPlateBlock> CODEC = simpleCodec(AddOnArmorPlateBlock::new);
    public static final BooleanProperty SLOPED = BooleanProperty.create("sloped");
    public static final EnumProperty<Half> HALF = BlockStateProperties.HALF;

    private static final VoxelShape BOTTOM_NORTH_SHAPE = slopedShape(Half.BOTTOM, Direction.NORTH);
    private static final VoxelShape BOTTOM_SOUTH_SHAPE = slopedShape(Half.BOTTOM, Direction.SOUTH);
    private static final VoxelShape BOTTOM_WEST_SHAPE = slopedShape(Half.BOTTOM, Direction.WEST);
    private static final VoxelShape BOTTOM_EAST_SHAPE = slopedShape(Half.BOTTOM, Direction.EAST);
    private static final VoxelShape TOP_NORTH_SHAPE = slopedShape(Half.TOP, Direction.NORTH);
    private static final VoxelShape TOP_SOUTH_SHAPE = slopedShape(Half.TOP, Direction.SOUTH);
    private static final VoxelShape TOP_WEST_SHAPE = slopedShape(Half.TOP, Direction.WEST);
    private static final VoxelShape TOP_EAST_SHAPE = slopedShape(Half.TOP, Direction.EAST);
    private static final double SLOPED_CLEARANCE = 0.75;

    public AddOnArmorPlateBlock(BlockBehaviour.Properties properties) {
        super(
            properties,
            Block.box(1, 3, 13, 15, 13, 16),
            Block.box(1, 3, 0, 15, 13, 3),
            Block.box(13, 3, 1, 16, 13, 15),
            Block.box(0, 3, 1, 3, 13, 15)
        );
        this.registerDefaultState(this.defaultBlockState()
            .setValue(SLOPED, false)
            .setValue(HALF, Half.BOTTOM));
    }

    @Override
    protected MapCodec<? extends AddOnArmorPlateBlock> codec() {
        return CODEC;
    }

    @Override
    protected void createBlockStateDefinition(StateDefinition.Builder<Block, BlockState> builder) {
        super.createBlockStateDefinition(builder);
        builder.add(SLOPED, HALF);
    }

    @Override
    public BlockState getStateForPlacement(BlockPlaceContext context) {
        CopycatSurfaceSupport support = CopycatSurfaceSupport.findForPlacement(context);
        if (support != null) {
            return this.defaultBlockState()
                .setValue(SLOPED, true)
                .setValue(FACING, support.facing())
                .setValue(HALF, support.half());
        }
        return super.getStateForPlacement(context);
    }

    @Override
    public boolean canSurvive(BlockState state, LevelReader level, BlockPos pos) {
        if (!state.getValue(SLOPED)) {
            return super.canSurvive(state, level, pos);
        }

        BlockPos supportPos = state.getValue(HALF) == Half.TOP ? pos.above() : pos.below();
        CopycatSurfaceSupport support = CopycatSurfaceSupport.read(level.getBlockState(supportPos));
        if (matchesSupport(state, support)) {
            return true;
        }

        return findAdjacentSupport(level, pos, state.getValue(FACING), state.getValue(HALF)) != null;
    }

    @Override
    protected VoxelShape getShape(BlockState state, BlockGetter level, BlockPos pos, CollisionContext context) {
        if (!state.getValue(SLOPED)) {
            return super.getShape(state, level, pos, context);
        }
        return shapeFor(state.getValue(FACING), state.getValue(HALF));
    }

    @Override
    protected VoxelShape getCollisionShape(BlockState state, BlockGetter level, BlockPos pos, CollisionContext context) {
        if (!state.getValue(SLOPED)) {
            return super.getCollisionShape(state, level, pos, context);
        }
        return getShape(state, level, pos, context);
    }

    private static CopycatSurfaceSupport findAdjacentSupport(LevelReader level, BlockPos pos, Direction facing, Half half) {
        CopycatSurfaceSupport below = CopycatSurfaceSupport.read(level.getBlockState(pos.below()));
        if (below != null && below.half() == Half.BOTTOM && matchesSupport(below, facing, half)) {
            return below;
        }

        CopycatSurfaceSupport above = CopycatSurfaceSupport.read(level.getBlockState(pos.above()));
        if (above != null && above.half() == Half.TOP && matchesSupport(above, facing, half)) {
            return above;
        }

        return null;
    }

    private static boolean matchesSupport(BlockState state, CopycatSurfaceSupport support) {
        return support != null
            && support.matches(state.getValue(FACING), state.getValue(HALF));
    }

    private static boolean matchesSupport(CopycatSurfaceSupport support, Direction facing, Half half) {
        return (facing == null || support.facing() == facing)
            && (half == null || support.half() == half);
    }

    private static VoxelShape shapeFor(Direction facing, Half half) {
        if (half == Half.TOP) {
            return switch (facing) {
                case SOUTH -> TOP_SOUTH_SHAPE;
                case WEST -> TOP_WEST_SHAPE;
                case EAST -> TOP_EAST_SHAPE;
                default -> TOP_NORTH_SHAPE;
            };
        }
        return switch (facing) {
            case SOUTH -> BOTTOM_SOUTH_SHAPE;
            case WEST -> BOTTOM_WEST_SHAPE;
            case EAST -> BOTTOM_EAST_SHAPE;
            default -> BOTTOM_NORTH_SHAPE;
        };
    }

    private static VoxelShape slopedShape(Half half, Direction facing) {
        VoxelShape shape = Shapes.empty();
        for (int i = 0; i < 8; i++) {
            double minZ = i * 2.0;
            double maxZ = minZ + 2.0;
            double minY;
            double maxY;
            if (half == Half.TOP) {
                minY = 13.5 - SLOPED_CLEARANCE + i * 2.0;
                maxY = minY + 3.0;
            } else {
                maxY = 1.5 + SLOPED_CLEARANCE - i * 2.0;
                minY = maxY - 3.0;
            }
            shape = Shapes.or(shape, rotatedBox(facing, 0.75, minY, minZ, 15.25, maxY, maxZ));
        }
        return shape;
    }

    private static VoxelShape rotatedBox(Direction facing, double minX, double minY, double minZ, double maxX, double maxY, double maxZ) {
        return switch (facing) {
            case SOUTH -> Block.box(16.0 - maxX, minY, 16.0 - maxZ, 16.0 - minX, maxY, 16.0 - minZ);
            case WEST -> Block.box(minZ, minY, 16.0 - maxX, maxZ, maxY, 16.0 - minX);
            case EAST -> Block.box(16.0 - maxZ, minY, minX, 16.0 - minZ, maxY, maxX);
            default -> Block.box(minX, minY, minZ, maxX, maxY, maxZ);
        };
    }
}
