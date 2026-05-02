package com.camowarfare.mixin;

import com.copycatsplus.copycats.content.copycat.half_layer.CopycatHalfLayerBlock;
import com.copycatsplus.copycats.content.copycat.half_layer.CopycatMultiHalfLayerModelCore;
import com.copycatsplus.copycats.foundation.copycat.model.assembly.AssemblyTransform;
import com.copycatsplus.copycats.foundation.copycat.model.assembly.CopycatRenderContext;
import com.copycatsplus.copycats.foundation.copycat.model.assembly.quad.QuadAutoCull;
import java.util.Objects;
import net.minecraft.core.Direction;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.block.state.properties.Half;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

import static com.copycatsplus.copycats.foundation.copycat.model.assembly.CopycatRenderContext.aabb;
import static com.copycatsplus.copycats.foundation.copycat.model.assembly.CopycatRenderContext.autoCull;
import static com.copycatsplus.copycats.foundation.copycat.model.assembly.CopycatRenderContext.cull;
import static com.copycatsplus.copycats.foundation.copycat.model.assembly.CopycatRenderContext.vec3;
import static com.copycatsplus.copycats.foundation.copycat.model.assembly.MutableCullFace.DOWN;
import static com.copycatsplus.copycats.foundation.copycat.model.assembly.MutableCullFace.EAST;
import static com.copycatsplus.copycats.foundation.copycat.model.assembly.MutableCullFace.UP;
import static com.copycatsplus.copycats.foundation.copycat.model.assembly.MutableCullFace.WEST;

@Mixin(value = CopycatMultiHalfLayerModelCore.class, remap = false)
abstract class CopycatMultiHalfLayerModelCoreMixin {
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
        if (Objects.equals(key, CopycatHalfLayerBlock.NEGATIVE_LAYERS.getName()) && state.getValue(CopycatHalfLayerBlock.NEGATIVE_LAYERS) == 0) {
            ci.cancel();
            return;
        }
        if (Objects.equals(key, CopycatHalfLayerBlock.POSITIVE_LAYERS.getName()) && state.getValue(CopycatHalfLayerBlock.POSITIVE_LAYERS) == 0) {
            ci.cancel();
            return;
        }

        boolean flipY = state.getValue(CopycatHalfLayerBlock.HALF) == Half.TOP;
        int rot = state.getValue(CopycatHalfLayerBlock.AXIS) == Direction.Axis.X ? 0 : 90;
        boolean positive = key.equals(CopycatHalfLayerBlock.POSITIVE_LAYERS.getName());
        int layer = state.getValue(positive ? CopycatHalfLayerBlock.POSITIVE_LAYERS : CopycatHalfLayerBlock.NEGATIVE_LAYERS);
        if (layer == 0) {
            ci.cancel();
            return;
        }
        AssemblyTransform transform = t -> t.rotateY(rot + (positive ? 180 : 0)).flipY(flipY);
        QuadAutoCull autoCull = autoCull(aabb(8, 16, 16));
        context.assemblePiece(transform, vec3(0, 0, 0), aabb(4, layer, 16).move(0, 0, 0), cull(EAST | UP), autoCull);
        context.assemblePiece(transform, vec3(0, layer, 0), aabb(4, layer, 16).move(0, layer, 0), cull(EAST | DOWN), autoCull);
        context.assemblePiece(transform, vec3(4, 0, 0), aabb(4, layer, 16).move(4, 0, 0), cull(WEST | UP), autoCull);
        context.assemblePiece(transform, vec3(4, layer, 0), aabb(4, layer, 16).move(4, layer, 0), cull(WEST | DOWN), autoCull);
        ci.cancel();
    }

    private static boolean camowarfare$isCamoMaterial(BlockState material) {
        return material != null
            && "camowarfare".equals(material.getBlock().builtInRegistryHolder().key().location().getNamespace());
    }
}
