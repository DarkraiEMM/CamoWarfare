package com.camowarfare.client.model;

import com.google.gson.JsonDeserializationContext;
import com.google.gson.JsonObject;
import net.minecraft.util.GsonHelper;
import net.neoforged.neoforge.client.model.geometry.IGeometryLoader;

public final class ConnectedCamoGeometryLoader implements IGeometryLoader<ConnectedCamoGeometry> {
    public static final ConnectedCamoGeometryLoader INSTANCE = new ConnectedCamoGeometryLoader();

    private ConnectedCamoGeometryLoader() {}

    @Override
    public ConnectedCamoGeometry read(JsonObject jsonObject, JsonDeserializationContext deserializationContext) {
        return new ConnectedCamoGeometry(
            GsonHelper.getAsBoolean(jsonObject, "item_render", false),
            GsonHelper.getAsBoolean(jsonObject, "position_tiled", false),
            GsonHelper.getAsInt(jsonObject, "position_tile_pixels", 32)
        );
    }
}
