package com.camowarfare.client;

import com.camowarfare.CamoWarfare;
import com.camowarfare.client.model.ConnectedCamoGeometryLoader;
import net.minecraft.resources.ResourceLocation;
import net.neoforged.api.distmarker.Dist;
import net.neoforged.bus.api.SubscribeEvent;
import net.neoforged.fml.common.EventBusSubscriber;
import net.neoforged.neoforge.client.event.EntityRenderersEvent;
import net.neoforged.neoforge.client.event.ModelEvent;

@EventBusSubscriber(modid = CamoWarfare.MOD_ID, bus = EventBusSubscriber.Bus.MOD, value = Dist.CLIENT)
public final class CamoWarfareClient {
    private CamoWarfareClient() {}

    @SubscribeEvent
    public static void registerGeometryLoaders(ModelEvent.RegisterGeometryLoaders event) {
        event.register(ResourceLocation.fromNamespaceAndPath(CamoWarfare.MOD_ID, "connected_camo"), ConnectedCamoGeometryLoader.INSTANCE);
    }

    @SubscribeEvent
    public static void registerRenderers(EntityRenderersEvent.RegisterRenderers event) {
        event.registerBlockEntityRenderer(CamoWarfare.VEHICLE_HANGING_PLATE_BLOCK_ENTITY.get(), VehicleHangingPlateRenderer::new);
    }
}
