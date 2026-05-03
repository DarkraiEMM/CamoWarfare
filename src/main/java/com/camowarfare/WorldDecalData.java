package com.camowarfare;

import java.util.ArrayList;
import java.util.EnumMap;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.core.HolderLookup;
import net.minecraft.nbt.CompoundTag;
import net.minecraft.nbt.ListTag;
import net.minecraft.nbt.StringTag;
import net.minecraft.nbt.Tag;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.world.level.saveddata.SavedData;

public final class WorldDecalData extends SavedData {
    private static final String DATA_ID = CamoWarfare.MOD_ID + "_world_decals";
    private static final int MAX_DECALS_PER_FACE = 3;
    private final Map<BlockPos, EnumMap<Direction, List<String>>> decals = new HashMap<>();

    public static WorldDecalData get(ServerLevel level) {
        return level.getDataStorage().computeIfAbsent(new SavedData.Factory<>(WorldDecalData::new, WorldDecalData::load), DATA_ID);
    }

    public Map<BlockPos, EnumMap<Direction, List<String>>> decals() {
        Map<BlockPos, EnumMap<Direction, List<String>>> copy = new HashMap<>();
        for (Map.Entry<BlockPos, EnumMap<Direction, List<String>>> entry : decals.entrySet()) {
            EnumMap<Direction, List<String>> faces = new EnumMap<>(Direction.class);
            for (Map.Entry<Direction, List<String>> face : entry.getValue().entrySet()) {
                faces.put(face.getKey(), List.copyOf(face.getValue()));
            }
            copy.put(entry.getKey().immutable(), faces);
        }
        return copy;
    }

    public void addDecal(BlockPos pos, Direction face, String decalId) {
        List<String> faceDecals = faceDecals(pos, face);
        faceDecals.remove(decalId);
        if (faceDecals.size() >= MAX_DECALS_PER_FACE) {
            faceDecals.remove(0);
        }
        faceDecals.add(decalId);
        setDirty();
    }

    public String removeLastDecal(BlockPos pos, Direction face) {
        EnumMap<Direction, List<String>> faces = decals.get(pos);
        if (faces == null) {
            return "";
        }
        List<String> faceDecals = faces.get(face);
        if (faceDecals == null || faceDecals.isEmpty()) {
            return "";
        }
        String removed = faceDecals.remove(faceDecals.size() - 1);
        cleanup(pos, face);
        setDirty();
        return removed;
    }

    public void clear(BlockPos pos) {
        if (decals.remove(pos) != null) {
            setDirty();
        }
    }

    private List<String> faceDecals(BlockPos pos, Direction face) {
        return decals.computeIfAbsent(pos.immutable(), ignored -> new EnumMap<>(Direction.class))
            .computeIfAbsent(face, ignored -> new ArrayList<>(MAX_DECALS_PER_FACE));
    }

    private void cleanup(BlockPos pos, Direction face) {
        EnumMap<Direction, List<String>> faces = decals.get(pos);
        if (faces == null) {
            return;
        }
        List<String> faceDecals = faces.get(face);
        if (faceDecals != null && faceDecals.isEmpty()) {
            faces.remove(face);
        }
        if (faces.isEmpty()) {
            decals.remove(pos);
        }
    }

    @Override
    public CompoundTag save(CompoundTag tag, HolderLookup.Provider registries) {
        ListTag entries = new ListTag();
        for (Map.Entry<BlockPos, EnumMap<Direction, List<String>>> blockEntry : decals.entrySet()) {
            for (Map.Entry<Direction, List<String>> faceEntry : blockEntry.getValue().entrySet()) {
                if (faceEntry.getValue().isEmpty()) {
                    continue;
                }
                CompoundTag entry = new CompoundTag();
                entry.putLong("pos", blockEntry.getKey().asLong());
                entry.putString("face", faceEntry.getKey().getName());
                ListTag ids = new ListTag();
                for (String decalId : faceEntry.getValue()) {
                    ids.add(StringTag.valueOf(decalId));
                }
                entry.put("decals", ids);
                entries.add(entry);
            }
        }
        tag.put("entries", entries);
        return tag;
    }

    private static WorldDecalData load(CompoundTag tag, HolderLookup.Provider registries) {
        WorldDecalData data = new WorldDecalData();
        ListTag entries = tag.getList("entries", Tag.TAG_COMPOUND);
        for (int i = 0; i < entries.size(); i++) {
            CompoundTag entry = entries.getCompound(i);
            Direction face = Direction.byName(entry.getString("face"));
            if (face == null) {
                continue;
            }
            BlockPos pos = BlockPos.of(entry.getLong("pos"));
            ListTag ids = entry.getList("decals", Tag.TAG_STRING);
            List<String> faceDecals = data.faceDecals(pos, face);
            for (int j = 0; j < ids.size() && faceDecals.size() < MAX_DECALS_PER_FACE; j++) {
                faceDecals.add(ids.getString(j));
            }
        }
        return data;
    }
}
