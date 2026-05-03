package com.camowarfare;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.core.HolderLookup;
import net.minecraft.nbt.CompoundTag;
import net.minecraft.nbt.ListTag;
import net.minecraft.nbt.StringTag;
import net.minecraft.network.protocol.Packet;
import net.minecraft.network.protocol.game.ClientGamePacketListener;
import net.minecraft.network.protocol.game.ClientboundBlockEntityDataPacket;
import net.minecraft.world.level.block.entity.BlockEntity;
import net.minecraft.world.level.block.state.BlockState;
import net.neoforged.neoforge.client.model.data.ModelData;

public final class ConnectedCamoBlockEntity extends BlockEntity {
    private static final String DECALS_TAG = "Decals";
    private static final int MAX_DECALS_PER_FACE = 3;
    private final List<String>[] decals = new List[Direction.values().length];

    public ConnectedCamoBlockEntity(BlockPos pos, BlockState blockState) {
        super(CamoWarfare.CONNECTED_CAMO_BLOCK_ENTITY.get(), pos, blockState);
        for (Direction direction : Direction.values()) {
            decals[direction.ordinal()] = new ArrayList<>(MAX_DECALS_PER_FACE);
        }
    }

    public String decal(Direction direction) {
        List<String> faceDecals = decals(direction);
        return faceDecals.isEmpty() ? "" : faceDecals.get(faceDecals.size() - 1);
    }

    public List<String> decals(Direction direction) {
        return List.copyOf(decals[direction.ordinal()]);
    }

    public void addDecal(Direction direction, String decalId) {
        List<String> faceDecals = decals[direction.ordinal()];
        faceDecals.remove(decalId);
        if (faceDecals.size() >= MAX_DECALS_PER_FACE) {
            faceDecals.remove(0);
        }
        faceDecals.add(decalId);
        setChangedSyncAndRefresh();
    }

    public void addDecalPiece(Direction direction, String decalEntry) {
        List<String> faceDecals = decals[direction.ordinal()];
        faceDecals.remove(decalEntry);
        if (faceDecals.size() >= MAX_DECALS_PER_FACE) {
            faceDecals.remove(0);
        }
        faceDecals.add(decalEntry);
        setChangedSyncAndRefresh();
    }

    public String removeLastDecal(Direction direction) {
        List<String> faceDecals = decals[direction.ordinal()];
        if (!faceDecals.isEmpty()) {
            String removed = faceDecals.remove(faceDecals.size() - 1);
            setChangedSyncAndRefresh();
            return removed;
        }
        return "";
    }

    public boolean removeDecalGroup(Direction direction, String groupId) {
        List<String> faceDecals = decals[direction.ordinal()];
        boolean removed = faceDecals.removeIf(entry -> groupId.equals(decalGroupId(entry)));
        if (removed) {
            setChangedSyncAndRefresh();
        }
        return removed;
    }

    public boolean removeDecal(Direction direction, String decalId) {
        List<String> faceDecals = decals[direction.ordinal()];
        boolean removed = faceDecals.remove(decalId);
        if (removed) {
            setChangedSyncAndRefresh();
        }
        return removed;
    }

    public void clearDecals(Direction direction) {
        List<String> faceDecals = decals[direction.ordinal()];
        if (!faceDecals.isEmpty()) {
            faceDecals.clear();
            setChangedSyncAndRefresh();
        }
    }

    public void refreshConnectionsAndClient() {
        setChangedSyncAndRefresh();
    }

    @Override
    public void onLoad() {
        super.onLoad();
        if (level == null) {
            return;
        }

        requestModelDataUpdate();
        if (!level.isClientSide) {
            refreshConnectionStateAndNeighbors();
        }
    }

    @Override
    public ModelData getModelData() {
        return ModelData.builder()
            .with(ConnectedCamoModelData.POSITION_TILE_PROPERTY, packPosition(worldPosition))
            .with(ConnectedCamoModelData.POSITION_PROPERTY, worldPosition)
            .with(ConnectedCamoModelData.CONNECTIONS_PROPERTY, connectionBits())
            .build();
    }

