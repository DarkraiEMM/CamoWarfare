package com.camowarfare.mixin;

import com.copycatsplus.copycats.content.copycat.half_layer.CopycatHalfLayerBlock;
import com.copycatsplus.copycats.content.copycat.half_layer.CopycatHalfLayerModelCore;
import com.copycatsplus.copycats.foundation.copycat.model.assembly.AssemblyTransform;
import com.copycatsplus.copycats.foundation.copycat.model.assembly.CopycatRenderContext;
import net.minecraft.core.Direction;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.block.state.properties.Half;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

import static com.copycatsplus.copycats.foundation.copycat.model.assembly.CopycatRenderContext.aabb;
import static com.copycatsplus.copycats.foundation.copycat.model.assembly.CopycatRenderContext.cull;
import static com.copycatsplus.copycats.foundation.copycat.model.assembly.CopycatRenderContext.vec3;
import static com.copycatsplus.copycats.foundation.copycat.model.assembly.MutableCullFace.DOWN;
import static com.copycatsplus.copycats.foundation.copycat.model.assembly.MutableCullFace.EAST;
import static com.copycatsplus.copycats.foundation.copycat.model.assembly.MutableCullFace.UP;
import static com.copycatsplus.copycats.foundation.copycat.model.assembly.MutableCullFace.WEST;

@Mixin(value = CopycatHalfLayerModelCore.class, remap = false)
abstract class CopycatHalfLayerModelCoreMixin {
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

        boolean flipY = state.getValue(CopycatHalfLayerBlock.HALF) == Half.TOP;
        int rot = state.getValue(CopycatHalfLayerBlock.AXIS) == Direction.Axis.X ? 0 : 90;
        for (boolean positive : FALSE_AND_TRUE) {
            int layer = state.getValue(positive ? CopycatHalfLayerBlock.POSITIVE_LAYERS : CopycatHalfLayerBlock.NEGATIVE_LAYERS);
            if (layer == 0) {
                continue;
            }
            AssemblyTransform transform = t -> t.rotateY(rot + (positive ? 180 : 0)).flipY(flipY);
            context.assemblePiece(transform, vec3(0, 0, 0), aabb(4, layer, 16).move(0, 0, 0), cull(EAST | UP));
            context.assemblePiece(transform, vec3(0, layer, 0), aabb(4, layer, 16).move(0, layer, 0), cull(EAST | DOWN));
            context.assemblePiece(transform, vec3(4, 0, 0), aabb(4, layer, 16).move(4, 0, 0), cull(WEST | UP));
            context.assemblePiece(transform, vec3(4, layer, 0), aabb(4, layer, 16).move(4, layer, 0), cull(WEST | DOWN));
        }
        ci.cancel();
    }

    private static boolean camowarfare$isCamoMaterial(BlockState material) {
        return material != null
            && "camowarfare".equals(material.getBlock().builtInRegistryHolder().key().location().getNamespace());
    }

    private static final boolean[] FALSE_AND_TRUE = new boolean[] { false, true };
}
