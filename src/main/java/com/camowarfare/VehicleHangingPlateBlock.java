package com.camowarfare;

import com.mojang.serialization.MapCodec;
import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.network.chat.Component;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.core.registries.BuiltInRegistries;
import net.minecraft.world.InteractionHand;
import net.minecraft.world.InteractionResult;
import net.minecraft.world.InteractionResultHolder;
import net.minecraft.world.ItemInteractionResult;
import net.minecraft.world.MenuProvider;
import net.minecraft.world.SimpleMenuProvider;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.item.BlockItem;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.level.BlockGetter;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.BarrelBlock;
import net.minecraft.world.level.block.ChestBlock;
import net.minecraft.world.level.block.EntityBlock;
import net.minecraft.world.level.block.ShulkerBoxBlock;
import net.minecraft.world.level.block.entity.BlockEntity;
import net.minecraft.world.level.block.state.BlockBehaviour;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.phys.BlockHitResult;
import net.minecraft.world.phys.Vec3;
import net.minecraft.world.phys.shapes.Shapes;
import net.minecraft.world.phys.shapes.VoxelShape;

public class VehicleHangingPlateBlock extends FaceMountedAttachmentBlock implements EntityBlock {
    public static final MapCodec<VehicleHangingPlateBlock> CODEC = simpleCodec(VehicleHangingPlateBlock::new);
    private static final VoxelShape SUPPORT_SHAPE = Shapes.block();
    private static final VoxelShape NORTH_PLATE_SHAPE = Block.box(0, 4, 12, 16, 12, 16);
    private static final VoxelShape SOUTH_PLATE_SHAPE = Block.box(0, 4, 0, 16, 12, 4);
    private static final VoxelShape WEST_PLATE_SHAPE = Block.box(12, 4, 0, 16, 12, 16);
    private static final VoxelShape EAST_PLATE_SHAPE = Block.box(0, 4, 0, 4, 12, 16);
    private static final VoxelShape NORTH_LEFT_MOUNT_SHAPE = Block.box(0, 3, 6, 8, 13, 14);
    private static final VoxelShape NORTH_RIGHT_MOUNT_SHAPE = Block.box(8, 3, 6, 16, 13, 14);
    private static final VoxelShape SOUTH_LEFT_MOUNT_SHAPE = Block.box(8, 3, 2, 16, 13, 10);
    private static final VoxelShape SOUTH_RIGHT_MOUNT_SHAPE = Block.box(0, 3, 2, 8, 13, 10);
    private static final VoxelShape WEST_LEFT_MOUNT_SHAPE = Block.box(6, 3, 8, 14, 13, 16);
    private static final VoxelShape WEST_RIGHT_MOUNT_SHAPE = Block.box(6, 3, 0, 14, 13, 8);
    private static final VoxelShape EAST_LEFT_MOUNT_SHAPE = Block.box(2, 3, 0, 10, 13, 8);
    private static final VoxelShape EAST_RIGHT_MOUNT_SHAPE = Block.box(2, 3, 8, 10, 13, 16);

    public VehicleHangingPlateBlock(BlockBehaviour.Properties properties) {
        super(
            properties,
            Block.box(0, 4, 12, 16, 11, 16),
            Block.box(0, 4, 0, 16, 11, 4),
            Block.box(12, 4, 0, 16, 11, 16),
            Block.box(0, 4, 0, 4, 11, 16)
        );
    }

    @Override
    protected MapCodec<? extends VehicleHangingPlateBlock> codec() {
        return CODEC;
    }

    @Override
    protected VoxelShape getBlockSupportShape(BlockState state, BlockGetter level, BlockPos pos) {
        return SUPPORT_SHAPE;
    }

    @Override
    public BlockEntity newBlockEntity(BlockPos pos, BlockState state) {
        return new VehicleHangingPlateBlockEntity(pos, state);
    }

