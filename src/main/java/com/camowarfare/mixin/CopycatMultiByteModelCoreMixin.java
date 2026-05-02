package com.camowarfare.mixin;

import com.copycatsplus.copycats.content.copycat.bytes.CopycatByteBlock;
import com.copycatsplus.copycats.content.copycat.bytes.CopycatMultiByteModelCore;
import com.copycatsplus.copycats.foundation.copycat.model.assembly.AssemblyTransform;
import com.copycatsplus.copycats.foundation.copycat.model.assembly.CopycatRenderContext;
import com.copycatsplus.copycats.foundation.copycat.model.assembly.quad.QuadAutoCull;
import java.util.HashMap;
import java.util.Map;
import net.minecraft.world.level.block.state.BlockState;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

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

@Mixin(value = CopycatMultiByteModelCore.class, remap = false)
abstract class CopycatMultiByteModelCoreMixin {
    private static final Map<String, CopycatByteBlock.Byte> BYTE_BY_KEY = camowarfare$byteByKey();

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
        CopycatByteBlock.Byte bite = BYTE_BY_KEY.get(key);
        if (bite == null || !state.getValue(CopycatByteBlock.byByte(bite))) {
            ci.cancel();
            return;
        }

        int x = bite.x() ? 8 : 0;
        int y = bite.y() ? 8 : 0;
        int z = bite.z() ? 8 : 0;
        QuadAutoCull autoCull = autoCull(aabb(8, 8, 8).move(x, y, z));
        piece(context, x, y, z, UP | EAST | SOUTH, autoCull);
        piece(context, x + 4, y, z, UP | WEST | SOUTH, autoCull);
        piece(context, x, y, z + 4, UP | EAST | NORTH, autoCull);
        piece(context, x + 4, y, z + 4, UP | WEST | NORTH, autoCull);
        piece(context, x, y + 4, z, DOWN | EAST | SOUTH, autoCull);
        piece(context, x + 4, y + 4, z, DOWN | WEST | SOUTH, autoCull);
        piece(context, x, y + 4, z + 4, DOWN | EAST | NORTH, autoCull);
        piece(context, x + 4, y + 4, z + 4, DOWN | WEST | NORTH, autoCull);
        ci.cancel();
    }

    private static void piece(CopycatRenderContext context, int x, int y, int z, int cull, QuadAutoCull autoCull) {
        context.assemblePiece(AssemblyTransform.IDENTITY, vec3(x, y, z), aabb(4, 4, 4).move(x, y, z), cull(cull), autoCull);
    }

    private static Map<String, CopycatByteBlock.Byte> camowarfare$byteByKey() {
        Map<String, CopycatByteBlock.Byte> map = new HashMap<>();
        for (CopycatByteBlock.Byte bite : CopycatByteBlock.allBytes) {
            map.put(CopycatByteBlock.byByte(bite).getName(), bite);
        }
        return Map.copyOf(map);
    }

    private static boolean camowarfare$isCamoMaterial(BlockState material) {
        return material != null
            && "camowarfare".equals(material.getBlock().builtInRegistryHolder().key().location().getNamespace());
    }
}
