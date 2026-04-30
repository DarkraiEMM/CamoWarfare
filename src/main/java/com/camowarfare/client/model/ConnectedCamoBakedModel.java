package com.camowarfare.client.model;

import java.util.ArrayList;
import java.util.EnumMap;
import java.util.List;
import java.util.Map;
import com.camowarfare.ConnectedPreviewPanelBlock;
import net.minecraft.client.renderer.RenderType;
import net.minecraft.client.renderer.block.model.BakedQuad;
import net.minecraft.client.renderer.block.model.BlockElement;
import net.minecraft.client.renderer.block.model.BlockElementFace;
import net.minecraft.client.renderer.block.model.BlockFaceUV;
import net.minecraft.client.renderer.texture.TextureAtlasSprite;
import net.minecraft.client.resources.model.BakedModel;
import net.minecraft.client.resources.model.ModelState;
import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.util.RandomSource;
import net.minecraft.world.level.BlockAndTintGetter;
import net.minecraft.world.level.block.state.BlockState;
import net.neoforged.neoforge.client.model.BakedModelWrapper;
import net.neoforged.neoforge.client.model.IDynamicBakedModel;
import net.neoforged.neoforge.client.model.IModelBuilder;
import net.neoforged.neoforge.client.model.data.ModelData;
import net.neoforged.neoforge.client.model.data.ModelData.Builder;
import net.neoforged.neoforge.client.model.data.ModelProperty;
import net.neoforged.neoforge.client.model.geometry.UnbakedGeometryHelper;
import org.jetbrains.annotations.Nullable;
import org.joml.Vector3f;

public final class ConnectedCamoBakedModel extends BakedModelWrapper<BakedModel> implements IDynamicBakedModel {
    private static final Vector3f CUBE_FROM = new Vector3f(0.0F, 0.0F, 0.0F);
    private static final Vector3f CUBE_TO = new Vector3f(16.0F, 16.0F, 16.0F);
    private static final float[] FULL_FACE_UV = new float[] { 0.0F, 0.0F, 16.0F, 16.0F };
    private static final float COPYCAT_TILE_SIZE = 4.0F;
    private static final int COPYCAT_TILES_PER_AXIS = 4;
    private static final int POSITION_ATLAS_PIXELS = 512;
    private static final int POSITION_ATLAS_UV_SIZE = 16;
    private static final float EDGE_WIDTH = 0.35F;
    private static final float RIVET_INSET = 0.75F;
    private static final float RIVET_SIZE = 1.55F;
    public static final ModelProperty<Boolean> COPYCAT_ATLAS_PROPERTY = new ModelProperty<>();
    public static final ModelProperty<Integer> POSITION_TILE_PROPERTY = new ModelProperty<>();

    private final Map<Direction.Axis, Map<Direction, List<BakedQuad>[]>> cachedFaceQuads;
    private final Map<Direction.Axis, Map<Direction, List<BakedQuad>[]>> cachedCopycatFaceQuads;
    private final Map<Direction.Axis, Map<Direction, Map<Integer, List<BakedQuad>>>> cachedPositionTiledFaceQuads;
    private final List<BakedQuad> itemQuads;
    private final boolean itemRender;
    private final boolean positionTiled;
    private final int positionTileCount;

    public ConnectedCamoBakedModel(
        BakedModel originalModel,
        Map<Direction, TextureAtlasSprite> faceSprites,
        @Nullable TextureAtlasSprite copycatAtlasSprite,
        @Nullable TextureAtlasSprite edgeSprite,
        @Nullable TextureAtlasSprite rivetSprite,
        Map<Direction, TextureAtlasSprite[]> splitFaceSprites,
        ModelState modelState,
        boolean itemRender,
        boolean positionTiled,
        int positionTilePixels
    ) {
        super(originalModel);
        this.itemRender = itemRender;
        this.positionTiled = positionTiled;
        int clampedTilePixels = validPositionTilePixels(positionTilePixels) ? positionTilePixels : 32;
        this.positionTileCount = POSITION_ATLAS_PIXELS / clampedTilePixels;
        float positionTileUvSize = (float) POSITION_ATLAS_UV_SIZE / this.positionTileCount;
        this.cachedFaceQuads = buildFaceCache(faceSprites, splitFaceSprites, modelState);
        this.cachedCopycatFaceQuads = buildCopycatFaceCache(faceSprites, copycatAtlasSprite, modelState);
        this.cachedPositionTiledFaceQuads = positionTiled
            ? buildPositionTiledFaceCache(faceSprites, edgeSprite, rivetSprite, modelState, this.positionTileCount, positionTileUvSize)
            : Map.of();
        this.itemQuads = buildItemQuads(faceSprites, modelState);
    }

