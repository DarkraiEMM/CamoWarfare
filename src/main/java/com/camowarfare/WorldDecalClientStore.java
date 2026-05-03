package com.camowarfare;

import java.util.EnumMap;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;

public final class WorldDecalClientStore {
    private static final Map<BlockPos, EnumMap<Direction, List<String>>> DECALS = new HashMap<>();

    private WorldDecalClientStore() {}

    public static void replace(Map<BlockPos, EnumMap<Direction, List<String>>> decals) {
        DECALS.clear();
        DECALS.putAll(copy(decals));
    }

    public static void update(BlockPos pos, EnumMap<Direction, List<String>> faces) {
        if (faces == null || faces.isEmpty()) {
            DECALS.remove(pos);
        } else {
            DECALS.put(pos.immutable(), copyFaces(faces));
        }
    }

    public static Map<BlockPos, EnumMap<Direction, List<String>>> decals() {
        return DECALS;
    }

    private static Map<BlockPos, EnumMap<Direction, List<String>>> copy(Map<BlockPos, EnumMap<Direction, List<String>>> decals) {
        Map<BlockPos, EnumMap<Direction, List<String>>> result = new HashMap<>();
        for (Map.Entry<BlockPos, EnumMap<Direction, List<String>>> entry : decals.entrySet()) {
            result.put(entry.getKey().immutable(), copyFaces(entry.getValue()));
        }
        return result;
    }

    private static EnumMap<Direction, List<String>> copyFaces(EnumMap<Direction, List<String>> faces) {
        EnumMap<Direction, List<String>> copy = new EnumMap<>(Direction.class);
        for (Map.Entry<Direction, List<String>> entry : faces.entrySet()) {
            copy.put(entry.getKey(), List.copyOf(entry.getValue()));
        }
        return copy;
    }
}