    @Override
    protected VoxelShape getShape(BlockState state, BlockGetter level, BlockPos pos, net.minecraft.world.phys.shapes.CollisionContext context) {
        Direction facing = state.getValue(FACING);
        VoxelShape shape = plateShape(facing);
        if (level.getBlockEntity(pos) instanceof VehicleHangingPlateBlockEntity blockEntity) {
            if (blockEntity.hasMount(0)) {
                shape = Shapes.or(shape, mountShape(facing, MountSlot.LEFT));
            }
            if (blockEntity.hasMount(1)) {
                shape = Shapes.or(shape, mountShape(facing, MountSlot.RIGHT));
            }
        }
        return shape;
    }

    @Override
    protected VoxelShape getCollisionShape(BlockState state, BlockGetter level, BlockPos pos, net.minecraft.world.phys.shapes.CollisionContext context) {
        return getShape(state, level, pos, context);
    }

    @Override
    protected InteractionResult useWithoutItem(BlockState state, Level level, BlockPos pos, Player player, BlockHitResult hitResult) {
        if (!(level.getBlockEntity(pos) instanceof VehicleHangingPlateBlockEntity blockEntity)) {
            return InteractionResult.PASS;
        }

        MountSlot slot = MountSlot.fromHit(state.getValue(FACING), pos, hitResult.getLocation());
        if (!blockEntity.hasMount(slot.index())) {
            return InteractionResult.PASS;
        }
        if (player.isSecondaryUseActive()) {
            if (!level.isClientSide) {
                blockEntity.unmount(slot.index(), level, pos);
            }
            return InteractionResult.sidedSuccess(level.isClientSide);
        }
        if (!level.isClientSide) {
            if (!tryUseMountedItem(blockEntity, slot.index(), level, player)) {
                player.openMenu(menuProvider(blockEntity, slot.index()));
            }
        }
        return InteractionResult.sidedSuccess(level.isClientSide);
    }

    @Override
    protected ItemInteractionResult useItemOn(ItemStack stack, BlockState state, Level level, BlockPos pos, Player player, InteractionHand hand, BlockHitResult hitResult) {
        if (!isSupportedMountItem(stack) || !(level.getBlockEntity(pos) instanceof VehicleHangingPlateBlockEntity blockEntity)) {
            return ItemInteractionResult.PASS_TO_DEFAULT_BLOCK_INTERACTION;
        }

        MountSlot slot = MountSlot.fromHit(state.getValue(FACING), pos, hitResult.getLocation());
        if (blockEntity.hasMount(slot.index())) {
            return ItemInteractionResult.PASS_TO_DEFAULT_BLOCK_INTERACTION;
        }
        if (!level.isClientSide) {
            blockEntity.mount(slot.index(), stack);
            if (!player.getAbilities().instabuild) {
                stack.shrink(1);
            }
        }
        return ItemInteractionResult.sidedSuccess(level.isClientSide);
    }

    @Override
    protected void onRemove(BlockState state, Level level, BlockPos pos, BlockState newState, boolean movedByPiston) {
        if (!state.is(newState.getBlock()) && level.getBlockEntity(pos) instanceof VehicleHangingPlateBlockEntity blockEntity) {
            blockEntity.dropAll(level, pos);
        }
        super.onRemove(state, level, pos, newState, movedByPiston);
    }

    private static MenuProvider menuProvider(VehicleHangingPlateBlockEntity blockEntity, int slot) {
        Component title = blockEntity.displayName(slot);
        return new SimpleMenuProvider((containerId, inventory, player) -> blockEntity.createMenu(slot, containerId, inventory), title);
    }

    private static boolean isSupportedMountItem(ItemStack stack) {
        ResourceLocation itemId = BuiltInRegistries.ITEM.getKey(stack.getItem());
        if (isSophisticatedBackpack(itemId) || isCreateBigCannonsAmmoContainer(itemId)) {
            return true;
        }

        if (!(stack.getItem() instanceof BlockItem blockItem)) {
            return false;
        }

        Block block = blockItem.getBlock();
        if (block instanceof ChestBlock || block instanceof BarrelBlock || block instanceof ShulkerBoxBlock) {
            return true;
        }

        ResourceLocation id = BuiltInRegistries.BLOCK.getKey(block);
        String path = id.getPath();
        return path.contains("chest")
            || path.contains("barrel")
            || path.contains("shulker")
            || path.contains("backpack")
            || path.contains("toolbox")
            || path.contains("crate")
            || path.contains("storage");
    }

