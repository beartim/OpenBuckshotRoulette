const WebSocket = require('ws');
const fs = require('fs');
const zlib = require('zlib');
const crypto = require('crypto');

const config = JSON.parse(fs.readFileSync('server.json', 'utf8'));

const server = new WebSocket.Server({
    port: config.ipv4_port,
    host: '0.0.0.0'
});

console.log(`Server started on port ${config.ipv4_port}`);

let clients = new Map(); // clientId -> {ws, roomId, playerId, playerName}
let rooms = new Map(); // roomId -> {hostId, clients: Set}
let nextClientId = 1;

server.on('connection', (ws) => {
    const clientId = nextClientId++;
    clients.set(clientId, {ws, roomId: null, playerId: null});

    console.log(`Client ${clientId} connected`);

    ws.on('message', (message) => {
        try {
            const data = JSON.parse(message);
            handleMessage(clientId, data);
        } catch (e) {
            // Assume it's binary packet
            handlePacket(clientId, message);
        }
    });

    ws.on('close', () => {
        console.log(`Client ${clientId} disconnected`);
        leaveRoom(clientId);
        clients.delete(clientId);
    });

    // Send client ID
    ws.send(JSON.stringify({type: 'connected', clientId}));
});

function handleMessage(clientId, data) {
    const client = clients.get(clientId);
    if (!client) return;
    switch (data.type) {
        case 'createRoom':
            createRoom(clientId, data);
            break;
        case 'joinRoom':
            joinRoom(clientId, data);
            break;
        case 'leaveRoom':
            leaveRoom(clientId);
            break;
        case 'listRooms':
            listRooms(clientId);
            break;
        case 'heartbeat':
            break
        default:
            console.log('Unknown message type:', data.type);
    }
}

function handlePacket(clientId, buffer) {
    const client = clients.get(clientId);
    if (!client || !client.roomId) return;

    // Decompress
    zlib.gunzip(buffer, (err, decompressed) => {
        if (err) {
            console.error('Decompression error:', err);
            return;
        }
        // Broadcast to room
        broadcastPacketToRoom(client.roomId, decompressed, clientId);
    });
}

function listRooms(clientId) {
    const client = clients.get(clientId);
    if (!client) return;
    
    const roomList = [];
    for (const [roomId, room] of rooms.entries()) {
        const members = Array.from(room.clients).map(id => {
            const roomClient = clients.get(id);
            return {playerId: roomClient.playerId, playerName: roomClient.playerName};
        });
        roomList.push({
            roomId: roomId.toString(),
            hostId: room.hostId,
            memberCount: room.clients.size,
            members: members
        });
    }
    
    client.ws.send(JSON.stringify({
        type: 'roomList',
        rooms: roomList
    }));
}

function createRoom(clientId, data) {
    const roomId = Math.floor(Math.random() * 900000) + 100000;
    const client = clients.get(clientId);
    client.roomId = roomId;
    client.playerId = data.playerId || clientId;
    client.playerName = data.playerName || `Player${clientId}`;
    rooms.set(roomId, {hostId: client.playerId, clients: new Set([clientId])});

    const roomMembers = Array.from(rooms.get(roomId).clients).map(id => {
        const roomClient = clients.get(id);
        return {playerId: roomClient.playerId, playerName: roomClient.playerName};
    });

    client.ws.send(JSON.stringify({type: 'roomCreated', roomId: roomId.toString(), hostId: client.playerId, members: roomMembers}));
    broadcastToRoom(roomId, {type: 'playerJoined', playerId: client.playerId, playerName: client.playerName}, clientId);
    console.log(`Room ${roomId} created by client ${clientId} (${client.playerName})`);
}

function joinRoom(clientId, data) {
    const roomId = parseInt(data.roomId);
    if (!rooms.has(roomId)) {
        clients.get(clientId).ws.send(JSON.stringify({type: 'error', message: 'Room not found'}));
        return;
    }

    const client = clients.get(clientId);
    if (client.roomId) {
        leaveRoom(clientId);
    }

    client.roomId = roomId;
    client.playerId = data.playerId || clientId;
    client.playerName = data.playerName || `Player${clientId}`;
    const room = rooms.get(roomId);
    room.clients.add(clientId);

    const roomMembers = Array.from(room.clients).map(id => {
        const roomClient = clients.get(id);
        return {playerId: roomClient.playerId, playerName: roomClient.playerName};
    });

    client.ws.send(JSON.stringify({type: 'joinedRoom', roomId: roomId.toString(), hostId: room.hostId, members: roomMembers}));
    broadcastToRoom(roomId, {type: 'playerJoined', playerId: client.playerId, playerName: client.playerName}, clientId);
    console.log(`Client ${clientId} (${client.playerName}) joined room ${roomId}`);
}

function leaveRoom(clientId) {
    const client = clients.get(clientId);
    if (!client.roomId) return;

    const roomId = client.roomId;
    const room = rooms.get(roomId);
    room.clients.delete(clientId);
    if (room.clients.size === 0) {
        rooms.delete(roomId);
        console.log(`Room ${roomId} deleted`);
    } else {
        broadcastToRoom(roomId, {type: 'playerLeft', playerId: client.playerId}, clientId);
    }
    client.roomId = null;
    client.playerId = null;
    client.playerName = null;
}

function broadcastToRoom(roomId, message, excludeClientId = null) {
    if (!rooms.has(roomId)) return;

    const room = rooms.get(roomId);
    for (const id of room.clients) {
        if (id !== excludeClientId) {
            const client = clients.get(id);
            if (client && client.ws.readyState === WebSocket.OPEN) {
                client.ws.send(JSON.stringify(message));
            }
        }
    }
}

function broadcastPacketToRoom(roomId, packet, excludeClientId = null) {
    if (!rooms.has(roomId)) return;

    const room = rooms.get(roomId);
    for (const id of room.clients) {
        if (id !== excludeClientId) {
            const client = clients.get(id);
            if (client && client.ws.readyState === WebSocket.OPEN) {
                client.ws.send(packet);
            }
        }
    }
}