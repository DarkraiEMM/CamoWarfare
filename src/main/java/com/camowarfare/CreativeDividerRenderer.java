package com.camowarfare;

import java.util.List;
import java.util.Map;
import net.minecraft.client.Minecraft;
import net.minecraft.client.gui.Font;
import net.minecraft.client.gui.GuiGraphics;
import net.minecraft.core.registries.BuiltInRegistries;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.world.inventory.AbstractContainerMenu;
import net.minecraft.world.inventory.Slot;
import net.minecraft.world.item.CreativeModeTab;
import net.minecraft.world.item.Item;
import net.minecraft.world.item.ItemStack;

public final class CreativeDividerRenderer {
    private static final int SLOT_GRID_WIDTH = 9;
    private static final int SLOT_STRIDE = 18;
    private static final int SEGMENT_SIZE = 18;
    private static final int TEXTURE_SIZE = 512;
    private static final int LABEL_X = 12;
    private static final int LABEL_Y = 5;
    private static final int LABEL_COLOR = 0xFFF1E6C5;
    private static final int SHADOW_COLOR = 0xAA1C1810;

    private CreativeDividerRenderer() {
    }

    public static boolean isCamoTab(CreativeModeTab tab) {
        return tab == CamoWarfare.CAMO_TAB.get();
    }

    public static boolean isDividerSlot(Slot slot) {
        return slot != null && slot.hasItem() && isMarkerItem(slot.getItem());
    }

    public static boolean isDividerItem(ItemStack stack) {
        return !stack.isEmpty() && parseSectionToken(stack) != null;
    }

    public static boolean isMarkerItem(ItemStack stack) {
        if (stack.isEmpty()) {
            return false;
        }

        if (isDividerItem(stack)) {
            return true;
        }

        ResourceLocation key = BuiltInRegistries.ITEM.getKey(stack.getItem());
        return CamoWarfare.MOD_ID.equals(key.getNamespace()) && key.getPath().startsWith("section_spacer");
    }

    public static void renderVisibleRows(GuiGraphics guiGraphics, AbstractContainerMenu menu, int leftPos, int topPos) {
        for (DividerRow row : collectVisibleRows(menu)) {
            drawBanner(guiGraphics, leftPos, topPos, row);
            drawLabel(guiGraphics, leftPos, topPos, row);
        }
    }

    private static List<DividerRow> collectVisibleRows(AbstractContainerMenu menu) {
        Map<Integer, List<Slot>> rowsByY = menu.slots.stream()
            .filter(Slot::isActive)
            .filter(slot -> slot.index >= 0 && slot.index < 45 && slot.container.getContainerSize() == 45)
            .collect(java.util.stream.Collectors.groupingBy(slot -> slot.y));

        return rowsByY.values()
            .stream()
            .map(CreativeDividerRenderer::tryBuildRow)
            .filter(java.util.Objects::nonNull)
            .sorted(java.util.Comparator.comparingInt(DividerRow::y).thenComparingInt(DividerRow::x))
            .toList();
    }

    private static DividerRow tryBuildRow(List<Slot> rowSlots) {
        if (rowSlots.isEmpty()) {
            return null;
        }

        rowSlots.sort(java.util.Comparator.comparingInt(slot -> slot.x));
        for (int i = 0; i < rowSlots.size(); i++) {
            Slot slot = rowSlots.get(i);
            SectionToken startToken = parseSectionToken(slot.getItem());
            if (startToken == null) {
                continue;
            }

            CreativeSection section = CreativeSection.fromId(startToken.sectionId());
            if (section == null) {
                continue;
            }

            int nextFillIndex = startToken.kind() == SectionTokenKind.TITLE ? 1 : startToken.fillIndex() + 1;
            int segments = 1;
            for (int j = i + 1; j < rowSlots.size(); j++) {
                SectionToken token = parseSectionToken(rowSlots.get(j).getItem());
                if (token == null
                    || token.kind() != SectionTokenKind.FILL
                    || token.fillIndex() != nextFillIndex
                    || !startToken.sectionId().equals(token.sectionId())) {
                    break;
                }
                segments++;
                nextFillIndex++;
            }

            return new DividerRow(
                section,
                slot.x - 1,
                slot.y - 1,
                startToken.kind() == SectionTokenKind.TITLE ? 0 : startToken.fillIndex(),
                segments,
                startToken.kind() == SectionTokenKind.TITLE
            );
        }
        return null;
    }

    private static void drawBanner(GuiGraphics guiGraphics, int leftPos, int topPos, DividerRow row) {
        for (int i = 0; i < row.segments(); i++) {
            int segmentIndex = row.startSegment() + i;
            guiGraphics.blit(
                bannerTexture(row.section().id(), segmentIndex == 0, segmentIndex),
                leftPos + row.x() + (i * SLOT_STRIDE),
                topPos + row.y(),
                0,
                0,
                SEGMENT_SIZE,
                SEGMENT_SIZE,
                TEXTURE_SIZE,
                TEXTURE_SIZE
            );
        }
    }

    private static void drawLabel(GuiGraphics guiGraphics, int leftPos, int topPos, DividerRow row) {
        if (!row.drawLabel()) {
            return;
        }

        Minecraft minecraft = Minecraft.getInstance();
        Font font = minecraft.font;
        String languageCode = minecraft.getLanguageManager().getSelected();
        boolean chineseUi = languageCode.equals("zh_cn") || languageCode.startsWith("zh_");
        String label = row.section().displayLabel(chineseUi);
        int x = leftPos + row.x() + LABEL_X;
        int y = topPos + row.y() + LABEL_Y;

        guiGraphics.pose().pushPose();
        guiGraphics.pose().translate(0.0F, 0.0F, 250.0F);
        guiGraphics.drawString(font, label, x + 1, y + 1, SHADOW_COLOR, false);
        guiGraphics.drawString(font, label, x, y, LABEL_COLOR, false);
        guiGraphics.pose().popPose();
    }

    private static ResourceLocation bannerTexture(String sectionId, boolean title, int fillIndex) {
        String name = title ? "section_" + sectionId + "_title" : "section_" + sectionId + "_fill_" + fillIndex;
        return ResourceLocation.fromNamespaceAndPath(CamoWarfare.MOD_ID, "textures/item/" + name + ".png");
    }

    private static SectionToken parseSectionToken(ItemStack stack) {
        Item item = stack.getItem();
        ResourceLocation key = BuiltInRegistries.ITEM.getKey(item);
        if (!CamoWarfare.MOD_ID.equals(key.getNamespace())) {
            return null;
        }

        String path = key.getPath();
        if (!path.startsWith("section_")) {
            return null;
        }

        if (path.endsWith("_title")) {
            return new SectionToken(path.substring("section_".length(), path.length() - "_title".length()), SectionTokenKind.TITLE, 0);
        }

        int fillAt = path.lastIndexOf("_fill_");
        if (fillAt < 0) {
            return null;
        }

        String sectionId = path.substring("section_".length(), fillAt);
        String fillIndexText = path.substring(fillAt + "_fill_".length());
        try {
            return new SectionToken(sectionId, SectionTokenKind.FILL, Integer.parseInt(fillIndexText));
        } catch (NumberFormatException ignored) {
            return null;
        }
    }

    private record DividerRow(CreativeSection section, int x, int y, int startSegment, int segments, boolean drawLabel) {
    }

    private record SectionToken(String sectionId, SectionTokenKind kind, int fillIndex) {
    }

    private enum SectionTokenKind {
        TITLE,
        FILL
    }
}
