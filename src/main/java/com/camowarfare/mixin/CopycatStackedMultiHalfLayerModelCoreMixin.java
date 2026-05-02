package com.camowarfare.mixin;

import com.copycatsplus.copycats.content.copycat.stacked_half_layer.CopycatStackedMultiHalfLayerModelCore;
import com.copycatsplus.copycats.foundation.copycat.model.assembly.AssemblyTransform;
import com.copycatsplus.copycats.foundation.copycat.model.assembly.CopycatRenderContext;
import com.copycatsplus.copycats.foundation.copycat.model.assembly.quad.QuadAutoCull;
import java.util.Objects;
import net.minecraft.world.level.block.state.BlockState;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

import static com.copycatsplus.copycats.content.copycat.half_layer.CopycatHalfLayerBlock.NEGATIVE_LAYERS;
import static com.copycatsplus.copycats.content.copycat.half_layer.CopycatHalfLayerBlock.POSITIVE_LAYERS;
import static com.copycatsplus.copycats.content.copycat.stacked_half_layer.CopycatStackedHalfLayerBlock.FACING;
import static com.copycatsplus.copycats.foundation.copycat.model.assembly.CopycatRenderContext.aabb;
import static com.copycatsplus.copycats.foundation.copycat.model.assembly.CopycatRenderContext.autoCull;
import static com.copycatsplus.copycats.foundation.copycat.model.assembly.CopycatRenderContext.cull;
import static com.copycatsplus.copycats.foundation.copycat.model.assembly.CopycatRenderContext.vec3;
import static com.copycatsplus.copycats.foundation.copycat.model.assembly.MutableCullFace.DOWN;
import static com.copycatsplus.copycats.foundation.copycat.model.assembly.MutableCullFace.NORTH;
import static com.copycatsplus.copycats.foundation.copycat.model.assembly.MutableCullFace.SOUTH;
import static com.copycatsplus.copycats.foundation.copycat.model.assembly.MutableCullFace.UP;

@Mixin(value = CopycatStackedMultiHalfLayerModelCore.class, remap = false)
abstract class CopycatStackedMultiHalfLayerModelCoreMixin {
    @Inject(method = "emitCopycatQuads", at = @At("HEAD"), cancellable = true, require = 1)
    private void camowarfare$emitCopycatQuadsForCamo(
        String key,
        BlockState state,
        CopycatRenderContext context,
        BlockState material,
        CallbackInfo ci
    ) {
        if (!camowarfare$isCamoMaterial(material)) {
            return;
        }
        if (Objects.equals(key, POSITIVE_LAYERS.getName()) && state.getValue(POSITIVE_LAYERS) == 0) {
            ci.cancel();
            return;
        }
        if (Objects.equals(key, NEGATIVE_LAYERS.getName()) && state.getValue(NEGATIVE_LAYERS) == 0) {
            ci.cancel();
            return;
        }

        int rot = (int) state.getValue(FACING).toYRot();
        boolean positive = key.equals(POSITIVE_LAYERS.getName());
        int layer = state.getValue(positive ? POSITIVE_LAYERS : NEGATIVE_LAYERS);
        if (layer == 0) {
            ci.cancel();
            return;
        }
        AssemblyTransform transform = t -> t.flipY(positive).rotateY(rot + 180);
        QuadAutoCull autoCull = autoCull(aabb(16, 8, 16));
        context.assemblePiece(transform, vec3(0, 0, 0), aabb(16, 4, layer).move(0, 0, 0), cull(UP | SOUTH), autoCull);
        context.assemblePiece(transform, vec3(0, 0, layer), aabb(16, 4, layer).move(0, 0, layer), cull(UP | NORTH), autoCull);
        context.assemblePiece(transform, vec3(0, 4, 0), aabb(16, 4, layer).move(0, 4, 0), cull(DOWN | SOUTH), autoCull);
        context.assemblePiece(transform, vec3(0, 4, layer), aabb(16, 4, layer).move(0, 4, layer), cull(DOWN | NORTH), autoCull);
        ci.cancel();
    }

    private static boolean camowarfare$isCamoMaterial(BlockState material) {
        return material != null
            && "camowarfare".equals(material.getBlock().builtInRegistryHolder().key().location().getNamespace());
    }
}
