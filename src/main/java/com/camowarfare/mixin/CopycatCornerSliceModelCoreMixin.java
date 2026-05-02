package com.camowarfare.mixin;

import com.copycatsplus.copycats.content.copycat.corner_slice.CopycatCornerSliceModelCore;
import com.copycatsplus.copycats.foundation.copycat.model.assembly.AssemblyTransform;
import com.copycatsplus.copycats.foundation.copycat.model.assembly.CopycatRenderContext;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.block.state.properties.Half;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

import static com.copycatsplus.copycats.content.copycat.slice.CopycatSliceBlock.FACING;
import static com.copycatsplus.copycats.content.copycat.slice.CopycatSliceBlock.HALF;
import static com.copycatsplus.copycats.content.copycat.slice.CopycatSliceBlock.LAYERS;
import static com.copycatsplus.copycats.foundation.copycat.model.assembly.CopycatRenderContext.aabb;
import static com.copycatsplus.copycats.foundation.copycat.model.assembly.CopycatRenderContext.cull;
import static com.copycatsplus.copycats.foundation.copycat.model.assembly.CopycatRenderContext.vec3;
import static com.copycatsplus.copycats.foundation.copycat.model.assembly.MutableCullFace.DOWN;
import static com.copycatsplus.copycats.foundation.copycat.model.assembly.MutableCullFace.EAST;
import static com.copycatsplus.copycats.foundation.copycat.model.assembly.MutableCullFace.NORTH;
import static com.copycatsplus.copycats.foundation.copycat.model.assembly.MutableCullFace.SOUTH;
import static com.copycatsplus.copycats.foundation.copycat.model.assembly.MutableCullFace.UP;
import static com.copycatsplus.copycats.foundation.copycat.model.assembly.MutableCullFace.WEST;

@Mixin(value = CopycatCornerSliceModelCore.class, remap = false)
abstract class CopycatCornerSliceModelCoreMixin {
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

        boolean flipY = state.getValue(HALF) == Half.TOP;
        int rot = (int) state.getValue(FACING).toYRot();
        int layers = state.getValue(LAYERS);
        AssemblyTransform transform = t -> t.rotateY(rot).flipY(flipY);
        piece(context, transform, 16 - layers, 0, 16 - layers, layers, UP | NORTH | WEST);
        piece(context, transform, 16 - layers * 2, 0, 16 - layers, layers, UP | NORTH | EAST);
        piece(context, transform, 16 - layers, 0, 16 - layers * 2, layers, UP | SOUTH | WEST);
        piece(context, transform, 16 - layers * 2, 0, 16 - layers * 2, layers, UP | SOUTH | EAST);
        piece(context, transform, 16 - layers, layers, 16 - layers, layers, DOWN | NORTH | WEST);
        piece(context, transform, 16 - layers * 2, layers, 16 - layers, layers, DOWN | NORTH | EAST);
        piece(context, transform, 16 - layers, layers, 16 - layers * 2, layers, DOWN | SOUTH | WEST);
        piece(context, transform, 16 - layers * 2, layers, 16 - layers * 2, layers, DOWN | SOUTH | EAST);
        ci.cancel();
    }

    private static void piece(CopycatRenderContext context, AssemblyTransform transform, int x, int y, int z, int size, int cull) {
        context.assemblePiece(transform, vec3(x, y, z), aabb(size, size, size).move(x, y, z), cull(cull));
    }

    private static boolean camowarfare$isCamoMaterial(BlockState material) {
        return material != null
            && "camowarfare".equals(material.getBlock().builtInRegistryHolder().key().location().getNamespace());
    }
}