    private static boolean tryUseMountedItem(VehicleHangingPlateBlockEntity blockEntity, int slot, Level level, Player player) {
        ItemStack mountedStack = blockEntity.mount(slot);
        ResourceLocation itemId = BuiltInRegistries.ITEM.getKey(mountedStack.getItem());
        if (isSophisticatedBackpack(itemId)) {
            return SophisticatedBackpacksCompat.openBackpack(player, blockEntity, slot);
        }
        if (!isCreateBigCannonsAmmoContainer(itemId)) {
            return false;
        }

        InteractionHand hand = InteractionHand.MAIN_HAND;
        ItemStack originalHandStack = player.getItemInHand(hand);
        player.setItemInHand(hand, mountedStack);
        InteractionResultHolder<ItemStack> result = mountedStack.getItem().use(level, player, hand);
        ItemStack updatedStack = result.getObject().isEmpty() ? player.getItemInHand(hand) : result.getObject();
        if (updatedStack == mountedStack) {
            blockEntity.markMountedStackChanged();
        } else {
            blockEntity.setMountedStack(slot, updatedStack);
        }
        player.setItemInHand(hand, originalHandStack);
        return result.getResult().consumesAction();
    }

    private static boolean isSophisticatedBackpack(ResourceLocation itemId) {
        String path = itemId.getPath();
        return itemId.getNamespace().equals("sophisticatedbackpacks")
            && (path.equals("backpack") || path.endsWith("_backpack"));
    }

    private static boolean isCreateBigCannonsAmmoContainer(ResourceLocation itemId) {
        return itemId.getNamespace().equals("createbigcannons")
            && (itemId.getPath().equals("autocannon_ammo_container")
                || itemId.getPath().equals("creative_autocannon_ammo_container")
                || itemId.getPath().contains("ammo_container"));
    }

    private static VoxelShape plateShape(Direction facing) {
        return switch (facing) {
            case SOUTH -> SOUTH_PLATE_SHAPE;
            case WEST -> WEST_PLATE_SHAPE;
            case EAST -> EAST_PLATE_SHAPE;
            default -> NORTH_PLATE_SHAPE;
        };
    }

    private static VoxelShape mountShape(Direction facing, MountSlot slot) {
        return switch (facing) {
            case SOUTH -> slot == MountSlot.LEFT ? SOUTH_LEFT_MOUNT_SHAPE : SOUTH_RIGHT_MOUNT_SHAPE;
            case WEST -> slot == MountSlot.LEFT ? WEST_LEFT_MOUNT_SHAPE : WEST_RIGHT_MOUNT_SHAPE;
            case EAST -> slot == MountSlot.LEFT ? EAST_LEFT_MOUNT_SHAPE : EAST_RIGHT_MOUNT_SHAPE;
            default -> slot == MountSlot.LEFT ? NORTH_LEFT_MOUNT_SHAPE : NORTH_RIGHT_MOUNT_SHAPE;
        };
    }

    private enum MountSlot {
        LEFT,
        RIGHT;

        private static MountSlot fromHit(Direction facing, BlockPos pos, Vec3 location) {
            double localX = location.x - pos.getX();
            double localZ = location.z - pos.getZ();
            return switch (facing) {
                case NORTH -> localX < 0.5 ? LEFT : RIGHT;
                case SOUTH -> localX > 0.5 ? LEFT : RIGHT;
                case WEST -> localZ > 0.5 ? LEFT : RIGHT;
                case EAST -> localZ < 0.5 ? LEFT : RIGHT;
                default -> RIGHT;
            };
        }

        private Direction offset(Direction facing) {
            return this == LEFT ? leftOf(facing) : leftOf(facing).getOpposite();
        }

        private int index() {
            return this == LEFT ? 0 : 1;
        }

        private static Direction leftOf(Direction facing) {
            return switch (facing) {
                case NORTH -> Direction.WEST;
                case SOUTH -> Direction.EAST;
                case WEST -> Direction.SOUTH;
                case EAST -> Direction.NORTH;
                default -> Direction.WEST;
            };
        }
    }
}
