package com.camowarfare;

import net.minecraft.sounds.SoundEvents;
import net.minecraft.world.level.block.SoundType;
import net.minecraft.world.level.block.TrapDoorBlock;
import net.minecraft.world.level.block.state.BlockBehaviour;
import net.minecraft.world.level.block.state.properties.BlockSetType;

public class VehicleDeckHatchBlock extends TrapDoorBlock {
    private static final BlockSetType VEHICLE_HATCH = BlockSetType.register(
        new BlockSetType(
            "camowarfare_vehicle_hatch",
            true,
            true,
            false,
            BlockSetType.PressurePlateSensitivity.EVERYTHING,
            SoundType.METAL,
            SoundEvents.IRON_DOOR_CLOSE,
            SoundEvents.IRON_DOOR_OPEN,
            SoundEvents.IRON_TRAPDOOR_CLOSE,
            SoundEvents.IRON_TRAPDOOR_OPEN,
            SoundEvents.METAL_PRESSURE_PLATE_CLICK_OFF,
            SoundEvents.METAL_PRESSURE_PLATE_CLICK_ON,
            SoundEvents.STONE_BUTTON_CLICK_OFF,
            SoundEvents.STONE_BUTTON_CLICK_ON
        )
    );

    public VehicleDeckHatchBlock(BlockBehaviour.Properties properties) {
        super(VEHICLE_HATCH, properties);
    }
}
