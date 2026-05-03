package com.camowarfare.client;

import com.camowarfare.CamoWarfare;
import com.camowarfare.WorldDecalClientStore;
import com.mojang.blaze3d.vertex.PoseStack;
import com.mojang.blaze3d.vertex.VertexConsumer;
import java.util.EnumMap;
import java.util.List;
import java.util.Map;
import net.minecraft.client.Minecraft;
import net.minecraft.client.renderer.LightTexture;
import net.minecraft.client.renderer.MultiBufferSource;
import net.minecraft.client.renderer.texture.OverlayTexture;
import net.minecraft.client.renderer.RenderType;
import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.state.BlockState;
import net.neoforged.api.distmarker.Dist;
import net.neoforged.bus.api.SubscribeEvent;
import net.neoforged.fml.common.EventBusSubscriber;
import net.neoforged.neoforge.client.event.RenderLevelStageEvent;
import org.joml.Matrix4f;

@EventBusSubscriber(modid = CamoWarfare.MOD_ID, value = Dist.CLIENT)
public final class WorldDecalRenderer {
    private static final float EPSILON = 0.006F;
    private static final float LAYER_EPSILON = 0.002F;

    private WorldDecalRenderer() {}

    @SubscribeEvent
    public static void render(RenderLevelStageEvent event) {
        if (event.getStage() != RenderLevelStageEvent.Stage.AFTER_BLOCK_ENTITIES) {
            return;
        }

        Minecraft minecraft = Minecraft.getInstance();
        Level level = minecraft.level;
        if (level == null || WorldDecalClientStore.decals().isEmpty()) {
            return;
        }

        PoseStack poseStack = event.getPoseStack();
        MultiBufferSource.BufferSource bufferSource = minecraft.renderBuffers().bufferSource();
        double cameraX = event.getCamera().getPosition().x;
        double cameraY = event.getCamera().getPosition().y;
        double cameraZ = event.getCamera().getPosition().z;

        poseStack.pushPose();
        poseStack.translate(-cameraX, -cameraY, -cameraZ);
        for (Map.Entry<BlockPos, EnumMap<Direction, List<String>>> blockEntry : WorldDecalClientStore.decals().entrySet()) {
            BlockPos pos = blockEntry.getKey();
            BlockState state = level.getBlockState(pos);
            if (!state.isCollisionShapeFullBlock(level, pos)) {
                continue;
            }
            for (Map.Entry<Direction, List<String>> faceEntry : blockEntry.getValue().entrySet()) {
                List<String> decals = faceEntry.getValue();
                for (int index = 0; index < decals.size(); index++) {
                    DecalRenderData decal = DecalRenderData.parse(decals.get(index));
                    ResourceLocation texture = ResourceLocation.fromNamespaceAndPath(
                        CamoWarfare.MOD_ID,
                        "textures/decal/decal_" + decal.id() + ".png"
                    );
                    VertexConsumer consumer = bufferSource.getBuffer(RenderType.entityCutoutNoCull(texture));
                    renderFaceDecal(pos, faceEntry.getKey(), decal, index, poseStack, consumer);
                }
            }
        }
        poseStack.popPose();
        bufferSource.endBatch();
    }

    private static void renderFaceDecal(
        BlockPos pos,
        Direction face,
        DecalRenderData decal,
        int index,
        PoseStack poseStack,
        VertexConsumer consumer
    ) {
        PoseStack.Pose pose = poseStack.last();
        Matrix4f matrix = pose.pose();
        float offset = EPSILON + index * LAYER_EPSILON;
        float x0 = pos.getX();
        float y0 = pos.getY();
        float z0 = pos.getZ();
        float x1 = x0 + 1.0F;
        float y1 = y0 + 1.0F;
        float z1 = z0 + 1.0F;
        int light = LightTexture.FULL_BRIGHT;
        switch (face) {
            case NORTH -> quad(consumer, matrix, pose, x1, y1, z0 - offset, x0, y1, z0 - offset, x0, y0, z0 - offset, x1, y0, z0 - offset, decal, 0, 0, -1, light);
            case SOUTH -> quad(consumer, matrix, pose, x0, y1, z1 + offset, x1, y1, z1 + offset, x1, y0, z1 + offset, x0, y0, z1 + offset, decal, 0, 0, 1, light);
            case WEST -> quad(consumer, matrix, pose, x0 - offset, y1, z0, x0 - offset, y1, z1, x0 - offset, y0, z1, x0 - offset, y0, z0, decal, -1, 0, 0, light);
            case EAST -> quad(consumer, matrix, pose, x1 + offset, y1, z1, x1 + offset, y1, z0, x1 + offset, y0, z0, x1 + offset, y0, z1, decal, 1, 0, 0, light);
            case UP -> quad(consumer, matrix, pose, x0, y1 + offset, z0, x1, y1 + offset, z0, x1, y1 + offset, z1, x0, y1 + offset, z1, decal, 0, 1, 0, light);
            case DOWN -> quad(consumer, matrix, pose, x0, y0 - offset, z0, x1, y0 - offset, z0, x1, y0 - offset, z1, x0, y0 - offset, z1, decal, 0, -1, 0, light);
        }
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
        int packedLight
    ) {
        vertex(consumer, matrix, pose, x0, y0, z0, decal.u0(), decal.v0(), normalX, normalY, normalZ, packedLight);
        vertex(consumer, matrix, pose, x1, y1, z1, decal.u1(), decal.v0(), normalX, normalY, normalZ, packedLight);
        vertex(consumer, matrix, pose, x2, y2, z2, decal.u1(), decal.v1(), normalX, normalY, normalZ, packedLight);
        vertex(consumer, matrix, pose, x3, y3, z3, decal.u0(), decal.v1(), normalX, normalY, normalZ, packedLight);
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
        int packedLight
    ) {
        consumer.addVertex(matrix, x, y, z)
            .setColor(255, 255, 255, 255)
            .setUv(u, v)
            .setOverlay(OverlayTexture.NO_OVERLAY)
            .setLight(packedLight)
            .setNormal(pose, normalX, normalY, normalZ);
    }

    private record DecalRenderData(String id, float u0, float v0, float u1, float v1) {
        static DecalRenderData parse(String entry) {
            String[] parts = entry.split("\\|", -1);
            if (parts.length != 6) {
                return full(entry);
            }
            try {
                return new DecalRenderData(parts[0], Float.parseFloat(parts[2]), Float.parseFloat(parts[3]), Float.parseFloat(parts[4]), Float.parseFloat(parts[5]));
            } catch (NumberFormatException ignored) {
                return full(parts[0]);
            }
        }

        private static DecalRenderData full(String id) {
            return new DecalRenderData(id, 0.0F, 0.0F, 1.0F, 1.0F);
        }
    }
}
