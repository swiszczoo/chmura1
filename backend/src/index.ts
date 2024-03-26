import express, { Express } from 'express';
import http from 'http';
import { Server } from 'socket.io';

import { playerConnected } from './game';

const app: Express = express();
const server = http.createServer(app);
const io = new Server(server);
const port = process.env.PORT || 3000;

io.on('connection', (socket) => {
    playerConnected(socket);
});

server.listen(port, () => {
    console.log(`App started on port ${port}`);
});
