package com.camowarfare.mixin;

import com.camowarfare.client.compat.CopycatCamoRenderState;
import com.copycatsplus.copycats.foundation.copycat.model.assembly.AssemblyTransform;
import com.copycatsplus.copycats.foundation.copycat.model.assembly.quad.QuadTransform;
import com.copycatsplus.copycats.foundation.copycat.model.assembly.neoforge.CopycatRenderContextNeoForge.CopycatBakedQuad;
import java.util.Arrays;
import java.util.List;
import com.mojang.logging.LogUtils;
import net.minecraft.client.renderer.texture.TextureAtlasSprite;
import net.minecraft.core.Direction;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.world.phys.AABB;
import net.minecraft.world.phys.Vec3;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;
import org.slf4j.Logger;

@Mixin(targets = "com.copycatsplus.copycats.foundation.copycat.model.assembly.neoforge.CopycatRenderContextNeoForge", remap = false)
abstract class CopycatRenderContextNeoForgeMixin {
    private static final Logger LOGGER = LogUtils.getLogger();
    private static final int VERTEX_STRIDE = 8;
    private static final ThreadLocal<Integer> camowarfare$destSizeBeforeAssemble = ThreadLocal.withInitial(() -> 0);
    private static boolean camowarfare$loggedFirstCopycatQuad = false;
    private static final String ASSEMBLE_QUAD_METHOD =
        "assembleQuad(Lcom/copycatsplus/copycats/foundation/copycat/model/assembly/neoforge/CopycatRenderContextNeoForge$CopycatBakedQuad;Ljava/util/List;Ljava/lang/String;Lnet/minecraft/world/phys/AABB;Lnet/minecraft/world/phys/Vec3;Lcom/copycatsplus/copycats/foundation/copycat/model/assembly/AssemblyTransform;[Lcom/copycatsplus/copycats/foundation/copycat/model/assembly/quad/QuadTransform;)V";

    @Inject(method = ASSEMBLE_QUAD_METHOD, at = @At("HEAD"), require = 1)
    private static void camowarfare$captureDestSize(
        CopycatBakedQuad src,
        List<CopycatBakedQuad> dest,
        String key,
        AABB crop,
        Vec3 move,
        AssemblyTransform assemblyTransform,
        QuadTransform[] transforms,
        CallbackInfo ci
    ) {
        camowarfare$destSizeBeforeAssemble.set(dest.size());
    }

    @Inject(method = ASSEMBLE_QUAD_METHOD, at = @At("RETURN"), require = 1)
    private static void camowarfare$replaceAssembledQuadWithMergedUv(
        CopycatBakedQuad src,
        List<CopycatBakedQuad> dest,
        String key,
        AABB crop,
        Vec3 move,
        AssemblyTransform assemblyTransform,
        QuadTransform[] transforms,
        CallbackInfo ci
    ) {
        int previousSize = camowarfare$destSizeBeforeAssemble.get();
        if (dest.size() <= previousSize) {
            return;
        }

        int index = dest.size() - 1;
        CopycatBakedQuad quad = dest.get(index);
        TextureAtlasSprite sprite = quad.getSprite();
        ResourceLocation spriteName = sprite.contents().name();
        if (!camowarfare$loggedFirstCopycatQuad) {
            camowarfare$loggedFirstCopycatQuad = true;
            LOGGER.info("[camowarfare] Copycats quad sprite={}, spriteClass={}, property={}, direction={}",
                spriteName, sprite.getClass().getName(), quad.property, quad.getDirection());
        }
        if (!CopycatCamoRenderState.hasCamoMaterial() || !"material".equals(quad.property)) {
            return;
        }

        int[] vertices = Arrays.copyOf(quad.getVertices(), quad.getVertices().length);
        camowarfare$applyMergedUv(vertices, quad.getDirection(), sprite);
        dest.set(index, new CopycatBakedQuad(
            vertices,
            quad.getTintIndex(),
            quad.getDirection(),
            sprite,
            quad.isShade(),
            quad.cullFace,
            quad.property
        ));
    }

    private static void camowarfare$applyMergedUv(int[] vertices, Direction direction, TextureAtlasSprite sprite) {
        for (int vertex = 0; vertex < 4; vertex++) {
            int base = vertex * VERTEX_STRIDE;
            float x = Float.intBitsToFloat(vertices[base]);
            float y = Float.intBitsToFloat(vertices[base + 1]);
            float z = Float.intBitsToFloat(vertices[base + 2]);
            float u;
            float v;
            switch (direction) {
                case UP, DOWN -> {
                    u = x * 16.0F;
                    v = z * 16.0F;
                }
                case EAST, WEST -> {
                    u = z * 16.0F;
                    v = (1.0F - y) * 16.0F;
                }
                case NORTH, SOUTH -> {
                    u = x * 16.0F;
                    v = (1.0F - y) * 16.0F;
                }
                default -> {
                    u = 0.0F;
                    v = 0.0F;
                }
            }
            vertices[base + 4] = Float.floatToRawIntBits(sprite.getU(u));
            vertices[base + 5] = Float.floatToRawIntBits(sprite.getV(v));
        }
    }
}
