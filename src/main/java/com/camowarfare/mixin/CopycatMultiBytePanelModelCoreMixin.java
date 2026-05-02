package com.camowarfare.mixin;

import com.copycatsplus.copycats.content.copycat.byte_panel.CopycatMultiBytePanelModelCore;
import com.copycatsplus.copycats.foundation.copycat.model.assembly.AssemblyTransform;
import com.copycatsplus.copycats.foundation.copycat.model.assembly.CopycatRenderContext;
import com.copycatsplus.copycats.foundation.copycat.model.assembly.quad.QuadAutoCull;
import net.minecraft.core.Direction;
import net.minecraft.world.level.block.state.BlockState;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

import static com.copycatsplus.copycats.content.copycat.byte_panel.CopycatBytePanelBlock.BOTTOM_LEFT;
import static com.copycatsplus.copycats.content.copycat.byte_panel.CopycatBytePanelBlock.TOP_LEFT;
import static com.copycatsplus.copycats.content.copycat.byte_panel.CopycatBytePanelBlock.TOP_RIGHT;
import static com.copycatsplus.copycats.content.copycat.byte_panel.CopycatBytePanelBlock.FACING;
import static com.copycatsplus.copycats.content.copycat.byte_panel.CopycatBytePanelBlock.fromProperty;
import static com.copycatsplus.copycats.foundation.copycat.model.assembly.CopycatRenderContext.aabb;
import static com.copycatsplus.copycats.foundation.copycat.model.assembly.CopycatRenderContext.autoCull;
import static com.copycatsplus.copycats.foundation.copycat.model.assembly.CopycatRenderContext.cull;
import static com.copycatsplus.copycats.foundation.copycat.model.assembly.CopycatRenderContext.vec3;
import static com.copycatsplus.copycats.foundation.copycat.model.assembly.MutableCullFace.DOWN;
import static com.copycatsplus.copycats.foundation.copycat.model.assembly.MutableCullFace.EAST;
import static com.copycatsplus.copycats.foundation.copycat.model.assembly.MutableCullFace.NORTH;
import static com.copycatsplus.copycats.foundation.copycat.model.assembly.MutableCullFace.SOUTH;
import static com.copycatsplus.copycats.foundation.copycat.model.assembly.MutableCullFace.UP;
import static com.copycatsplus.copycats.foundation.copycat.model.assembly.MutableCullFace.WEST;

