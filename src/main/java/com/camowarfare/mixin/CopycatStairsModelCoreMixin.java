package com.camowarfare.mixin;

import com.copycatsplus.copycats.content.copycat.stairs.CopycatStairsModelCore;
import com.copycatsplus.copycats.foundation.copycat.model.assembly.AssemblyTransform;
import com.copycatsplus.copycats.foundation.copycat.model.assembly.CopycatRenderContext;
import net.minecraft.world.level.block.StairBlock;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.block.state.properties.Half;
import net.minecraft.world.level.block.state.properties.StairsShape;
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

@Mixin(value = CopycatStairsModelCore.class, remap = false)
abstract class CopycatStairsModelCoreMixin {
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

        int facing = (int) state.getValue(StairBlock.FACING).toYRot();
        boolean top = state.getValue(StairBlock.HALF) == Half.TOP;
        StairsShape shape = state.getValue(StairBlock.SHAPE);
        switch (shape) {
            case STRAIGHT -> {
                AssemblyTransform transform = t -> t.rotateY(facing).flipY(top);
                camowarfare$assembleStraight(context, transform);
            }
            case INNER_LEFT, INNER_RIGHT -> {
                boolean flipX = shape == StairsShape.INNER_RIGHT;
                AssemblyTransform transform = t -> t.flipX(flipX).rotateY(facing).flipY(top);
                camowarfare$assembleInnerLeft(context, transform);
            }
            case OUTER_LEFT, OUTER_RIGHT -> {
                boolean flipX = shape == StairsShape.OUTER_RIGHT;
                AssemblyTransform transform = t -> t.flipX(flipX).rotateY(facing).flipY(top);
                camowarfare$assembleOuterLeft(context, transform);
            }
        }
        ci.cancel();
    }

    private static void camowarfare$assembleStraight(CopycatRenderContext context, AssemblyTransform transform) {
        context.assemblePiece(transform, vec3(0, 0, 0), aabb(16, 4, 8).move(0, 0, 0), cull(UP | SOUTH));
        context.assemblePiece(transform, vec3(0, 4, 0), aabb(16, 4, 8).move(0, 4, 0), cull(DOWN | SOUTH));
        context.assemblePiece(transform, vec3(0, 0, 8), aabb(16, 8, 8).move(0, 0, 8), cull(UP | NORTH));
        context.assemblePiece(transform, vec3(0, 8, 8), aabb(16, 8, 4).move(0, 8, 8), cull(DOWN | SOUTH));
        context.assemblePiece(transform, vec3(0, 8, 12), aabb(16, 8, 4).move(0, 8, 12), cull(DOWN | NORTH));
    }

    private static void camowarfare$assembleInnerLeft(CopycatRenderContext context, AssemblyTransform transform) {
        context.assemblePiece(transform, vec3(0, 0, 0), aabb(8, 4, 8).move(0, 0, 0), cull(UP | SOUTH | EAST));
        context.assemblePiece(transform, vec3(0, 4, 0), aabb(8, 4, 8).move(0, 4, 0), cull(DOWN | SOUTH | EAST));
        context.assemblePiece(transform, vec3(0, 0, 8), aabb(16, 8, 8).move(0, 0, 8), cull(UP | NORTH));
        context.assemblePiece(transform, vec3(8, 8, 8), aabb(8, 8, 8).move(8, 8, 8), cull(DOWN | NORTH | WEST));
        context.assemblePiece(transform, vec3(0, 8, 12), aabb(8, 8, 4).move(0, 8, 12), cull(DOWN | NORTH | EAST));
        context.assemblePiece(transform, vec3(0, 8, 8), aabb(8, 8, 4).move(0, 8, 8), cull(DOWN | SOUTH | EAST));
        context.assemblePiece(transform, vec3(12, 8, 0), aabb(4, 8, 8).move(12, 8, 0), cull(DOWN | SOUTH | WEST));
        context.assemblePiece(transform, vec3(8, 8, 0), aabb(4, 8, 8).move(8, 8, 0), cull(DOWN | SOUTH | EAST));
        context.assemblePiece(transform, vec3(8, 0, 0), aabb(8, 8, 8).move(8, 0, 0), cull(UP | SOUTH | WEST));
    }

    private static void camowarfare$assembleOuterLeft(CopycatRenderContext context, AssemblyTransform transform) {
        context.assemblePiece(transform, vec3(0, 0, 0), aabb(8, 4, 16).move(0, 0, 0), cull(UP | EAST));
        context.assemblePiece(transform, vec3(0, 4, 0), aabb(8, 4, 16).move(0, 4, 0), cull(DOWN | EAST));
        context.assemblePiece(transform, vec3(8, 0, 0), aabb(8, 4, 8).move(8, 0, 0), cull(UP | SOUTH | WEST));
        context.assemblePiece(transform, vec3(8, 4, 0), aabb(8, 4, 8).move(8, 4, 0), cull(DOWN | SOUTH | WEST));
        context.assemblePiece(transform, vec3(8, 0, 8), aabb(8, 8, 8).move(8, 0, 8), cull(UP | NORTH | WEST));
        context.assemblePiece(transform, vec3(12, 8, 12), aabb(4, 8, 4).move(12, 8, 12), cull(DOWN | NORTH | WEST));
        context.assemblePiece(transform, vec3(8, 8, 12), aabb(4, 8, 4).move(8, 8, 12), cull(DOWN | NORTH | EAST));
        context.assemblePiece(transform, vec3(12, 8, 8), aabb(4, 8, 4).move(12, 8, 8), cull(DOWN | SOUTH | WEST));
        context.assemblePiece(transform, vec3(8, 8, 8), aabb(4, 8, 4).move(8, 8, 8), cull(DOWN | SOUTH | EAST));
    }

    private static boolean camowarfare$isCamoMaterial(BlockState material) {
        return material != null
            && "camowarfare".equals(material.getBlock().builtInRegistryHolder().key().location().getNamespace());
    }
}
