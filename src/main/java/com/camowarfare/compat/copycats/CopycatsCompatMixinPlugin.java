package com.camowarfare.compat.copycats;

import java.util.List;
import java.util.Set;
import org.objectweb.asm.tree.ClassNode;
import org.spongepowered.asm.mixin.MixinEnvironment;
import org.spongepowered.asm.mixin.extensibility.IMixinConfigPlugin;
import org.spongepowered.asm.mixin.extensibility.IMixinInfo;

public final class CopycatsCompatMixinPlugin implements IMixinConfigPlugin {
    private static final String COPYCATS_MODEL_CORE_RESOURCE =
        "com/copycatsplus/copycats/foundation/copycat/model/CopycatModelCore.class";
    private boolean copycatsAvailable;

    @Override
    public void onLoad(String mixinPackage) {
        this.copycatsAvailable = isResourcePresent(COPYCATS_MODEL_CORE_RESOURCE);
    }

    @Override
    public String getRefMapperConfig() {
        return null;
    }

    @Override
    public boolean shouldApplyMixin(String targetClassName, String mixinClassName) {
        return this.copycatsAvailable
            && MixinEnvironment.getCurrentEnvironment().getSide() == MixinEnvironment.Side.CLIENT
            && isClassPresent(targetClassName);
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

    private static boolean isClassPresent(String className) {
        return className != null && isResourcePresent(className.replace('.', '/') + ".class");
    }

    private static boolean isResourcePresent(String resourcePath) {
        ClassLoader loader = Thread.currentThread().getContextClassLoader();
        return loader != null && loader.getResource(resourcePath) != null;
    }
}
