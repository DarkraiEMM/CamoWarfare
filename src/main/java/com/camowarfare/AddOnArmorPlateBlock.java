package com.camowarfare;

import com.mojang.serialization.MapCodec;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.state.BlockBehaviour;

public class AddOnArmorPlateBlock extends FaceMountedAttachmentBlock {
    public static final MapCodec<AddOnArmorPlateBlock> CODEC = simpleCodec(AddOnArmorPlateBlock::new);

    public AddOnArmorPlateBlock(BlockBehaviour.Properties properties) {
        super(
            properties,
            Block.box(1, 3, 13, 15, 13, 16),
            Block.box(1, 3, 0, 15, 13, 3),
            Block.box(13, 3, 1, 16, 13, 15),
            Block.box(0, 3, 1, 3, 13, 15)
        );
    }

    @Override
    protected MapCodec<? extends AddOnArmorPlateBlock> codec() {
        return CODEC;
    }
}
