package com.camowarfare.compat.cbc.mixin;

import com.camowarfare.CamoWarfare;
import net.minecraft.core.BlockPos;
import net.minecraft.core.registries.Registries;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.tags.TagKey;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.phys.BlockHitResult;
import net.minecraft.world.phys.Vec3;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.Shadow;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Redirect;
import rbasamoyai.createbigcannons.munitions.AbstractCannonProjectile;
import rbasamoyai.createbigcannons.munitions.AbstractCannonProjectile.ImpactResult;
import rbasamoyai.createbigcannons.munitions.AbstractCannonProjectile.ImpactResult.KinematicOutcome;
import rbasamoyai.createbigcannons.munitions.ProjectileContext;

@Mixin(value = AbstractCannonProjectile.class, remap = false)
abstract class CreateBigCannonsProjectileMixin {
    private static final float REACTIVE_ARMOR_EFFECT_POWER = 1.2F;
    private static final TagKey<Block> CAMOWARFARE_ADD_ON_ARMOR_BLOCKS = TagKey.create(
        Registries.BLOCK,
        ResourceLocation.fromNamespaceAndPath(CamoWarfare.MOD_ID, "add_on_armor_blocks")
    );

    @Shadow
    protected abstract ImpactResult calculateBlockPenetration(
        ProjectileContext projectileContext,
        BlockState state,
        BlockHitResult blockHitResult
    );

    @Redirect(
        method = "clipAndDamage",
        at = @At(
            value = "INVOKE",
            target = "Lrbasamoyai/createbigcannons/munitions/AbstractCannonProjectile;calculateBlockPenetration(Lrbasamoyai/createbigcannons/munitions/ProjectileContext;Lnet/minecraft/world/level/block/state/BlockState;Lnet/minecraft/world/phys/BlockHitResult;)Lrbasamoyai/createbigcannons/munitions/AbstractCannonProjectile$ImpactResult;"
        ),
        require = 1
    )
    private ImpactResult camowarfare$reactiveArmorConsumesProjectile(
        AbstractCannonProjectile projectile,
        ProjectileContext context,
        BlockState state,
        BlockHitResult hitResult
    ) {
        if (hitResult == null || context == null || !state.is(CAMOWARFARE_ADD_ON_ARMOR_BLOCKS)) {
            return this.calculateBlockPenetration(context, state, hitResult);
        }
        if (!projectile.level().isClientSide) {
            BlockPos pos = hitResult.getBlockPos();
            projectile.level().destroyBlock(pos, false, projectile);
            Vec3 effectPos = hitResult.getLocation();
            projectile.level().explode(
                projectile,
                effectPos.x,
                effectPos.y,
                effectPos.z,
                REACTIVE_ARMOR_EFFECT_POWER,
                false,
                Level.ExplosionInteraction.NONE
            );
        }
        projectile.setProjectileMass(0);
        return new ImpactResult(KinematicOutcome.STOP, true);
    }
}
