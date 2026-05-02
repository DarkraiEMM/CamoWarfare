package com.camowarfare.client.compat;

import java.util.concurrent.atomic.AtomicBoolean;

public final class CopycatCamoRenderState {
    private static final AtomicBoolean CAMO_MATERIAL = new AtomicBoolean(false);

    private CopycatCamoRenderState() {
    }

    public static void setCamoMaterial(boolean value) {
        CAMO_MATERIAL.set(value);
    }

    public static boolean hasCamoMaterial() {
        return CAMO_MATERIAL.get();
    }
}