    @Override
    public List<BakedQuad> getQuads(
            @Nullable BlockState state,
            @Nullable Direction side,
            RandomSource rand,
            ModelData extraData,
            @Nullable RenderType renderType) {
        if (state == null) {
            return side == null && itemRender ? itemQuads : List.of();
        }

        if (side == null) {
            return List.of();
        }

        Direction.Axis axis = state.hasProperty(ConnectedPreviewPanelBlock.AXIS)
            ? state.getValue(ConnectedPreviewPanelBlock.AXIS)
            : Direction.Axis.Y;
        if (positionTiled && !useCopycatAtlas(extraData)) {
            int mask = maskForFace(state, side, axis);
            int packedPosition = packedPosition(extraData);
            int key = positionFaceKey(side, packedPosition, mask, positionTileCount);
            return cachedPositionTiledFaceQuads.get(axis).get(side).getOrDefault(key, List.of());
        }

        Map<Direction.Axis, Map<Direction, List<BakedQuad>[]>> cache = useCopycatAtlas(extraData) ? cachedCopycatFaceQuads : cachedFaceQuads;
        return cache.get(axis).get(side)[maskForFace(state, side, axis)];
    }

    @Override
    public ModelData getModelData(BlockAndTintGetter level, BlockPos pos, BlockState state, ModelData modelData) {
        ModelData inherited = originalModel.getModelData(level, pos, state, modelData);
        boolean copycatScaled = isCopycatScaledGetter(level);
        if (!copycatScaled && !positionTiled) {
            return inherited;
        }

        Builder builder = ModelData.builder();
        copyEntries(inherited, builder);
        if (copycatScaled) {
            builder.with(COPYCAT_ATLAS_PROPERTY, true);
        }
        if (positionTiled) {
            builder.with(POSITION_TILE_PROPERTY, packPosition(pos, positionTileCount));
        }
        return builder.build();
    }

    public static void addItemQuads(IModelBuilder<?> builder, Map<Direction, TextureAtlasSprite> faceSprites, ModelState modelState) {
        for (Direction direction : Direction.values()) {
            builder.addUnculledFace(createQuad(direction, faceSprites.get(direction), FULL_FACE_UV, modelState));
        }
    }

    private static Map<Direction.Axis, Map<Direction, List<BakedQuad>[]>> buildFaceCache(
        Map<Direction, TextureAtlasSprite> faceSprites,
        Map<Direction, TextureAtlasSprite[]> splitFaceSprites,
        ModelState modelState
    ) {
        Map<Direction.Axis, Map<Direction, List<BakedQuad>[]>> cacheByAxis = new EnumMap<>(Direction.Axis.class);
        for (Direction.Axis axis : Direction.Axis.values()) {
            Map<Direction, List<BakedQuad>[]> cache = new EnumMap<>(Direction.class);
            for (Direction worldFace : Direction.values()) {
                Direction localFace = worldToLocal(worldFace, axis);
                @SuppressWarnings("unchecked")
                List<BakedQuad>[] quadsByMask = new List[16];
                TextureAtlasSprite atlasSprite = faceSprites.get(localFace);
                TextureAtlasSprite[] splitSprites = splitFaceSprites.get(localFace);
                for (int mask = 0; mask < 16; mask++) {
                    if (splitSprites != null) {
                        quadsByMask[mask] = List.of(createQuad(worldFace, splitSprites[mask], FULL_FACE_UV, modelState));
                    } else {
                        quadsByMask[mask] = List.of(createQuad(worldFace, atlasSprite, tileUv(mask), modelState));
                    }
                }
                cache.put(worldFace, quadsByMask);
            }
            cacheByAxis.put(axis, Map.copyOf(cache));
        }
        return Map.copyOf(cacheByAxis);
    }

