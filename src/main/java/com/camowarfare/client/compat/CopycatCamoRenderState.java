package com.camowarfare.client.compat;

public final class CopycatCamoRenderState {
    private static final ThreadLocal<Boolean> CAMO_MATERIAL = ThreadLocal.withInitial(() -> false);

    private CopycatCamoRenderState() {
    }

    public static void setCamoMaterial(boolean value) {
        CAMO_MATERIAL.set(value);
    }

    public static boolean hasCamoMaterial() {
        return CAMO_MATERIAL.get();
    }
}
