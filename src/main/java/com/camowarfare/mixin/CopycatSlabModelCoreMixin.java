package com.camowarfare.mixin;

import com.copycatsplus.copycats.content.copycat.slab.CopycatSlabBlock;
import com.copycatsplus.copycats.content.copycat.slab.CopycatSlabModelCore;
import com.copycatsplus.copycats.foundation.copycat.model.assembly.AssemblyTransform;
import com.copycatsplus.copycats.foundation.copycat.model.assembly.CopycatRenderContext;
import net.minecraft.core.Direction;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.block.state.properties.SlabType;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

import static com.copycatsplus.copycats.foundation.copycat.model.assembly.CopycatRenderContext.aabb;
import static com.copycatsplus.copycats.foundation.copycat.model.assembly.CopycatRenderContext.cull;
import static com.copycatsplus.copycats.foundation.copycat.model.assembly.CopycatRenderContext.vec3;
import static com.copycatsplus.copycats.foundation.copycat.model.assembly.MutableCullFace.DOWN;
import static com.copycatsplus.copycats.foundation.copycat.model.assembly.MutableCullFace.NORTH;
import static com.copycatsplus.copycats.foundation.copycat.model.assembly.MutableCullFace.SOUTH;
import static com.copycatsplus.copycats.foundation.copycat.model.assembly.MutableCullFace.UP;

@Mixin(value = CopycatSlabModelCore.class, remap = false)
abstract class CopycatSlabModelCoreMixin {
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

        Direction facing = state.getOptionalValue(CopycatSlabBlock.SLAB_TYPE).isPresent()
            ? CopycatSlabBlock.getApparentDirection(state)
            : Direction.UP;
        boolean isDouble = state.getOptionalValue(CopycatSlabBlock.SLAB_TYPE).orElse(SlabType.BOTTOM) == SlabType.DOUBLE;

        camowarfare$assembleSlab(context, facing);
        if (isDouble) {
            camowarfare$assembleSlab(context, facing.getOpposite());
        }
        ci.cancel();
    }

    private static void camowarfare$assembleSlab(CopycatRenderContext context, Direction facing) {
        if (facing.getAxis().isHorizontal()) {
            AssemblyTransform transform = t -> t.rotateY((int) facing.toYRot());
            context.assemblePiece(
                transform,
                vec3(0, 0, 0),
                aabb(16, 16, 4).move(0, 0, 0),
                cull(SOUTH)
            );
            context.assemblePiece(
                transform,
                vec3(0, 0, 4),
                aabb(16, 16, 4).move(0, 0, 4),
                cull(NORTH)
            );
        } else {
            AssemblyTransform transform = t -> t.flipY(facing.getAxisDirection() == Direction.AxisDirection.NEGATIVE);
            context.assemblePiece(
                transform,
                vec3(0, 0, 0),
                aabb(16, 4, 16).move(0, 0, 0),
                cull(UP)
            );
            context.assemblePiece(
                transform,
                vec3(0, 4, 0),
                aabb(16, 4, 16).move(0, 4, 0),
                cull(DOWN)
            );
        }
    }

    private static boolean camowarfare$isCamoMaterial(BlockState material) {
        return material != null
            && "camowarfare".equals(material.getBlock().builtInRegistryHolder().key().location().getNamespace());
    }
}