    @Override
    protected void saveAdditional(CompoundTag tag, HolderLookup.Provider registries) {
        super.saveAdditional(tag, registries);
        CompoundTag decalTag = new CompoundTag();
        for (Direction direction : Direction.values()) {
            List<String> faceDecals = decals[direction.ordinal()];
            if (!faceDecals.isEmpty()) {
                ListTag listTag = new ListTag();
                for (String decalId : faceDecals) {
                    listTag.add(StringTag.valueOf(decalId));
                }
                decalTag.put(direction.getName(), listTag);
            }
        }
        if (!decalTag.isEmpty()) {
            tag.put(DECALS_TAG, decalTag);
        }
    }

    @Override
    protected void loadAdditional(CompoundTag tag, HolderLookup.Provider registries) {
        super.loadAdditional(tag, registries);
        Arrays.stream(decals).forEach(List::clear);
        if (!tag.contains(DECALS_TAG)) {
            return;
        }

        CompoundTag decalTag = tag.getCompound(DECALS_TAG);
        for (Direction direction : Direction.values()) {
            String key = direction.getName();
            if (decalTag.contains(key)) {
                loadFaceDecals(direction, decalTag, key);
            }
        }
    }

    @Override
    public CompoundTag getUpdateTag(HolderLookup.Provider registries) {
        CompoundTag tag = new CompoundTag();
        saveAdditional(tag, registries);
        return tag;
    }

    @Override
    public Packet<ClientGamePacketListener> getUpdatePacket() {
        return ClientboundBlockEntityDataPacket.create(this);
    }

    private int connectionBits() {
        if (level == null || !(getBlockState().getBlock() instanceof ConnectedCamoBlock block)) {
            return 0;
        }

        int bits = 0;
        for (Direction direction : Direction.values()) {
            BlockState neighborState = level.getBlockState(worldPosition.relative(direction));
            if (neighborState.getBlock() instanceof ConnectedCamoBlock neighbor
                    && neighbor.connectionFamily().equals(block.connectionFamily())) {
                bits |= ConnectedCamoModelData.connectionBit(direction);
            }
        }
        return bits;
    }

    private static int packPosition(BlockPos pos) {
        return Math.floorMod(pos.getX(), 16)
            | (Math.floorMod(pos.getY(), 16) << 4)
            | (Math.floorMod(pos.getZ(), 16) << 8);
    }

    private void loadFaceDecals(Direction direction, CompoundTag decalTag, String key) {
        List<String> faceDecals = decals[direction.ordinal()];
        if (decalTag.get(key) instanceof ListTag listTag) {
            for (int i = 0; i < listTag.size() && faceDecals.size() < MAX_DECALS_PER_FACE; i++) {
                faceDecals.add(listTag.getString(i));
            }
            return;
        }

        String legacyDecal = decalTag.getString(key);
        if (!legacyDecal.isEmpty()) {
            faceDecals.add(legacyDecal);
        }
    }

    static String decalGroupId(String decalEntry) {
        String[] parts = decalEntry.split("\\|", -1);
        return parts.length == 6 ? parts[1] : "";
    }

    private void setChangedAndSync() {
        setChanged();
        requestModelDataUpdate();
        if (level != null) {
            BlockState state = getBlockState();
            level.sendBlockUpdated(worldPosition, state, state, 3);
        }
    }

    private void setChangedSyncAndRefresh() {
        setChangedAndSync();
        refreshConnectionStateAndNeighbors();
    }

    private void refreshConnectionStateAndNeighbors() {
        if (level == null || level.isClientSide) {
            return;
        }

        refreshConnectionState(worldPosition);
        for (Direction direction : Direction.values()) {
            refreshConnectionState(worldPosition.relative(direction));
        }
    }

    private void refreshConnectionState(BlockPos pos) {
        if (level == null || level.isClientSide) {
            return;
        }

        BlockState state = level.getBlockState(pos);
        if (!(state.getBlock() instanceof ConnectedCamoBlock block)) {
            return;
        }

        BlockState updatedState = block.updateConnections(level, pos, state);
        if (!updatedState.equals(state)) {
            level.setBlock(pos, updatedState, 3);
            if (level.getBlockEntity(pos) instanceof ConnectedCamoBlockEntity blockEntity) {
                blockEntity.requestModelDataUpdate();
            }
            return;
        }
        if (level.getBlockEntity(pos) instanceof ConnectedCamoBlockEntity blockEntity) {
            blockEntity.requestModelDataUpdate();
        }
        level.sendBlockUpdated(pos, state, state, 3);
    }
}