    private static Map<Direction.Axis, Map<Direction, List<BakedQuad>[]>> buildCopycatFaceCache(
        Map<Direction, TextureAtlasSprite> faceSprites,
        @Nullable TextureAtlasSprite copycatAtlasSprite,
        ModelState modelState
    ) {
        Map<Direction.Axis, Map<Direction, List<BakedQuad>[]>> cacheByAxis = new EnumMap<>(Direction.Axis.class);
        for (Direction.Axis axis : Direction.Axis.values()) {
            Map<Direction, List<BakedQuad>[]> cache = new EnumMap<>(Direction.class);
            for (Direction worldFace : Direction.values()) {
                Direction localFace = worldToLocal(worldFace, axis);
                TextureAtlasSprite sprite = copycatAtlasSprite != null ? copycatAtlasSprite : faceSprites.get(localFace);
                @SuppressWarnings("unchecked")
                List<BakedQuad>[] quadsByMask = new List[16];
                for (int mask = 0; mask < 16; mask++) {
                    quadsByMask[mask] = createTiledFaceQuads(worldFace, sprite, modelState);
                }
                cache.put(worldFace, quadsByMask);
            }
            cacheByAxis.put(axis, Map.copyOf(cache));
        }
        return Map.copyOf(cacheByAxis);
    }

    private static Map<Direction.Axis, Map<Direction, Map<Integer, List<BakedQuad>>>> buildPositionTiledFaceCache(
        Map<Direction, TextureAtlasSprite> faceSprites,
        @Nullable TextureAtlasSprite edgeSprite,
        @Nullable TextureAtlasSprite rivetSprite,
        ModelState modelState,
        int positionTileCount,
        float positionTileUvSize
    ) {
        Map<Direction.Axis, Map<Direction, Map<Integer, List<BakedQuad>>>> cacheByAxis = new EnumMap<>(Direction.Axis.class);
        for (Direction.Axis axis : Direction.Axis.values()) {
            Map<Direction, Map<Integer, List<BakedQuad>>> cache = new EnumMap<>(Direction.class);
            for (Direction worldFace : Direction.values()) {
                Direction localFace = worldToLocal(worldFace, axis);
                TextureAtlasSprite camoSprite = faceSprites.get(localFace);
                Map<Integer, List<BakedQuad>> quadsByTileAndMask = new java.util.HashMap<>();
                for (int tileX = 0; tileX < positionTileCount; tileX++) {
                    for (int tileY = 0; tileY < positionTileCount; tileY++) {
                        for (int mask = 0; mask < 16; mask++) {
                            quadsByTileAndMask.put(
                                positionKey(tileX, tileY, mask),
                                createPositionTiledFaceQuads(worldFace, camoSprite, edgeSprite, rivetSprite, tileX, tileY, mask, positionTileUvSize, modelState)
                            );
                        }
                    }
                }
                cache.put(worldFace, Map.copyOf(quadsByTileAndMask));
            }
            cacheByAxis.put(axis, Map.copyOf(cache));
        }
        return Map.copyOf(cacheByAxis);
    }

    private static List<BakedQuad> buildItemQuads(Map<Direction, TextureAtlasSprite> faceSprites, ModelState modelState) {
        List<BakedQuad> quads = new ArrayList<>();
        for (Direction direction : Direction.values()) {
            quads.add(createQuad(direction, faceSprites.get(direction), FULL_FACE_UV, modelState));
        }
        return List.copyOf(quads);
    }

    private static BakedQuad createQuad(Direction direction, TextureAtlasSprite atlasSprite, float[] uvCoords, ModelState modelState) {
        BlockFaceUV uv = new BlockFaceUV(uvCoords, 0);
        BlockElementFace face = new BlockElementFace(direction, -1, "atlas", uv);
        BlockElement element = new BlockElement(CUBE_FROM, CUBE_TO, Map.of(direction, face), null, true);
        return UnbakedGeometryHelper.bakeElementFace(element, face, atlasSprite, direction, modelState);
    }

    private static List<BakedQuad> createTiledFaceQuads(Direction direction, TextureAtlasSprite atlasSprite, ModelState modelState) {
        List<BakedQuad> quads = new ArrayList<>(COPYCAT_TILES_PER_AXIS * COPYCAT_TILES_PER_AXIS);
        for (int row = 0; row < COPYCAT_TILES_PER_AXIS; row++) {
            for (int col = 0; col < COPYCAT_TILES_PER_AXIS; col++) {
                float u0 = col * COPYCAT_TILE_SIZE;
                float v0 = row * COPYCAT_TILE_SIZE;
                float u1 = u0 + COPYCAT_TILE_SIZE;
                float v1 = v0 + COPYCAT_TILE_SIZE;
                quads.add(createQuad(direction, atlasSprite, new float[] { u0, v0, u1, v1 }, subElementFor(direction, col, row), modelState));
            }
        }
        return List.copyOf(quads);
    }

