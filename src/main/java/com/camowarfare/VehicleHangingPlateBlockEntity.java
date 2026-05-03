package com.camowarfare;

import net.minecraft.core.BlockPos;
import net.minecraft.core.HolderLookup;
import net.minecraft.core.NonNullList;
import net.minecraft.nbt.CompoundTag;
import net.minecraft.network.protocol.Packet;
import net.minecraft.network.protocol.game.ClientGamePacketListener;
import net.minecraft.network.protocol.game.ClientboundBlockEntityDataPacket;
import net.minecraft.network.chat.Component;
import net.minecraft.world.ContainerHelper;
import net.minecraft.world.SimpleContainer;
import net.minecraft.world.entity.player.Inventory;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.inventory.AbstractContainerMenu;
import net.minecraft.world.inventory.ChestMenu;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.entity.BlockEntity;
import net.minecraft.world.level.block.state.BlockState;

public class VehicleHangingPlateBlockEntity extends BlockEntity {
    private static final int CONTAINER_SIZE = 27;
    private final ItemStack[] mounts = {ItemStack.EMPTY, ItemStack.EMPTY};
    private final NonNullList<ItemStack>[] contents = new NonNullList[] {
        NonNullList.withSize(CONTAINER_SIZE, ItemStack.EMPTY),
        NonNullList.withSize(CONTAINER_SIZE, ItemStack.EMPTY)
    };

    public VehicleHangingPlateBlockEntity(BlockPos pos, BlockState blockState) {
        super(CamoWarfare.VEHICLE_HANGING_PLATE_BLOCK_ENTITY.get(), pos, blockState);
    }

    @Override
    public void onLoad() {
        super.onLoad();
        if (this.level != null && !this.level.isClientSide) {
            BlockState state = this.getBlockState();
            this.level.sendBlockUpdated(this.worldPosition, state, state, 3);
        }
    }

    public ItemStack mount(int slot) {
        return this.mounts[slot];
    }

    public boolean hasMount(int slot) {
        return !this.mounts[slot].isEmpty();
    }

    public void mount(int slot, ItemStack stack) {
        this.mounts[slot] = stack.copyWithCount(1);
        this.setChangedAndSync();
    }

    public void setMountedStack(int slot, ItemStack stack) {
        this.mounts[slot] = stack.isEmpty() ? ItemStack.EMPTY : stack.copyWithCount(1);
        this.setChangedAndSync();
    }

    public void markMountedStackChanged() {
        this.setChangedAndSync();
    }

    public void unmount(int slot, Level level, BlockPos pos) {
        if (this.mounts[slot].isEmpty()) {
            return;
        }
        popStack(level, pos, this.mounts[slot]);
        this.mounts[slot] = ItemStack.EMPTY;
        for (ItemStack stack : this.contents[slot]) {
            popStack(level, pos, stack);
        }
        this.contents[slot] = NonNullList.withSize(CONTAINER_SIZE, ItemStack.EMPTY);
        this.setChangedAndSync();
    }

    public void dropAll(Level level, BlockPos pos) {
        for (int slot = 0; slot < this.mounts.length; slot++) {
            this.unmount(slot, level, pos);
        }
    }

    public AbstractContainerMenu createMenu(int slot, int containerId, Inventory inventory) {
        return ChestMenu.threeRows(containerId, inventory, new MountedContainer(slot));
    }

    public Component displayName(int slot) {
        return Component.translatable(slot == 0 ? "container.camowarfare.vehicle_hanging_plate_left" : "container.camowarfare.vehicle_hanging_plate_right");
    }

    private static void popStack(Level level, BlockPos pos, ItemStack stack) {
        if (!stack.isEmpty()) {
            net.minecraft.world.Containers.dropItemStack(level, pos.getX() + 0.5, pos.getY() + 0.5, pos.getZ() + 0.5, stack);
        }
    }

    private void setChangedAndSync() {
        this.setChanged();
        if (this.level != null) {
            BlockState state = this.getBlockState();
            this.level.sendBlockUpdated(this.worldPosition, state, state, 3);
        }
    }

    @Override
    protected void saveAdditional(CompoundTag tag, HolderLookup.Provider registries) {
        super.saveAdditional(tag, registries);
        for (int slot = 0; slot < 2; slot++) {
            if (!this.mounts[slot].isEmpty()) {
                tag.put("Mount" + slot, this.mounts[slot].save(registries, new CompoundTag()));
            }
            CompoundTag items = new CompoundTag();
            ContainerHelper.saveAllItems(items, this.contents[slot], registries);
            tag.put("Items" + slot, items);
        }
    }

    @Override
    protected void loadAdditional(CompoundTag tag, HolderLookup.Provider registries) {
        super.loadAdditional(tag, registries);
        for (int slot = 0; slot < 2; slot++) {
            this.mounts[slot] = tag.contains("Mount" + slot)
                ? ItemStack.parseOptional(registries, tag.getCompound("Mount" + slot))
                : ItemStack.EMPTY;
            this.contents[slot] = NonNullList.withSize(CONTAINER_SIZE, ItemStack.EMPTY);
            if (tag.contains("Items" + slot)) {
                ContainerHelper.loadAllItems(tag.getCompound("Items" + slot), this.contents[slot], registries);
            }
        }
    }

    @Override
    public CompoundTag getUpdateTag(HolderLookup.Provider registries) {
        CompoundTag tag = new CompoundTag();
        this.saveAdditional(tag, registries);
        return tag;
    }

    @Override
    public Packet<ClientGamePacketListener> getUpdatePacket() {
        return ClientboundBlockEntityDataPacket.create(this);
    }

    private final class MountedContainer extends SimpleContainer {
        private final int slot;

        private MountedContainer(int slot) {
            super(CONTAINER_SIZE);
            this.slot = slot;
            for (int i = 0; i < CONTAINER_SIZE; i++) {
                this.setItem(i, VehicleHangingPlateBlockEntity.this.contents[slot].get(i));
            }
        }

        @Override
        public void setChanged() {
            super.setChanged();
            for (int i = 0; i < CONTAINER_SIZE; i++) {
                VehicleHangingPlateBlockEntity.this.contents[this.slot].set(i, this.getItem(i));
            }
            VehicleHangingPlateBlockEntity.this.setChangedAndSync();
        }

        @Override
        public boolean stillValid(Player player) {
            return VehicleHangingPlateBlockEntity.this.level != null
                && VehicleHangingPlateBlockEntity.this.hasMount(this.slot)
                && player.distanceToSqr(
                    VehicleHangingPlateBlockEntity.this.worldPosition.getX() + 0.5,
                    VehicleHangingPlateBlockEntity.this.worldPosition.getY() + 0.5,
                    VehicleHangingPlateBlockEntity.this.worldPosition.getZ() + 0.5
                ) <= 64.0;
        }
    }
}
