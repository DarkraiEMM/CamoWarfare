package com.camowarfare;

import java.lang.reflect.Constructor;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.lang.reflect.Proxy;
import java.util.Collections;
import java.util.OptionalInt;
import java.util.function.Consumer;
import java.util.function.Function;
import net.minecraft.core.BlockPos;
import net.minecraft.network.FriendlyByteBuf;
import net.minecraft.world.MenuProvider;
import net.minecraft.world.SimpleMenuProvider;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.inventory.AbstractContainerMenu;
import net.minecraft.world.item.ItemStack;

final class SophisticatedBackpacksCompat {
    private static final String HANDLER_NAME = "camowarfare_hanging_plate";
    private static boolean registrationAttempted;
    private static boolean registered;

    private SophisticatedBackpacksCompat() {
    }

    static void registerInventoryHandler() {
        if (registrationAttempted) {
            return;
        }
        registrationAttempted = true;
        try {
            Class<?> providerClass = Class.forName("net.p3pp3rf1y.sophisticatedbackpacks.util.PlayerInventoryProvider");
            Class<?> slotCountGetterClass = Class.forName("net.p3pp3rf1y.sophisticatedbackpacks.util.PlayerInventoryHandler$SlotCountGetter");
            Class<?> slotStackGetterClass = Class.forName("net.p3pp3rf1y.sophisticatedbackpacks.util.PlayerInventoryHandler$SlotStackGetter");

            Object provider = providerClass.getMethod("get").invoke(null);
            Object slotCountGetter = Proxy.newProxyInstance(
                slotCountGetterClass.getClassLoader(),
                new Class<?>[] {slotCountGetterClass},
                (proxy, method, args) -> 2
            );
            Object slotStackGetter = Proxy.newProxyInstance(
                slotStackGetterClass.getClassLoader(),
                new Class<?>[] {slotStackGetterClass},
                (proxy, method, args) -> mountedStack((Player) args[0], (String) args[1], (Integer) args[2])
            );
            Function<Object, java.util.Set<String>> identifiers = ignored -> Collections.emptySet();

            Method addHandler = providerClass.getMethod(
                "addPlayerInventoryHandler",
                String.class,
                Function.class,
                slotCountGetterClass,
                slotStackGetterClass,
                boolean.class,
                boolean.class,
                boolean.class,
                boolean.class
            );
            addHandler.invoke(provider, HANDLER_NAME, identifiers, slotCountGetter, slotStackGetter, false, false, true, false);
            registered = true;
        } catch (ClassNotFoundException ignored) {
            registered = false;
        } catch (ReflectiveOperationException | RuntimeException exception) {
            registered = false;
            CamoWarfare.LOGGER.warn("Unable to register Sophisticated Backpacks hanging plate handler", exception);
        }
    }

    static boolean openBackpack(Player player, VehicleHangingPlateBlockEntity blockEntity, int slot) {
        registerInventoryHandler();
        if (!registered) {
            return false;
        }

        try {
            Class<?> contextClass = Class.forName("net.p3pp3rf1y.sophisticatedbackpacks.common.gui.BackpackContext");
            Class<?> itemContextClass = Class.forName("net.p3pp3rf1y.sophisticatedbackpacks.common.gui.BackpackContext$Item");
            Class<?> containerClass = Class.forName("net.p3pp3rf1y.sophisticatedbackpacks.common.gui.BackpackContainer");
            Constructor<?> contextConstructor = itemContextClass.getConstructor(String.class, String.class, int.class, boolean.class);
            Object context = contextConstructor.newInstance(HANDLER_NAME, identifier(blockEntity), slot, false);
            Constructor<?> containerConstructor = containerClass.getConstructor(int.class, Player.class, contextClass);
            Method toBuffer = contextClass.getMethod("toBuffer", FriendlyByteBuf.class);

            MenuProvider provider = new SimpleMenuProvider(
                (containerId, inventory, menuPlayer) -> createContainer(containerConstructor, containerId, menuPlayer, context),
                blockEntity.mount(slot).getHoverName()
            );
            OptionalInt menuId = player.openMenu(provider, buffer -> writeContext(toBuffer, context, buffer));
            return menuId.isPresent();
        } catch (ClassNotFoundException ignored) {
            return false;
        } catch (ReflectiveOperationException | RuntimeException exception) {
            CamoWarfare.LOGGER.warn("Unable to open Sophisticated Backpacks mounted backpack", exception);
            return false;
        }
    }

    private static AbstractContainerMenu createContainer(Constructor<?> constructor, int containerId, Player player, Object context) {
        try {
            return (AbstractContainerMenu) constructor.newInstance(containerId, player, context);
        } catch (InstantiationException | IllegalAccessException | InvocationTargetException exception) {
            throw new IllegalStateException("Unable to create Sophisticated Backpacks container", exception);
        }
    }

    private static void writeContext(Method toBuffer, Object context, FriendlyByteBuf buffer) {
        try {
            toBuffer.invoke(context, buffer);
        } catch (IllegalAccessException | InvocationTargetException exception) {
            throw new IllegalStateException("Unable to write Sophisticated Backpacks context", exception);
        }
    }

    private static ItemStack mountedStack(Player player, String identifier, int slot) {
        VehicleHangingPlateBlockEntity blockEntity = findBlockEntity(player, identifier);
        if (blockEntity == null || !blockEntity.hasMount(slot)) {
            return ItemStack.EMPTY;
        }
        blockEntity.markMountedStackChanged();
        return blockEntity.mount(slot);
    }

    private static VehicleHangingPlateBlockEntity findBlockEntity(Player player, String identifier) {
        String[] parts = identifier.split(",");
        if (parts.length != 3) {
            return null;
        }
        try {
            BlockPos pos = new BlockPos(Integer.parseInt(parts[0]), Integer.parseInt(parts[1]), Integer.parseInt(parts[2]));
            return player.level().getBlockEntity(pos) instanceof VehicleHangingPlateBlockEntity blockEntity ? blockEntity : null;
        } catch (NumberFormatException exception) {
            return null;
        }
    }

    private static String identifier(VehicleHangingPlateBlockEntity blockEntity) {
        BlockPos pos = blockEntity.getBlockPos();
        return pos.getX() + "," + pos.getY() + "," + pos.getZ();
    }
}
