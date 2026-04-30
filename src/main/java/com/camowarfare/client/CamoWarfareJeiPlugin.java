package com.camowarfare.client;

import com.camowarfare.CamoWarfare;
import java.util.List;
import mezz.jei.api.IModPlugin;
import mezz.jei.api.JeiPlugin;
import mezz.jei.api.constants.VanillaTypes;
import mezz.jei.api.runtime.IIngredientManager;
import mezz.jei.api.runtime.IJeiRuntime;
import net.minecraft.core.registries.BuiltInRegistries;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.world.item.ItemStack;

@JeiPlugin
public final class CamoWarfareJeiPlugin implements IModPlugin {
    private static final ResourceLocation PLUGIN_UID =
        ResourceLocation.fromNamespaceAndPath(CamoWarfare.MOD_ID, "jei_plugin");

    @Override
    public ResourceLocation getPluginUid() {
        return PLUGIN_UID;
    }

    @Override
    public void onRuntimeAvailable(IJeiRuntime jeiRuntime) {
        IIngredientManager ingredientManager = jeiRuntime.getIngredientManager();
        List<ItemStack> markerStacks = BuiltInRegistries.ITEM.stream()
            .filter(item -> {
                ResourceLocation key = BuiltInRegistries.ITEM.getKey(item);
                return CamoWarfare.MOD_ID.equals(key.getNamespace()) && key.getPath().startsWith("section_");
            })
            .map(item -> new ItemStack(item))
            .filter(stack -> !stack.isEmpty())
            .toList();

        if (!markerStacks.isEmpty()) {
            ingredientManager.removeIngredientsAtRuntime(VanillaTypes.ITEM_STACK, markerStacks);
        }
    }
}
