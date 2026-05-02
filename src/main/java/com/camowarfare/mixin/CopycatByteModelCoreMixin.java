package com.camowarfare.mixin;

import com.copycatsplus.copycats.content.copycat.bytes.CopycatByteBlock;
import com.copycatsplus.copycats.content.copycat.bytes.CopycatByteModelCore;
import com.copycatsplus.copycats.foundation.copycat.model.assembly.AssemblyTransform;
import com.copycatsplus.copycats.foundation.copycat.model.assembly.CopycatRenderContext;
import net.minecraft.world.level.block.state.BlockState;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

import static com.copycatsplus.copycats.foundation.copycat.model.assembly.CopycatRenderContext.aabb;
import static com.copycatsplus.copycats.foundation.copycat.model.assembly.CopycatRenderContext.cull;
import static com.copycatsplus.copycats.foundation.copycat.model.assembly.CopycatRenderContext.vec3;
import static com.copycatsplus.copycats.foundation.copycat.model.assembly.MutableCullFace.DOWN;
import static com.copycatsplus.copycats.foundation.copycat.model.assembly.MutableCullFace.EAST;
import static com.copycatsplus.copycats.foundation.copycat.model.assembly.MutableCullFace.NORTH;
import static com.copycatsplus.copycats.foundation.copycat.model.assembly.MutableCullFace.SOUTH;
import static com.copycatsplus.copycats.foundation.copycat.model.assembly.MutableCullFace.UP;
import static com.copycatsplus.copycats.foundation.copycat.model.assembly.MutableCullFace.WEST;

@Mixin(value = CopycatByteModelCore.class, remap = false)
abstract class CopycatByteModelCoreMixin {
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

        for (CopycatByteBlock.Byte bite : CopycatByteBlock.allBytes) {
            if (!state.getValue(CopycatByteBlock.byByte(bite))) {
                continue;
            }
            int x = bite.x() ? 8 : 0;
            int y = bite.y() ? 8 : 0;
            int z = bite.z() ? 8 : 0;
            context.assemblePiece(AssemblyTransform.IDENTITY, vec3(x, y, z), aabb(4, 4, 4).move(x, y, z), cull(UP | EAST | SOUTH));
            context.assemblePiece(AssemblyTransform.IDENTITY, vec3(x + 4, y, z), aabb(4, 4, 4).move(x + 4, y, z), cull(UP | WEST | SOUTH));
            context.assemblePiece(AssemblyTransform.IDENTITY, vec3(x, y, z + 4), aabb(4, 4, 4).move(x, y, z + 4), cull(UP | EAST | NORTH));
            context.assemblePiece(AssemblyTransform.IDENTITY, vec3(x + 4, y, z + 4), aabb(4, 4, 4).move(x + 4, y, z + 4), cull(UP | WEST | NORTH));
            context.assemblePiece(AssemblyTransform.IDENTITY, vec3(x, y + 4, z), aabb(4, 4, 4).move(x, y + 4, z), cull(DOWN | EAST | SOUTH));
            context.assemblePiece(AssemblyTransform.IDENTITY, vec3(x + 4, y + 4, z), aabb(4, 4, 4).move(x + 4, y + 4, z), cull(DOWN | WEST | SOUTH));
            context.assemblePiece(AssemblyTransform.IDENTITY, vec3(x, y + 4, z + 4), aabb(4, 4, 4).move(x, y + 4, z + 4), cull(DOWN | EAST | NORTH));
            context.assemblePiece(AssemblyTransform.IDENTITY, vec3(x + 4, y + 4, z + 4), aabb(4, 4, 4).move(x + 4, y + 4, z + 4), cull(DOWN | WEST | NORTH));
        }
        ci.cancel();
    }

    private static boolean camowarfare$isCamoMaterial(BlockState material) {
        return material != null
            && "camowarfare".equals(material.getBlock().builtInRegistryHolder().key().location().getNamespace());
    }
}
