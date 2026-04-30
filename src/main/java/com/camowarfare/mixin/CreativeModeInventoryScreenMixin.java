package com.camowarfare.mixin;

import com.camowarfare.CreativeDividerRenderer;
import java.util.List;
import net.minecraft.client.gui.GuiGraphics;
import net.minecraft.client.gui.screens.inventory.CreativeModeInventoryScreen;
import net.minecraft.network.chat.Component;
import net.minecraft.world.inventory.ClickType;
import net.minecraft.world.inventory.Slot;
import net.minecraft.world.item.CreativeModeTab;
import net.minecraft.world.item.ItemStack;
import org.spongepowered.asm.mixin.Final;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.Shadow;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfoReturnable;

@Mixin(CreativeModeInventoryScreen.class)
abstract class CreativeModeInventoryScreenMixin {
    @Shadow
    @Final
    private static CreativeModeTab selectedTab;

    @Inject(
        method = "render",
        at = @At(
            value = "INVOKE",
            target = "Lnet/minecraft/client/gui/screens/inventory/CreativeModeInventoryScreen;renderTooltip(Lnet/minecraft/client/gui/GuiGraphics;II)V"
        )
    )
    private void camowarfare$renderSectionBanners(GuiGraphics guiGraphics, int mouseX, int mouseY, float partialTick, CallbackInfo ci) {
        if (CreativeDividerRenderer.isCamoTab(selectedTab)) {
            AbstractContainerScreenAccessor accessor = (AbstractContainerScreenAccessor) this;
            CreativeDividerRenderer.renderVisibleRows(
                guiGraphics,
                accessor.camowarfare$getMenu(),
                accessor.camowarfare$getLeftPos(),
                accessor.camowarfare$getTopPos()
            );
        }
    }

    @Inject(method = "getTooltipFromContainerItem", at = @At("HEAD"), cancellable = true)
    private void camowarfare$suppressDividerTooltips(ItemStack stack, CallbackInfoReturnable<List<Component>> cir) {
        if (CreativeDividerRenderer.isCamoTab(selectedTab) && CreativeDividerRenderer.isMarkerItem(stack)) {
            cir.setReturnValue(List.of());
        }
    }

    @Inject(method = "slotClicked", at = @At("HEAD"), cancellable = true)
    private void camowarfare$ignoreDividerClicks(Slot slot, int slotId, int mouseButton, ClickType type, CallbackInfo ci) {
        if (CreativeDividerRenderer.isCamoTab(selectedTab) && CreativeDividerRenderer.isDividerSlot(slot)) {
            AbstractContainerScreenAccessor accessor = (AbstractContainerScreenAccessor) this;
            ItemStack carried = accessor.camowarfare$getMenu().getCarried();
            if (type == ClickType.PICKUP && !carried.isEmpty()) {
                if (mouseButton == 0) {
                    accessor.camowarfare$getMenu().setCarried(ItemStack.EMPTY);
                } else if (mouseButton == 1) {
                    carried.shrink(1);
                    if (carried.isEmpty()) {
                        accessor.camowarfare$getMenu().setCarried(ItemStack.EMPTY);
                    }
                }
            }
            ci.cancel();
        }
    }
}