    private static BakedQuad createQuad(Direction direction, TextureAtlasSprite atlasSprite, float[] uvCoords, BlockElement element, ModelState modelState) {
        BlockFaceUV uv = new BlockFaceUV(uvCoords, 0);
        BlockElementFace face = new BlockElementFace(direction, -1, "atlas", uv);
        BlockElement quadElement = new BlockElement(element.from, element.to, Map.of(direction, face), null, true);
        return UnbakedGeometryHelper.bakeElementFace(quadElement, face, atlasSprite, direction, modelState);
    }

    private static List<BakedQuad> createPositionTiledFaceQuads(
        Direction direction,
        TextureAtlasSprite camoSprite,
        @Nullable TextureAtlasSprite edgeSprite,
        @Nullable TextureAtlasSprite rivetSprite,
        int tileX,
        int tileY,
        int mask,
        float positionTileUvSize,
        ModelState modelState
    ) {
        List<BakedQuad> quads = new ArrayList<>(8);
        quads.add(createQuad(direction, camoSprite, positionTileUv(tileX, tileY, positionTileUvSize), modelState));
        if (edgeSprite != null) {
            if ((mask & 1) == 0) {
                quads.add(createQuad(direction, edgeSprite, FULL_FACE_UV, edgeElementFor(direction, FaceBand.TOP), modelState));
            }
            if ((mask & 2) == 0) {
                quads.add(createQuad(direction, edgeSprite, FULL_FACE_UV, edgeElementFor(direction, FaceBand.RIGHT), modelState));
            }
            if ((mask & 4) == 0) {
                quads.add(createQuad(direction, edgeSprite, FULL_FACE_UV, edgeElementFor(direction, FaceBand.BOTTOM), modelState));
            }
            if ((mask & 8) == 0) {
                quads.add(createQuad(direction, edgeSprite, FULL_FACE_UV, edgeElementFor(direction, FaceBand.LEFT), modelState));
            }
        }
        if (rivetSprite != null) {
            boolean topOpen = (mask & 1) == 0;
            boolean rightOpen = (mask & 2) == 0;
            boolean bottomOpen = (mask & 4) == 0;
            boolean leftOpen = (mask & 8) == 0;
            if (topOpen && leftOpen) {
                quads.add(createQuad(direction, rivetSprite, FULL_FACE_UV, rivetElementFor(direction, FaceCorner.TOP_LEFT), modelState));
            }
            if (topOpen && rightOpen) {
                quads.add(createQuad(direction, rivetSprite, FULL_FACE_UV, rivetElementFor(direction, FaceCorner.TOP_RIGHT), modelState));
            }
            if (bottomOpen && leftOpen) {
                quads.add(createQuad(direction, rivetSprite, FULL_FACE_UV, rivetElementFor(direction, FaceCorner.BOTTOM_LEFT), modelState));
            }
            if (bottomOpen && rightOpen) {
                quads.add(createQuad(direction, rivetSprite, FULL_FACE_UV, rivetElementFor(direction, FaceCorner.BOTTOM_RIGHT), modelState));
            }
        }
        return List.copyOf(quads);
    }

    private static BlockElement subElementFor(Direction direction, int col, int row) {
        float minA = col * COPYCAT_TILE_SIZE;
        float maxA = minA + COPYCAT_TILE_SIZE;
        float minB = row * COPYCAT_TILE_SIZE;
        float maxB = minB + COPYCAT_TILE_SIZE;
        return switch (direction) {
            case NORTH, SOUTH -> new BlockElement(
                new Vector3f(minA, 16.0F - maxB, 0.0F),
                new Vector3f(maxA, 16.0F - minB, 16.0F),
                Map.of(),
                null,
                true
            );
            case EAST, WEST -> new BlockElement(
                new Vector3f(0.0F, 16.0F - maxB, minA),
                new Vector3f(16.0F, 16.0F - minB, maxA),
                Map.of(),
                null,
                true
            );
            case UP, DOWN -> new BlockElement(
                new Vector3f(minA, 0.0F, minB),
                new Vector3f(maxA, 16.0F, maxB),
                Map.of(),
                null,
                true
            );
        };
    }

