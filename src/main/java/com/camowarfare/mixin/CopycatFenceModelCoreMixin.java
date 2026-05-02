package com.camowarfare.mixin;

import com.copycatsplus.copycats.content.copycat.fence.CopycatFenceBlock;
import com.copycatsplus.copycats.content.copycat.fence.CopycatFenceModelCore;
import com.copycatsplus.copycats.foundation.copycat.model.assembly.AssemblyTransform;
import com.copycatsplus.copycats.foundation.copycat.model.assembly.CopycatRenderContext;
import net.minecraft.core.Direction;
import net.minecraft.world.level.block.FenceBlock;
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

@Mixin(value = CopycatFenceModelCore.class, remap = false)
abstract class CopycatFenceModelCoreMixin {
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
        if (material.getBlock() instanceof FenceBlock) {
            context.assembleAll();
            ci.cancel();
            return;
        }

        for (Direction direction : HORIZONTAL_DIRECTIONS) {
            context.assemblePiece(t -> t.rotateY((int) direction.toYRot()), vec3(6, 0, 6), aabb(2, 16, 2).move(6, 0, 6), cull(SOUTH | EAST));
        }

        for (Direction direction : HORIZONTAL_DIRECTIONS) {
            if (!state.getValue(CopycatFenceBlock.byDirection(direction))) {
                continue;
            }
            AssemblyTransform transform = t -> t.rotateY((int) direction.toYRot());
            rail(context, transform, 7, 6, 10, 1, 1, 6, UP | NORTH | EAST);
            rail(context, transform, 8, 6, 10, 1, 1, 6, UP | NORTH | WEST);
            rail(context, transform, 7, 7, 10, 1, 2, 6, DOWN | NORTH | EAST);
            rail(context, transform, 8, 7, 10, 1, 2, 6, DOWN | NORTH | WEST);
            rail(context, transform, 7, 12, 10, 1, 1, 6, UP | NORTH | EAST);
            rail(context, transform, 8, 12, 10, 1, 1, 6, UP | NORTH | WEST);
            rail(context, transform, 7, 13, 10, 1, 2, 6, DOWN | NORTH | EAST);
            rail(context, transform, 8, 13, 10, 1, 2, 6, DOWN | NORTH | WEST);
        }
        ci.cancel();
    }

    private static void rail(CopycatRenderContext context, AssemblyTransform transform, int x, int y, int z, int sx, int sy, int sz, int cull) {
        context.assemblePiece(transform, vec3(x, y, z), aabb(sx, sy, sz).move(x, y, z), cull(cull));
    }

    private static boolean camowarfare$isCamoMaterial(BlockState material) {
        return material != null
            && "camowarfare".equals(material.getBlock().builtInRegistryHolder().key().location().getNamespace());
    }

    private static final Direction[] HORIZONTAL_DIRECTIONS = new Direction[] {
        Direction.NORTH,
        Direction.SOUTH,
        Direction.WEST,
        Direction.EAST
    };
}
