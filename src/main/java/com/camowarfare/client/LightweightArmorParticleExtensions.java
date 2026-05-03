package com.camowarfare.client;

import com.camowarfare.SlatArmorBlock;
import net.minecraft.client.multiplayer.ClientLevel;
import net.minecraft.client.particle.ParticleEngine;
import net.minecraft.client.particle.TerrainParticle;
import net.minecraft.core.BlockPos;
import net.minecraft.util.RandomSource;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.phys.AABB;
import net.minecraft.world.phys.BlockHitResult;
import net.minecraft.world.phys.HitResult;
import net.minecraft.world.phys.Vec3;
import net.minecraft.world.phys.shapes.VoxelShape;
import net.neoforged.neoforge.client.extensions.common.IClientBlockExtensions;

final class LightweightArmorParticleExtensions implements IClientBlockExtensions {
    static final LightweightArmorParticleExtensions INSTANCE = new LightweightArmorParticleExtensions();

    private LightweightArmorParticleExtensions() {}

    @Override
    public boolean addHitEffects(BlockState state, Level level, HitResult target, ParticleEngine manager) {
        if (!(level instanceof ClientLevel clientLevel) || !(target instanceof BlockHitResult blockHit)) {
            return true;
        }

        BlockPos pos = blockHit.getBlockPos();
        Vec3 hit = blockHit.getLocation();
        addParticle(clientLevel, manager, state, pos, hit.x, hit.y, hit.z, 0.0, 0.0, 0.0, 0.45F);
        return true;
    }

    @Override
    public boolean addDestroyEffects(BlockState state, Level level, BlockPos pos, ParticleEngine manager) {
        if (!(level instanceof ClientLevel clientLevel) || !state.shouldSpawnTerrainParticles()) {
            return true;
        }

        RandomSource random = clientLevel.random;
        AABB bounds = bounds(state, clientLevel, pos);
        int count = state.getBlock() instanceof SlatArmorBlock ? 14 : 8;
        for (int i = 0; i < count; i++) {
            double x = pos.getX() + randomBetween(random, bounds.minX, bounds.maxX);
            double y = pos.getY() + randomBetween(random, bounds.minY, bounds.maxY);
            double z = pos.getZ() + randomBetween(random, bounds.minZ, bounds.maxZ);
            double xSpeed = (random.nextDouble() - 0.5) * 0.18;
            double ySpeed = random.nextDouble() * 0.12;
            double zSpeed = (random.nextDouble() - 0.5) * 0.18;
            addParticle(clientLevel, manager, state, pos, x, y, z, xSpeed, ySpeed, zSpeed, 0.7F);
        }
        return true;
    }

    private static AABB bounds(BlockState state, ClientLevel level, BlockPos pos) {
        VoxelShape shape = state.getShape(level, pos);
        return shape.isEmpty() ? new AABB(0.25, 0.25, 0.25, 0.75, 0.75, 0.75) : shape.bounds();
    }

    private static double randomBetween(RandomSource random, double min, double max) {
        return min + random.nextDouble() * Math.max(0.01, max - min);
    }

    private static void addParticle(
        ClientLevel level,
        ParticleEngine manager,
        BlockState state,
        BlockPos pos,
        double x,
        double y,
        double z,
        double xSpeed,
        double ySpeed,
        double zSpeed,
        float scale
    ) {
        TerrainParticle particle = new TerrainParticle(level, x, y, z, xSpeed, ySpeed, zSpeed, state, pos);
        manager.add(particle.updateSprite(state, pos).setPower(0.18F).scale(scale));
    }
}
