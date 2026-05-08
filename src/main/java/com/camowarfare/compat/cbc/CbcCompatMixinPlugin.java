package com.camowarfare.compat.cbc;

import java.util.List;
import java.util.Set;
import org.objectweb.asm.tree.ClassNode;
import org.spongepowered.asm.mixin.extensibility.IMixinConfigPlugin;
import org.spongepowered.asm.mixin.extensibility.IMixinInfo;

public final class CbcCompatMixinPlugin implements IMixinConfigPlugin {
    private static final String CBC_PROJECTILE_RESOURCE = "rbasamoyai/createbigcannons/munitions/AbstractCannonProjectile.class";
    private boolean cbcAvailable;

    @Override
    public void onLoad(String mixinPackage) {
        this.cbcAvailable = isResourcePresent(CBC_PROJECTILE_RESOURCE);
    }

    @Override
    public String getRefMapperConfig() {
        return null;
    }

    @Override
    public boolean shouldApplyMixin(String targetClassName, String mixinClassName) {
        return this.cbcAvailable;
    }

    @Override
    public void acceptTargets(Set<String> myTargets, Set<String> otherTargets) {
    }

    @Override
    public List<String> getMixins() {
        return null;
    }

    @Override
    public void preApply(String targetClassName, ClassNode targetClass, String mixinClassName, IMixinInfo mixinInfo) {
    }

    @Override
    public void postApply(String targetClassName, ClassNode targetClass, String mixinClassName, IMixinInfo mixinInfo) {
    }

    private static boolean isResourcePresent(String resourcePath) {
        ClassLoader loader = Thread.currentThread().getContextClassLoader();
        return loader != null && loader.getResource(resourcePath) != null;
    }
}
