package com.camowarfare.client;

import com.camowarfare.CamoWarfare;
import com.camowarfare.ConnectedCamoBlockEntity;
import com.mojang.blaze3d.vertex.PoseStack;
import com.mojang.blaze3d.vertex.VertexConsumer;
import java.util.List;
import net.minecraft.client.renderer.MultiBufferSource;
import net.minecraft.client.renderer.RenderType;
import net.minecraft.client.renderer.LightTexture;
import net.minecraft.client.renderer.blockentity.BlockEntityRenderer;
import net.minecraft.client.renderer.blockentity.BlockEntityRendererProvider;
import net.minecraft.core.Direction;
import net.minecraft.resources.ResourceLocation;
import org.joml.Matrix4f;

public final class ConnectedCamoDecalRenderer implements BlockEntityRenderer<ConnectedCamoBlockEntity> {
    private static final float MIN = 0.18F;
    private static final float MAX = 0.82F;
    private static final float EPSILON = 0.006F;
    private static final float LAYER_EPSILON = 0.002F;

    public ConnectedCamoDecalRenderer(BlockEntityRendererProvider.Context context) {
    }

    @Override
    public void render(
        ConnectedCamoBlockEntity blockEntity,
        float partialTick,
        PoseStack poseStack,
        MultiBufferSource bufferSource,
        int packedLight,
        int packedOverlay
    ) {
        for (Direction face : Direction.values()) {
            List<String> decals = blockEntity.decals(face);
            for (int index = 0; index < decals.size(); index++) {
                DecalRenderData decal = DecalRenderData.parse(decals.get(index));
                ResourceLocation texture = ResourceLocation.fromNamespaceAndPath(
                    CamoWarfare.MOD_ID,
                    "textures/decal/decal_" + decal.id() + ".png"
                );
                RenderType renderType = RenderType.entityCutoutNoCull(texture);
                int decalLight = LightTexture.FULL_BRIGHT;
                VertexConsumer consumer = bufferSource.getBuffer(renderType);
                renderFaceDecal(face, decal, index, decals.size(), poseStack, consumer, decalLight, packedOverlay);
            }
        }
    }

    private static void renderFaceDecal(
        Direction face,
        DecalRenderData decal,
        int index,
        int count,
        PoseStack poseStack,
        VertexConsumer consumer,
        int packedLight,
        int packedOverlay
    ) {
        PoseStack.Pose pose = poseStack.last();
        Matrix4f matrix = pose.pose();
        DecalBox box = boxFor(decal, index, count);
        float offset = EPSILON + index * LAYER_EPSILON;
        switch (face) {
            case NORTH -> quad(consumer, matrix, pose, box.maxX, box.maxY, -offset, box.minX, box.maxY, -offset, box.minX, box.minY, -offset, box.maxX, box.minY, -offset, decal, 0, 0, -1, packedLight, packedOverlay);
            case SOUTH -> quad(consumer, matrix, pose, box.minX, box.maxY, 1 + offset, box.maxX, box.maxY, 1 + offset, box.maxX, box.minY, 1 + offset, box.minX, box.minY, 1 + offset, decal, 0, 0, 1, packedLight, packedOverlay);
            case WEST -> quad(consumer, matrix, pose, -offset, box.maxY, box.minX, -offset, box.maxY, box.maxX, -offset, box.minY, box.maxX, -offset, box.minY, box.minX, decal, -1, 0, 0, packedLight, packedOverlay);
            case EAST -> quad(consumer, matrix, pose, 1 + offset, box.maxY, box.maxX, 1 + offset, box.maxY, box.minX, 1 + offset, box.minY, box.minX, 1 + offset, box.minY, box.maxX, decal, 1, 0, 0, packedLight, packedOverlay);
            case UP -> quad(consumer, matrix, pose, box.minX, 1 + offset, box.minY, box.maxX, 1 + offset, box.minY, box.maxX, 1 + offset, box.maxY, box.minX, 1 + offset, box.maxY, decal, 0, 1, 0, packedLight, packedOverlay);
            case DOWN -> quad(consumer, matrix, pose, box.minX, -offset, box.minY, box.maxX, -offset, box.minY, box.maxX, -offset, box.maxY, box.minX, -offset, box.maxY, decal, 0, -1, 0, packedLight, packedOverlay);
        }
    }

