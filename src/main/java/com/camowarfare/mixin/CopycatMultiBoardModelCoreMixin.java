package com.camowarfare.mixin;

import com.copycatsplus.copycats.content.copycat.board.CopycatBoardBlock;
import com.copycatsplus.copycats.content.copycat.board.CopycatMultiBoardModelCore;
import com.copycatsplus.copycats.foundation.copycat.model.assembly.CopycatRenderContext;
import java.util.EnumMap;
import java.util.Locale;
import java.util.Map;
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

@Mixin(value = CopycatMultiBoardModelCore.class, remap = false)
abstract class CopycatMultiBoardModelCoreMixin {
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

        Map<Direction, Boolean> sides = new EnumMap<>(Direction.class);
        for (Direction direction : Direction.values()) {
            sides.put(direction, state.getValue(CopycatBoardBlock.byDirection(direction)));
        }

        Direction direction = Direction.byName(key.toLowerCase(Locale.ROOT));
        if (direction == null || !sides.get(direction)) {
            ci.cancel();
            return;
        }

        if (direction.getAxis().isVertical()) {
            context.assemblePiece(
                t -> t.flipY(direction == Direction.UP),
                vec3(0, 0, 0),
                aabb(16, 1, 16).move(0, 0, 0),
                cull((NORTH * i(sides.get(Direction.NORTH))) |
                    (SOUTH * i(sides.get(Direction.SOUTH))) |
                    (EAST * i(sides.get(Direction.EAST))) |
                    (WEST * i(sides.get(Direction.WEST))))
            );
        } else {
            Direction right = direction.getClockWise();
            Direction left = direction.getCounterClockWise();
            context.assemblePiece(
                t -> t.rotateY((int) direction.toYRot() + 180),
                vec3(0, 0, 0),
                aabb(16, 16, 1).move(0, 0, 0),
                cull((UP * i(sides.get(Direction.UP))) |
                    (DOWN * i(sides.get(Direction.DOWN))) |
                    (EAST * i(sides.get(right))) |
                    (WEST * i(sides.get(left))))
            );
        }
        ci.cancel();
    }

    private static int i(boolean value) {
        return value ? 1 : 0;
    }

    private static boolean camowarfare$isCamoMaterial(BlockState material) {
        return material != null
            && "camowarfare".equals(material.getBlock().builtInRegistryHolder().key().location().getNamespace());
    }
}
