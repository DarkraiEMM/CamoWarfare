package com.camowarfare.mixin;

import com.camowarfare.client.compat.CopycatCamoRenderState;
import com.copycatsplus.copycats.foundation.copycat.model.CopycatModelCore;
import com.copycatsplus.copycats.foundation.copycat.model.neoforge.CopycatModelNeoForge;
import com.mojang.logging.LogUtils;
import net.minecraft.util.RandomSource;
import net.minecraft.world.level.block.state.BlockState;
import net.neoforged.neoforge.client.model.data.ModelData;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.Shadow;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;
import org.slf4j.Logger;

@Mixin(value = CopycatModelNeoForge.class, remap = false)
abstract class CopycatModelNeoForgeMixin {
    private static final Logger LOGGER = LogUtils.getLogger();
    private static boolean camowarfare$loggedCamoMaterial = false;

    @Shadow
    protected CopycatModelCore core;

    @Inject(
        method = "prepareModelCore(Lnet/minecraft/world/level/block/state/BlockState;Lnet/minecraft/util/RandomSource;Lnet/neoforged/neoforge/client/model/data/ModelData;)V",
        at = @At("TAIL"),
        require = 1
    )
    private void camowarfare$disableEnhancedModelsForCamo(
        BlockState state,
        RandomSource rand,
        ModelData data,
        CallbackInfo ci
    ) {
        CopycatCamoRenderState.setCamoMaterial(false);
        for (BlockState material : CopycatModelNeoForge.getMaterials(data).values()) {
            if ("camowarfare".equals(material.getBlock().builtInRegistryHolder().key().location().getNamespace())) {
                CopycatCamoRenderState.setCamoMaterial(true);
                if (!camowarfare$loggedCamoMaterial) {
                    camowarfare$loggedCamoMaterial = true;
                    LOGGER.info("[camowarfare] Copycats material detected: {}, disabling enhanced model for this render",
                        material.getBlock().builtInRegistryHolder().key().location());
                }
                core.enhanced = false;
                return;
            }
        }
    }
}
