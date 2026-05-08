package com.camowarfare.compat.cbc.mixin;

import com.camowarfare.CamoWarfare;
import net.minecraft.core.registries.Registries;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.tags.TagKey;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.phys.BlockHitResult;
import net.minecraft.world.phys.Vec3;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfoReturnable;
import rbasamoyai.createbigcannons.munitions.AbstractCannonProjectile.ImpactResult;
import rbasamoyai.createbigcannons.munitions.AbstractCannonProjectile.ImpactResult.KinematicOutcome;
import rbasamoyai.createbigcannons.munitions.ProjectileContext;
import rbasamoyai.createbigcannons.munitions.big_cannon.AbstractBigCannonProjectile;

@Mixin(value = AbstractBigCannonProjectile.class, remap = false)
abstract class CreateBigCannonsBigProjectileMixin {
    private static final TagKey<Block> CAMOWARFARE_SLAT_ARMOR_BLOCKS = TagKey.create(
        Registries.BLOCK,
        ResourceLocation.fromNamespaceAndPath(CamoWarfare.MOD_ID, "slat_armor_blocks")
    );
    private static final double SLAT_ARMOR_WEAKEN_CHANCE = 0.35D;
    private static final float SLAT_ARMOR_MASS_SCALE = 0.55F;
    private static final double SLAT_ARMOR_VELOCITY_SCALE = 0.85D;

    @Inject(method = "calculateBlockPenetration", at = @At("HEAD"), cancellable = true, require = 1)
    private void camowarfare$weakenSlatHitsAndPassThrough(
        ProjectileContext context,
        BlockState state,
        BlockHitResult hitResult,
        CallbackInfoReturnable<ImpactResult> cir
    ) {
        if (hitResult == null || context == null) {
            return;
        }
        if (!state.is(CAMOWARFARE_SLAT_ARMOR_BLOCKS)) {
            return;
        }
        AbstractBigCannonProjectile projectile = (AbstractBigCannonProjectile) (Object) this;
        if (projectile.level().random.nextDouble() < SLAT_ARMOR_WEAKEN_CHANCE) {
            projectile.setProjectileMass(projectile.getProjectileMass() * SLAT_ARMOR_MASS_SCALE);
            Vec3 velocity = projectile.getDeltaMovement();
            projectile.setDeltaMovement(velocity.scale(SLAT_ARMOR_VELOCITY_SCALE));
        }
        cir.setReturnValue(new ImpactResult(KinematicOutcome.PENETRATE, false));
    }
}
