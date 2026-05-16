package com.camowarfare.mixin;

import com.camowarfare.client.CreativeDividerRenderer;
import net.minecraft.client.gui.GuiGraphics;
import net.minecraft.client.gui.screens.inventory.AbstractContainerScreen;
import net.minecraft.client.gui.screens.inventory.CreativeModeInventoryScreen;
import net.minecraft.world.inventory.Slot;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

@Mixin(AbstractContainerScreen.class)
abstract class AbstractContainerScreenMixin {
    @Inject(method = "renderSlot", at = @At("HEAD"), cancellable = true)
    private void camowarfare$hideDividerSlots(GuiGraphics guiGraphics, Slot slot, CallbackInfo ci) {
        if ((Object) this instanceof CreativeModeInventoryScreen && CreativeDividerRenderer.isDividerSlot(slot)) {
            ci.cancel();
        }
    }

    @Inject(method = "renderSlotHighlight(Lnet/minecraft/client/gui/GuiGraphics;Lnet/minecraft/world/inventory/Slot;IIF)V", at = @At("HEAD"), cancellable = true)
    private void camowarfare$hideDividerHighlight(GuiGraphics guiGraphics, Slot slot, int mouseX, int mouseY, float partialTick, CallbackInfo ci) {
        if ((Object) this instanceof CreativeModeInventoryScreen && CreativeDividerRenderer.isDividerSlot(slot)) {
            ci.cancel();
        }
    }
}
