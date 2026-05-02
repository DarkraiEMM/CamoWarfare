package com.camowarfare.mixin;

import com.copycatsplus.copycats.content.copycat.half_panel.CopycatHalfPanelBlock;
import com.copycatsplus.copycats.content.copycat.half_panel.CopycatHalfPanelModelCore;
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
import static com.copycatsplus.copycats.foundation.copycat.model.assembly.MutableCullFace.DOWN;
import static com.copycatsplus.copycats.foundation.copycat.model.assembly.MutableCullFace.EAST;
import static com.copycatsplus.copycats.foundation.copycat.model.assembly.MutableCullFace.NORTH;
import static com.copycatsplus.copycats.foundation.copycat.model.assembly.MutableCullFace.SOUTH;
import static com.copycatsplus.copycats.foundation.copycat.model.assembly.MutableCullFace.UP;
import static com.copycatsplus.copycats.foundation.copycat.model.assembly.MutableCullFace.WEST;

@Mixin(value = CopycatHalfPanelModelCore.class, remap = false)
abstract class CopycatHalfPanelModelCoreMixin {
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

        Direction facing = state.getValue(CopycatHalfPanelBlock.FACING);
        Direction offset = state.getValue(CopycatHalfPanelBlock.OFFSET);
        if (facing.getAxis().isVertical()) {
            boolean flipY = facing == Direction.UP;
            AssemblyTransform transform = t -> t.rotateY((int) offset.toYRot()).flipY(flipY);
            context.assemblePiece(transform, vec3(0, 0, 12), aabb(16, 1, 4).move(0, 0, 12), cull(UP | NORTH));
            context.assemblePiece(transform, vec3(0, 0, 8), aabb(16, 1, 4).move(0, 0, 8), cull(UP | SOUTH));
            context.assemblePiece(transform, vec3(0, 1, 12), aabb(16, 2, 4).move(0, 1, 12), cull(DOWN | NORTH));
            context.assemblePiece(transform, vec3(0, 1, 8), aabb(16, 2, 4).move(0, 1, 8), cull(DOWN | SOUTH));
        } else if (offset.getAxis() == facing.getAxis()) {
            boolean flipY = offset.getAxisDirection() == Direction.AxisDirection.POSITIVE;
            AssemblyTransform transform = t -> t.rotateY((int) facing.toYRot()).flipY(flipY);
            context.assemblePiece(transform, vec3(0, 0, 15), aabb(16, 4, 1).move(0, 0, 15), cull(UP | NORTH));
            context.assemblePiece(transform, vec3(0, 4, 15), aabb(16, 4, 1).move(0, 4, 15), cull(DOWN | NORTH));
            context.assemblePiece(transform, vec3(0, 0, 13), aabb(16, 4, 2).move(0, 0, 13), cull(UP | SOUTH));
            context.assemblePiece(transform, vec3(0, 4, 13), aabb(16, 4, 2).move(0, 4, 13), cull(DOWN | SOUTH));
        } else {
            int leftOffset = offset == facing.getCounterClockWise() ? 8 : 0;
            AssemblyTransform transform = t -> t.rotateY((int) facing.toYRot());
            context.assemblePiece(transform, vec3(leftOffset, 0, 15), aabb(4, 16, 1).move(leftOffset, 0, 15), cull(EAST | NORTH));
            context.assemblePiece(transform, vec3(4 + leftOffset, 0, 15), aabb(4, 16, 1).move(4 + leftOffset, 0, 15), cull(WEST | NORTH));
            context.assemblePiece(transform, vec3(leftOffset, 0, 13), aabb(4, 16, 2).move(leftOffset, 0, 13), cull(EAST | SOUTH));
            context.assemblePiece(transform, vec3(4 + leftOffset, 0, 13), aabb(4, 16, 2).move(4 + leftOffset, 0, 13), cull(WEST | SOUTH));
        }
        ci.cancel();
    }

    private static boolean camowarfare$isCamoMaterial(BlockState material) {
        return material != null
            && "camowarfare".equals(material.getBlock().builtInRegistryHolder().key().location().getNamespace());
    }
}
