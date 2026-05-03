package com.camowarfare;

import java.util.EnumMap;
import java.util.List;
import java.util.Map;
import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.network.RegistryFriendlyByteBuf;
import net.minecraft.network.codec.StreamCodec;
import net.minecraft.network.protocol.common.custom.CustomPacketPayload;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.server.level.ServerPlayer;
import net.minecraft.world.level.ChunkPos;
import net.neoforged.bus.api.SubscribeEvent;
import net.neoforged.fml.common.EventBusSubscriber;
import net.neoforged.neoforge.event.level.BlockEvent;
import net.neoforged.neoforge.event.entity.player.PlayerEvent;
import net.neoforged.neoforge.network.PacketDistributor;
import net.neoforged.neoforge.network.event.RegisterPayloadHandlersEvent;
import net.neoforged.neoforge.network.handling.IPayloadContext;

@EventBusSubscriber(modid = CamoWarfare.MOD_ID)
public final class WorldDecalNetworking {
    private WorldDecalNetworking() {}

    public static void register(RegisterPayloadHandlersEvent event) {
        event.registrar("1")
            .playToClient(SyncWorldDecalsPayload.TYPE, SyncWorldDecalsPayload.STREAM_CODEC, WorldDecalNetworking::handleSync)
            .playToClient(UpdateWorldDecalPayload.TYPE, UpdateWorldDecalPayload.STREAM_CODEC, WorldDecalNetworking::handleUpdate);
    }

    public static void syncAll(ServerPlayer player) {
        if (player.level() instanceof ServerLevel level) {
            PacketDistributor.sendToPlayer(player, new SyncWorldDecalsPayload(WorldDecalData.get(level).decals()));
        }
    }

    public static void syncBlock(ServerLevel level, BlockPos pos) {
        PacketDistributor.sendToPlayersTrackingChunk(level, new ChunkPos(pos), new UpdateWorldDecalPayload(pos, WorldDecalData.get(level).decals().get(pos)));
    }

    @SubscribeEvent
    public static void onPlayerLoggedIn(PlayerEvent.PlayerLoggedInEvent event) {
        if (event.getEntity() instanceof ServerPlayer player) {
            syncAll(player);
        }
    }

    @SubscribeEvent
    public static void onPlayerChangedDimension(PlayerEvent.PlayerChangedDimensionEvent event) {
        if (event.getEntity() instanceof ServerPlayer player) {
            syncAll(player);
        }
    }

    @SubscribeEvent
    public static void onBlockBroken(BlockEvent.BreakEvent event) {
        if (event.getLevel() instanceof ServerLevel level) {
            WorldDecalData.get(level).clear(event.getPos());
            syncBlock(level, event.getPos());
        }
    }

    private static void handleSync(SyncWorldDecalsPayload payload, IPayloadContext context) {
        context.enqueueWork(() -> WorldDecalClientStore.replace(payload.decals()));
    }

    private static void handleUpdate(UpdateWorldDecalPayload payload, IPayloadContext context) {
        context.enqueueWork(() -> WorldDecalClientStore.update(payload.pos(), payload.faces()));
    }

    public record SyncWorldDecalsPayload(Map<BlockPos, EnumMap<Direction, List<String>>> decals) implements CustomPacketPayload {
        public static final CustomPacketPayload.Type<SyncWorldDecalsPayload> TYPE = new CustomPacketPayload.Type<>(ResourceLocation.fromNamespaceAndPath(CamoWarfare.MOD_ID, "sync_world_decals"));
        public static final StreamCodec<RegistryFriendlyByteBuf, SyncWorldDecalsPayload> STREAM_CODEC = StreamCodec.ofMember(SyncWorldDecalsPayload::write, SyncWorldDecalsPayload::read);

        private void write(RegistryFriendlyByteBuf buf) {
            buf.writeVarInt(decals.size());
            for (Map.Entry<BlockPos, EnumMap<Direction, List<String>>> entry : decals.entrySet()) {
                buf.writeBlockPos(entry.getKey());
                writeFaces(buf, entry.getValue());
            }
        }

        private static SyncWorldDecalsPayload read(RegistryFriendlyByteBuf buf) {
            int count = buf.readVarInt();
            Map<BlockPos, EnumMap<Direction, List<String>>> decals = new java.util.HashMap<>();
            for (int i = 0; i < count; i++) {
                decals.put(buf.readBlockPos(), readFaces(buf));
            }
            return new SyncWorldDecalsPayload(decals);
        }

        @Override
        public Type<? extends CustomPacketPayload> type() {
            return TYPE;
        }
    }

    public record UpdateWorldDecalPayload(BlockPos pos, EnumMap<Direction, List<String>> faces) implements CustomPacketPayload {
        public static final CustomPacketPayload.Type<UpdateWorldDecalPayload> TYPE = new CustomPacketPayload.Type<>(ResourceLocation.fromNamespaceAndPath(CamoWarfare.MOD_ID, "update_world_decal"));
        public static final StreamCodec<RegistryFriendlyByteBuf, UpdateWorldDecalPayload> STREAM_CODEC = StreamCodec.ofMember(UpdateWorldDecalPayload::write, UpdateWorldDecalPayload::read);

        private void write(RegistryFriendlyByteBuf buf) {
            buf.writeBlockPos(pos);
            writeFaces(buf, faces);
        }

        private static UpdateWorldDecalPayload read(RegistryFriendlyByteBuf buf) {
            return new UpdateWorldDecalPayload(buf.readBlockPos(), readFaces(buf));
        }

        @Override
        public Type<? extends CustomPacketPayload> type() {
            return TYPE;
        }
    }

    private static void writeFaces(RegistryFriendlyByteBuf buf, EnumMap<Direction, List<String>> faces) {
        if (faces == null || faces.isEmpty()) {
            buf.writeVarInt(0);
            return;
        }
        buf.writeVarInt(faces.size());
        for (Map.Entry<Direction, List<String>> entry : faces.entrySet()) {
            buf.writeEnum(entry.getKey());
            buf.writeVarInt(entry.getValue().size());
            for (String decalId : entry.getValue()) {
                buf.writeUtf(decalId);
            }
        }
    }

    private static EnumMap<Direction, List<String>> readFaces(RegistryFriendlyByteBuf buf) {
        int count = buf.readVarInt();
        EnumMap<Direction, List<String>> faces = new EnumMap<>(Direction.class);
        for (int i = 0; i < count; i++) {
            Direction face = buf.readEnum(Direction.class);
            int decalCount = buf.readVarInt();
            java.util.ArrayList<String> decals = new java.util.ArrayList<>(decalCount);
            for (int j = 0; j < decalCount; j++) {
                decals.add(buf.readUtf());
            }
            if (!decals.isEmpty()) {
                faces.put(face, List.copyOf(decals));
            }
        }
        return faces;
    }
}