    private static float[] tileUv(int mask) {
        float tileSize = 4.0F;
        float u0 = (mask % 4) * tileSize;
        float v0 = (mask / 4) * tileSize;
        return new float[] { u0, v0, u0 + tileSize, v0 + tileSize };
    }

    private static float[] positionTileUv(int tileX, int tileY, float positionTileUvSize) {
        float u0 = tileX * positionTileUvSize;
        float v0 = tileY * positionTileUvSize;
        return new float[] { u0, v0, u0 + positionTileUvSize, v0 + positionTileUvSize };
    }

    private static int positionFaceKey(Direction side, int packedPosition, int mask, int positionTileCount) {
        int x = packedPosition & 15;
        int y = (packedPosition >> 4) & 15;
        int z = (packedPosition >> 8) & 15;
        int vertical = Math.floorMod(-y, positionTileCount);
        return switch (side) {
            case UP, DOWN -> positionKey(x, z, mask);
            case NORTH, SOUTH -> positionKey(x, vertical, mask);
            case EAST, WEST -> positionKey(z, vertical, mask);
        };
    }

    private static int positionKey(int tileX, int tileY, int mask) {
        return tileX | (tileY << 4) | (mask << 8);
    }

    private static int packPosition(BlockPos pos, int positionTileCount) {
        return Math.floorMod(pos.getX(), positionTileCount)
            | (Math.floorMod(pos.getY(), positionTileCount) << 4)
            | (Math.floorMod(pos.getZ(), positionTileCount) << 8);
    }

    private static int packedPosition(ModelData data) {
        Integer value = data.get(POSITION_TILE_PROPERTY);
        return value == null ? 0 : value;
    }

    private static boolean validPositionTilePixels(int tilePixels) {
        return tilePixels >= 32 && tilePixels <= POSITION_ATLAS_PIXELS && POSITION_ATLAS_PIXELS % tilePixels == 0;
    }

    private static BlockElement edgeElementFor(Direction direction, FaceBand band) {
        return faceElementFor(direction, bandMinA(band), bandMinB(band), bandMaxA(band), bandMaxB(band));
    }

    private static BlockElement rivetElementFor(Direction direction, FaceCorner corner) {
        float minA = switch (corner) {
            case TOP_LEFT, BOTTOM_LEFT -> RIVET_INSET;
            case TOP_RIGHT, BOTTOM_RIGHT -> 16.0F - RIVET_INSET - RIVET_SIZE;
        };
        float minB = switch (corner) {
            case TOP_LEFT, TOP_RIGHT -> RIVET_INSET;
            case BOTTOM_LEFT, BOTTOM_RIGHT -> 16.0F - RIVET_INSET - RIVET_SIZE;
        };
        return faceElementFor(direction, minA, minB, minA + RIVET_SIZE, minB + RIVET_SIZE);
    }

    private static BlockElement faceElementFor(Direction direction, float minA, float minB, float maxA, float maxB) {
        return switch (direction) {
            case NORTH, SOUTH -> new BlockElement(
                new Vector3f(minA, 16.0F - maxB, 0.0F),
                new Vector3f(maxA, 16.0F - minB, 16.0F),
                Map.of(),
                null,
                true
            );
            case EAST, WEST -> new BlockElement(
                new Vector3f(0.0F, 16.0F - maxB, minA),
                new Vector3f(16.0F, 16.0F - minB, maxA),
                Map.of(),
                null,
                true
            );
            case UP, DOWN -> new BlockElement(
                new Vector3f(minA, 0.0F, minB),
                new Vector3f(maxA, 16.0F, maxB),
                Map.of(),
                null,
                true
            );
        };
    }

    private static float bandMinA(FaceBand band) {
        return switch (band) {
            case LEFT -> 0.0F;
            case RIGHT -> 16.0F - EDGE_WIDTH;
            case TOP, BOTTOM -> 0.0F;
        };
    }

    private static float bandMaxA(FaceBand band) {
        return switch (band) {
            case LEFT -> EDGE_WIDTH;
            case RIGHT -> 16.0F;
            case TOP, BOTTOM -> 16.0F;
        };
    }

    private static float bandMinB(FaceBand band) {
        return switch (band) {
            case TOP -> 0.0F;
            case BOTTOM -> 16.0F - EDGE_WIDTH;
            case LEFT, RIGHT -> 0.0F;
        };
    }