@Mixin(value = CopycatMultiBytePanelModelCore.class, remap = false)
abstract class CopycatMultiBytePanelModelCoreMixin {
    @Inject(method = "emitCopycatQuads", at = @At("HEAD"), cancellable = true, require = 1)
    private void camowarfare$emitCopycatQuadsForCamo(
        String key,
        BlockState state,
        CopycatRenderContext context,
        BlockState material,
        CallbackInfo ci
    ) {
        if (!camowarfare$isCamoMaterial(material) || !state.getValue(fromProperty(key))) {
            return;
        }

        int i = key.equals(BOTTOM_LEFT.getName()) || key.equals(TOP_LEFT.getName()) ? 1 : 0;
        int j = key.equals(TOP_LEFT.getName()) || key.equals(TOP_RIGHT.getName()) ? 1 : 0;
        Direction facing = state.getValue(FACING);
        if (facing.getAxis().isHorizontal()) {
            AssemblyTransform transform = t -> t.rotateY((int) facing.toYRot());
            QuadAutoCull autoCull = autoCull(aabb(8, 8, 16).move(i * 8, j * 8, 0));
            panel(context, transform, i * 8, j * 8, 13, 4, 4, 2, UP | EAST | SOUTH, autoCull);
            panel(context, transform, i * 8 + 4, j * 8, 13, 4, 4, 2, UP | WEST | SOUTH, autoCull);
            panel(context, transform, i * 8, j * 8 + 4, 13, 4, 4, 2, DOWN | EAST | SOUTH, autoCull);
            panel(context, transform, i * 8 + 4, j * 8 + 4, 13, 4, 4, 2, DOWN | WEST | SOUTH, autoCull);
            panel(context, transform, i * 8, j * 8, 15, 4, 4, 1, UP | EAST | NORTH, autoCull);
            panel(context, transform, i * 8 + 4, j * 8, 15, 4, 4, 1, UP | WEST | NORTH, autoCull);
            panel(context, transform, i * 8, j * 8 + 4, 15, 4, 4, 1, DOWN | EAST | NORTH, autoCull);
            panel(context, transform, i * 8 + 4, j * 8 + 4, 15, 4, 4, 1, DOWN | WEST | NORTH, autoCull);
        } else if (facing == Direction.DOWN) {
            QuadAutoCull autoCull = autoCull(aabb(8, 16, 8).move(i * 8, 0, j * 8));
            flatPanel(context, i * 8, 0, j * 8, 4, 2, 4, UP | EAST | SOUTH, autoCull);
            flatPanel(context, i * 8 + 4, 0, j * 8, 4, 2, 4, UP | WEST | SOUTH, autoCull);
            flatPanel(context, i * 8, 0, j * 8 + 4, 4, 2, 4, UP | EAST | NORTH, autoCull);
            flatPanel(context, i * 8 + 4, 0, j * 8 + 4, 4, 2, 4, UP | WEST | NORTH, autoCull);
            flatPanel(context, i * 8, 2, j * 8, 4, 1, 4, DOWN | EAST | SOUTH, autoCull);
            flatPanel(context, i * 8 + 4, 2, j * 8, 4, 1, 4, DOWN | WEST | SOUTH, autoCull);
            flatPanel(context, i * 8, 2, j * 8 + 4, 4, 1, 4, DOWN | EAST | NORTH, autoCull);
            flatPanel(context, i * 8 + 4, 2, j * 8 + 4, 4, 1, 4, DOWN | WEST | NORTH, autoCull);
        } else if (facing == Direction.UP) {
            QuadAutoCull autoCull = autoCull(aabb(8, 16, 8).move(i * 8, 0, 8 - j * 8));
            int z = 8 - j * 8;
            flatPanel(context, i * 8, 13, z, 4, 2, 4, UP | EAST | SOUTH, autoCull);
            flatPanel(context, i * 8 + 4, 13, z, 4, 2, 4, UP | WEST | SOUTH, autoCull);
            flatPanel(context, i * 8, 13, z + 4, 4, 2, 4, UP | EAST | NORTH, autoCull);
            flatPanel(context, i * 8 + 4, 13, z + 4, 4, 2, 4, UP | WEST | NORTH, autoCull);
            flatPanel(context, i * 8, 15, z, 4, 1, 4, DOWN | EAST | SOUTH, autoCull);
            flatPanel(context, i * 8 + 4, 15, z, 4, 1, 4, DOWN | WEST | SOUTH, autoCull);
            flatPanel(context, i * 8, 15, z + 4, 4, 1, 4, DOWN | EAST | NORTH, autoCull);
            flatPanel(context, i * 8 + 4, 15, z + 4, 4, 1, 4, DOWN | WEST | NORTH, autoCull);
        }
        ci.cancel();
    }

    private static void panel(CopycatRenderContext context, AssemblyTransform transform, int x, int y, int z, int sx, int sy, int sz, int cull, QuadAutoCull autoCull) {
        context.assemblePiece(transform, vec3(x, y, z), aabb(sx, sy, sz).move(x, y, z), cull(cull), autoCull);
    }

    private static void flatPanel(CopycatRenderContext context, int x, int y, int z, int sx, int sy, int sz, int cull, QuadAutoCull autoCull) {
        context.assemblePiece(AssemblyTransform.IDENTITY, vec3(x, y, z), aabb(sx, sy, sz).move(x, y, z), cull(cull), autoCull);
    }

    private static boolean camowarfare$isCamoMaterial(BlockState material) {
        return material != null
            && "camowarfare".equals(material.getBlock().builtInRegistryHolder().key().location().getNamespace());
    }
}
