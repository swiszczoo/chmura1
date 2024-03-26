import { Socket } from "socket.io";
import { Board } from "./board";

interface SocketMeta {
    playerName: string;
    playerReady: boolean;
    playerInGame: boolean;
    assignedBoard: Board | null;
    assignedShape: 'X' | 'O' | null;
};

const socketState: Map<Socket, SocketMeta> = new Map();
let playerInLobby: Socket | null = null;

const startGame = (player: Socket): boolean => {
    const meta = socketState.get(player);
    if (!meta) {
        return false;
    }

    if (meta.playerInGame) {
        return false;
    }

    if (playerInLobby === null) {
        playerInLobby = player
    } else {
        const playerMeta1 = socketState.get(playerInLobby)!;
        const playerMeta2 = socketState.get(player)!;
        console.log(`[game] Starting a new game between '${playerMeta1.playerName}' and '${playerMeta2.playerName}'`);

        const shuffle = Math.random() < 0.5;
        playerMeta1.assignedShape = shuffle ? 'X' : 'O';
        playerMeta2.assignedShape = shuffle ? 'O' : 'X';

        const players = [playerInLobby, player];

        const board = (shuffle 
            ? new Board(players, playerMeta1.playerName, playerMeta2.playerName)
            : new Board(players, playerMeta2.playerName, playerMeta1.playerName)
        );
        playerMeta1.assignedBoard = board;
        playerMeta2.assignedBoard = board;

        setTimeout(() => sendBoardState(board), 0);
        playerInLobby = null;
    }

    return true;
};

const sendBoardState = (board: Board) => {
    board.getPlayers().forEach((weakPlayer: WeakRef<Socket>) => {
        const strongPlayer = weakPlayer.deref();

        if (strongPlayer) {
            const strongMeta = socketState.get(strongPlayer);
            if (strongMeta) {
                const boardData = board.getData(strongMeta.assignedShape as 'X' | 'O');

                strongPlayer.emit('update_board', boardData);
            }
        }
    });
};

const removeGame = (board: Board) => {
    console.log('[game] Game finished');
    board.getPlayers().forEach((weakPlayer: WeakRef<Socket>) => {
        const strongPlayer = weakPlayer.deref();

        if (strongPlayer) {
            const strongMeta = socketState.get(strongPlayer);
            if (strongMeta) {
                strongMeta.assignedBoard = null;
                strongMeta.assignedShape = null;
            }
        }
    });
};

const makeMove = (player: Socket, x: number, y: number): boolean => {
    const meta = socketState.get(player);
    if (!meta) {
        return false;
    }

    if (meta.assignedBoard === null) {
        return false;
    }

    const board = meta.assignedBoard;
    if (board.getWinner() !== undefined) {
        return false;
    }

    if(!board.makeMove(meta.assignedShape === 'X', x, y)) {
        return false;
    }

    sendBoardState(board);

    if (board.getWinner() !== undefined) {
        removeGame(board);
    }
    return true;
}

export const playerConnected = (socket: Socket) => {
    socketState.set(socket, {
        playerName: '',
        playerReady: false,
        playerInGame: false,
        assignedBoard: null,
        assignedShape: null,
    });

    socket.on('set_player_name', (name: string, callback: (ok: boolean) => void) => {
        const state = socketState.get(socket);

        if (state && name.length > 0) {
            state.playerName = name;

            if (!state.playerReady) 
                console.log(`[game] Player '${name}' connected`);

            state.playerReady = true;
            callback(true);
        } else {
            callback(false);
        }
    });

    socket.on('join_game', (_, callback: (ok: boolean) => void) => {
        callback(startGame(socket));
    });

    socket.on('move', (coords: number[], callback: (ok: boolean) => void) => {
        callback(makeMove(socket, coords[0], coords[1]));
    });

    socket.on('disconnect', () => {
        if (playerInLobby === socket) {
            playerInLobby = null;
        }

        const state = socketState.get(socket);

        if (state) {
            socketState.delete(socket);
            if (state.playerReady) {
                console.log(`[game] Player '${state.playerName}' disconnected`);
            }

            if (state.assignedBoard) {
                state.assignedBoard.forceWin(state.assignedShape === 'X' ? 'O' : 'X');
                sendBoardState(state.assignedBoard);
                removeGame(state.assignedBoard);
            }
        }
    });
};