    private static float bandMaxB(FaceBand band) {
        return switch (band) {
            case TOP -> EDGE_WIDTH;
            case BOTTOM -> 16.0F;
            case LEFT, RIGHT -> 16.0F;
        };
    }

    private static int maskForFace(BlockState state, Direction worldFace, Direction.Axis axis) {
        Direction localFace = worldToLocal(worldFace, axis);
        Direction[] localEdges = edgesForFace(localFace);
        return mask(
            isConnected(state, localToWorld(localEdges[0], axis)),
            isConnected(state, localToWorld(localEdges[1], axis)),
            isConnected(state, localToWorld(localEdges[2], axis)),
            isConnected(state, localToWorld(localEdges[3], axis))
        );
    }

    private static boolean isConnected(BlockState state, Direction worldDirection) {
        return switch (worldDirection) {
            case NORTH -> state.getValue(com.camowarfare.ConnectedCamoBlock.NORTH);
            case SOUTH -> state.getValue(com.camowarfare.ConnectedCamoBlock.SOUTH);
            case EAST -> state.getValue(com.camowarfare.ConnectedCamoBlock.EAST);
            case WEST -> state.getValue(com.camowarfare.ConnectedCamoBlock.WEST);
            case UP -> state.getValue(com.camowarfare.ConnectedCamoBlock.UP);
            case DOWN -> state.getValue(com.camowarfare.ConnectedCamoBlock.DOWN);
        };
    }

    private static Direction[] edgesForFace(Direction face) {
        return switch (face) {
            case UP, DOWN -> new Direction[] { Direction.NORTH, Direction.EAST, Direction.SOUTH, Direction.WEST };
            case NORTH -> new Direction[] { Direction.UP, Direction.EAST, Direction.DOWN, Direction.WEST };
            case SOUTH -> new Direction[] { Direction.UP, Direction.EAST, Direction.DOWN, Direction.WEST };
            case EAST -> new Direction[] { Direction.UP, Direction.SOUTH, Direction.DOWN, Direction.NORTH };
            case WEST -> new Direction[] { Direction.UP, Direction.SOUTH, Direction.DOWN, Direction.NORTH };
        };
    }

    private static Direction worldToLocal(Direction worldDirection, Direction.Axis axis) {
        for (Direction localDirection : Direction.values()) {
            if (localToWorld(localDirection, axis) == worldDirection) {
                return localDirection;
            }
        }
        return worldDirection;
    }

    private static Direction localToWorld(Direction localDirection, Direction.Axis axis) {
        return switch (axis) {
            case Y -> localDirection;
            case X -> switch (localDirection) {
                case UP -> Direction.EAST;
                case DOWN -> Direction.WEST;
                case EAST -> Direction.DOWN;
                case WEST -> Direction.UP;
                case NORTH -> Direction.NORTH;
                case SOUTH -> Direction.SOUTH;
            };
            case Z -> switch (localDirection) {
                case UP -> Direction.SOUTH;
                case DOWN -> Direction.NORTH;
                case NORTH -> Direction.UP;
                case SOUTH -> Direction.DOWN;
                case EAST -> Direction.EAST;
                case WEST -> Direction.WEST;
            };
        };
    }

    private static int mask(boolean top, boolean right, boolean bottom, boolean left) {
        int mask = 0;
        if (top) {
            mask |= 1;
        }
        if (right) {
            mask |= 2;
        }
        if (bottom) {
            mask |= 4;
        }
        if (left) {
            mask |= 8;
        }
        return mask;
    }

    private static boolean useCopycatAtlas(ModelData data) {
        Boolean value = data.get(COPYCAT_ATLAS_PROPERTY);
        return Boolean.TRUE.equals(value);
    }

    private static boolean isCopycatScaledGetter(BlockAndTintGetter level) {
        String className = level.getClass().getName();
        return className.contains("ScaledBlockAndTintGetter");
    }

    private static void copyEntries(ModelData source, Builder target) {
        for (ModelProperty<?> property : source.getProperties()) {
            copyEntry(source, target, property);
        }
    }

    private static <T> void copyEntry(ModelData source, Builder target, ModelProperty<T> property) {
        T value = source.get(property);
        if (value != null) {
            target.with(property, value);
        }
    }

    private enum FaceBand {
        TOP,
        RIGHT,
        BOTTOM,
        LEFT
    }

    private enum FaceCorner {
        TOP_LEFT,
        TOP_RIGHT,
        BOTTOM_LEFT,
        BOTTOM_RIGHT
    }
}
