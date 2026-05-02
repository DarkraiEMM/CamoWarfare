package com.camowarfare.mixin;

import com.copycatsplus.copycats.content.copycat.vertical_step.CopycatVerticalStepBlock;
import com.copycatsplus.copycats.content.copycat.vertical_step.CopycatVerticalStepModelCore;
import com.copycatsplus.copycats.foundation.copycat.model.assembly.AssemblyTransform;
import com.copycatsplus.copycats.foundation.copycat.model.assembly.CopycatRenderContext;
import net.minecraft.core.Direction;
import net.minecraft.world.level.block.state.BlockState;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

import static com.copycatsplus.copycats.foundation.copycat.model.assembly.CopycatRenderContext.aabb;
import static com.copycatsplus.copycats.foundation.copycat.model.assembly.CopycatRenderContext.cull;
import static com.copycatsplus.copycats.foundation.copycat.model.assembly.CopycatRenderContext.vec3;
import static com.copycatsplus.copycats.foundation.copycat.model.assembly.MutableCullFace.EAST;
import static com.copycatsplus.copycats.foundation.copycat.model.assembly.MutableCullFace.NORTH;
import static com.copycatsplus.copycats.foundation.copycat.model.assembly.MutableCullFace.SOUTH;
import static com.copycatsplus.copycats.foundation.copycat.model.assembly.MutableCullFace.WEST;

@Mixin(value = CopycatVerticalStepModelCore.class, remap = false)
abstract class CopycatVerticalStepModelCoreMixin {
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

        Direction facing = state.getValue(CopycatVerticalStepBlock.FACING);
        AssemblyTransform transform = t -> t.rotateY((int) facing.toYRot());
        context.assemblePiece(transform, vec3(8, 0, 8), aabb(4, 16, 4).move(8, 0, 8), cull(EAST | SOUTH));
        context.assemblePiece(transform, vec3(12, 0, 8), aabb(4, 16, 4).move(12, 0, 8), cull(WEST | SOUTH));
        context.assemblePiece(transform, vec3(8, 0, 12), aabb(4, 16, 4).move(8, 0, 12), cull(EAST | NORTH));
        context.assemblePiece(transform, vec3(12, 0, 12), aabb(4, 16, 4).move(12, 0, 12), cull(WEST | NORTH));
        ci.cancel();
    }

    private static boolean camowarfare$isCamoMaterial(BlockState material) {
        return material != null
            && "camowarfare".equals(material.getBlock().builtInRegistryHolder().key().location().getNamespace());
    }
}
