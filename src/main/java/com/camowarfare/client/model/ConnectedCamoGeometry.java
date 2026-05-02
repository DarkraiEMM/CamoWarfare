package com.camowarfare.client.model;

import java.util.Collections;
import java.util.ArrayList;
import java.util.List;
import java.util.function.Function;
import java.util.EnumMap;
import java.util.Map;
import net.minecraft.client.renderer.block.model.ItemOverrides;
import net.minecraft.client.renderer.texture.TextureAtlasSprite;
import net.minecraft.client.resources.model.BakedModel;
import net.minecraft.client.resources.model.Material;
import net.minecraft.client.resources.model.ModelBaker;
import net.minecraft.client.resources.model.ModelState;
import net.minecraft.core.Direction;
import net.neoforged.neoforge.client.RenderTypeGroup;
import net.neoforged.neoforge.client.model.IModelBuilder;
import net.neoforged.neoforge.client.model.geometry.IGeometryBakingContext;
import net.neoforged.neoforge.client.model.geometry.IUnbakedGeometry;
import net.neoforged.neoforge.client.model.geometry.UnbakedGeometryHelper;

public final class ConnectedCamoGeometry implements IUnbakedGeometry<ConnectedCamoGeometry> {
    private final boolean itemRender;
    private final boolean positionTiled;
    private final int positionTilePixels;

    public ConnectedCamoGeometry(boolean itemRender, boolean positionTiled, int positionTilePixels) {
        this.itemRender = itemRender;
        this.positionTiled = positionTiled;
        this.positionTilePixels = positionTilePixels;
    }

    @Override
    public BakedModel bake(
            IGeometryBakingContext context,
            ModelBaker baker,
            Function<Material, TextureAtlasSprite> spriteGetter,
            ModelState modelState,
            ItemOverrides overrides) {
        ModelState composedState = UnbakedGeometryHelper.composeRootTransformIntoModelState(modelState, context.getRootTransform());
        Map<Direction, TextureAtlasSprite> faceSprites = loadFaceSprites(context, spriteGetter);
        TextureAtlasSprite copycatAtlasSprite = loadOptionalSprite(context, spriteGetter, "copycat_atlas");
        List<TextureAtlasSprite> copycatTileSprites = loadOptionalSpriteSequence(context, spriteGetter, "copycat_atlas_");
        TextureAtlasSprite edgeSprite = loadOptionalSprite(context, spriteGetter, "edge");
        TextureAtlasSprite rivetSprite = loadOptionalSprite(context, spriteGetter, "rivet");
        Map<Direction, TextureAtlasSprite[]> splitFaceSprites = emptySplitFaceSprites();
        TextureAtlasSprite particleSprite = context.hasMaterial("particle")
            ? spriteGetter.apply(context.getMaterial("particle"))
            : faceSprites.get(Direction.NORTH);

        RenderTypeGroup renderTypes = RenderTypeGroup.EMPTY;
        if (context.getRenderTypeHint() != null) {
            renderTypes = context.getRenderType(context.getRenderTypeHint());
        }

        IModelBuilder<?> builder = IModelBuilder.of(
            context.useAmbientOcclusion(),
            context.useBlockLight(),
            context.isGui3d(),
            context.getTransforms(),
            overrides,
            particleSprite,
            renderTypes
        );

        if (itemRender) {
            ConnectedCamoBakedModel.addItemQuads(builder, faceSprites, composedState);
        }

        BakedModel baseModel = builder.build();
        return new ConnectedCamoBakedModel(
            baseModel,
            faceSprites,
            copycatAtlasSprite,
            copycatTileSprites,
            edgeSprite,
            rivetSprite,
            splitFaceSprites,
            composedState,
            itemRender,
            positionTiled,
            positionTilePixels
        );
    }

    private static Map<Direction, TextureAtlasSprite> loadFaceSprites(
        IGeometryBakingContext context,
        Function<Material, TextureAtlasSprite> spriteGetter
    ) {
        TextureAtlasSprite fallback = spriteGetter.apply(context.getMaterial("atlas"));
        Map<Direction, TextureAtlasSprite> sprites = new EnumMap<>(Direction.class);
        for (Direction direction : Direction.values()) {
            String materialName = materialName(direction);
            TextureAtlasSprite sprite = context.hasMaterial(materialName)
                ? spriteGetter.apply(context.getMaterial(materialName))
                : fallback;
            sprites.put(direction, sprite);
        }
        return Map.copyOf(sprites);
    }

    private static Map<Direction, TextureAtlasSprite[]> emptySplitFaceSprites() {
        Map<Direction, TextureAtlasSprite[]> sprites = new EnumMap<>(Direction.class);
        for (Direction direction : Direction.values()) {
            sprites.put(direction, null);
        }
        return Collections.unmodifiableMap(sprites);
    }

    private static TextureAtlasSprite loadOptionalSprite(
        IGeometryBakingContext context,
        Function<Material, TextureAtlasSprite> spriteGetter,
        String materialName
    ) {
        if (!context.hasMaterial(materialName)) {
            return null;
        }

        return spriteGetter.apply(context.getMaterial(materialName));
    }

    private static List<TextureAtlasSprite> loadOptionalSpriteSequence(
        IGeometryBakingContext context,
        Function<Material, TextureAtlasSprite> spriteGetter,
        String materialPrefix
    ) {
        List<TextureAtlasSprite> sprites = new ArrayList<>();
        for (int i = 0; i < 256; i++) {
            String materialName = materialPrefix + i;
            if (!context.hasMaterial(materialName)) {
                break;
            }
            sprites.add(spriteGetter.apply(context.getMaterial(materialName)));
        }
        return List.copyOf(sprites);
    }

    private static String materialName(Direction direction) {
        return switch (direction) {
            case NORTH -> "north";
            case SOUTH -> "south";
            case EAST -> "east";
            case WEST -> "west";
            case UP -> "up";
            case DOWN -> "down";
        };
    }
}
