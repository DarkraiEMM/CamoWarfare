package com.camowarfare.client;

import com.camowarfare.FaceMountedAttachmentBlock;
import com.camowarfare.VehicleHangingPlateBlockEntity;
import com.mojang.blaze3d.vertex.PoseStack;
import com.mojang.math.Axis;
import net.minecraft.client.Minecraft;
import net.minecraft.client.renderer.MultiBufferSource;
import net.minecraft.client.renderer.blockentity.BlockEntityRenderer;
import net.minecraft.client.renderer.blockentity.BlockEntityRendererProvider;
import net.minecraft.core.registries.BuiltInRegistries;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.world.item.ItemDisplayContext;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.core.Direction;

public class VehicleHangingPlateRenderer implements BlockEntityRenderer<VehicleHangingPlateBlockEntity> {
    public VehicleHangingPlateRenderer(BlockEntityRendererProvider.Context context) {
    }

    @Override
    public void render(VehicleHangingPlateBlockEntity blockEntity, float partialTick, PoseStack poseStack, MultiBufferSource bufferSource, int packedLight, int packedOverlay) {
        BlockState state = blockEntity.getBlockState();
        Direction facing = state.getValue(FaceMountedAttachmentBlock.FACING);
        renderMount(blockEntity.mount(0), facing, true, blockEntity, poseStack, bufferSource, packedLight, packedOverlay);
        renderMount(blockEntity.mount(1), facing, false, blockEntity, poseStack, bufferSource, packedLight, packedOverlay);
    }

    private static void renderMount(ItemStack stack, Direction facing, boolean left, VehicleHangingPlateBlockEntity blockEntity, PoseStack poseStack, MultiBufferSource bufferSource, int packedLight, int packedOverlay) {
        if (stack.isEmpty()) {
            return;
        }

        poseStack.pushPose();
        poseStack.translate(0.5, 0.5, 0.5);
        poseStack.mulPose(Axis.YP.rotationDegrees(yRotation(facing)));
        poseStack.translate(left ? -0.25 : 0.25, -0.02, 0.10);
        poseStack.mulPose(Axis.YP.rotationDegrees(itemYRotation(stack)));
        float scale = itemScale(stack);
        poseStack.scale(scale, scale, scale);
        Minecraft.getInstance().getItemRenderer().renderStatic(
            stack,
            ItemDisplayContext.NONE,
            packedLight,
            packedOverlay,
            poseStack,
            bufferSource,
            blockEntity.getLevel(),
            left ? 17 : 29
        );
        poseStack.popPose();
    }

    private static float yRotation(Direction facing) {
        return switch (facing) {
            case SOUTH -> 180.0F;
            case WEST -> 90.0F;
            case EAST -> 270.0F;
            default -> 0.0F;
        };
    }

    private static float itemYRotation(ItemStack stack) {
        ResourceLocation itemId = BuiltInRegistries.ITEM.getKey(stack.getItem());
        if (itemId.getNamespace().equals("sophisticatedbackpacks")) {
            return 0.0F;
        }
        if (isSuspiciousRoastChicken(itemId)) {
            return 0.0F;
        }
        return 180.0F;
    }

    private static float itemScale(ItemStack stack) {
        ResourceLocation itemId = BuiltInRegistries.ITEM.getKey(stack.getItem());
        if (itemId.getNamespace().equals("sophisticatedbackpacks")) {
            return 0.68F;
        }
        if (isSuspiciousRoastChicken(itemId)) {
            return 0.72F;
        }
        return 0.54F;
    }

    private static boolean isSuspiciousRoastChicken(ResourceLocation itemId) {
        return itemId.getNamespace().equals("camowarfare") && itemId.getPath().equals("suspicious_roast_chicken_block");
    }
}