    private static DecalBox boxFor(DecalRenderData decal, int index, int count) {
        String decalId = decal.id();
        if (decal.customUv()) {
            return new DecalBox(0.0F, 0.0F, 1.0F, 1.0F);
        }
        if (decalId.startsWith("number_") && count > 1) {
            float gap = 0.03F;
            float width = Math.min(0.42F, (0.92F - gap * (count - 1)) / count);
            float total = width * count + gap * (count - 1);
            float minX = 0.5F - total / 2.0F + index * (width + gap);
            return new DecalBox(minX, 0.12F, minX + width, 0.88F);
        }
        if (decalId.startsWith("number_")) {
            return new DecalBox(0.22F, 0.12F, 0.78F, 0.88F);
        }
        if (decalId.startsWith("mark_")) {
            return new DecalBox(0.0F, 0.0F, 1.0F, 1.0F);
        }
        return new DecalBox(MIN, MIN, MAX, MAX);
    }

    private static void quad(
        VertexConsumer consumer,
        Matrix4f matrix,
        PoseStack.Pose pose,
        float x0,
        float y0,
        float z0,
        float x1,
        float y1,
        float z1,
        float x2,
        float y2,
        float z2,
        float x3,
        float y3,
        float z3,
        DecalRenderData decal,
        int normalX,
        int normalY,
        int normalZ,
        int packedLight,
        int packedOverlay
    ) {
        vertex(consumer, matrix, pose, x0, y0, z0, decal.u0(), decal.v0(), normalX, normalY, normalZ, packedLight, packedOverlay);
        vertex(consumer, matrix, pose, x1, y1, z1, decal.u1(), decal.v0(), normalX, normalY, normalZ, packedLight, packedOverlay);
        vertex(consumer, matrix, pose, x2, y2, z2, decal.u1(), decal.v1(), normalX, normalY, normalZ, packedLight, packedOverlay);
        vertex(consumer, matrix, pose, x3, y3, z3, decal.u0(), decal.v1(), normalX, normalY, normalZ, packedLight, packedOverlay);
    }

    private static void vertex(
        VertexConsumer consumer,
        Matrix4f matrix,
        PoseStack.Pose pose,
        float x,
        float y,
        float z,
        float u,
        float v,
        int normalX,
        int normalY,
        int normalZ,
        int packedLight,
        int packedOverlay
    ) {
        consumer.addVertex(matrix, x, y, z)
            .setColor(255, 255, 255, 255)
            .setUv(u, v)
            .setOverlay(packedOverlay)
            .setLight(packedLight)
            .setNormal(pose, normalX, normalY, normalZ);
    }

    private record DecalBox(float minX, float minY, float maxX, float maxY) {}

    private record DecalRenderData(String id, float u0, float v0, float u1, float v1, boolean customUv) {
        static DecalRenderData parse(String entry) {
            String[] parts = entry.split("\\|", -1);
            if (parts.length != 6) {
                return full(entry);
            }
            try {
                return new DecalRenderData(
                    parts[0],
                    Float.parseFloat(parts[2]),
                    Float.parseFloat(parts[3]),
                    Float.parseFloat(parts[4]),
                    Float.parseFloat(parts[5]),
                    true
                );
            } catch (NumberFormatException ignored) {
                return full(parts[0]);
            }
        }

        private static DecalRenderData full(String id) {
            return new DecalRenderData(id, 0.0F, 0.0F, 1.0F, 1.0F, false);
        }
    }
}
