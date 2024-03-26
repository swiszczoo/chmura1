import { Socket } from "socket.io";

interface BoardData {
    nextMove: 'X' | 'O';
    playerNameX: string;
    playerNameO: string;
    result: 'X' | 'O' | '-' | undefined;
    playfield: string;
    yourShape: 'X' | 'O';
}

export class Board {
    private xMove: boolean;
    private playerNameX: string;
    private playerNameO: string;
    private board: ('X' | 'O' | ' ')[][];
    private winner: 'X' | 'O' | '-' | undefined;

    private players: WeakRef<Socket>[];

    public constructor(players: Socket[], xName: string, oName: string) {
        this.xMove = false;
        this.playerNameX = xName;
        this.playerNameO = oName;
        this.board = [
            [' ', ' ', ' '],
            [' ', ' ', ' '],
            [' ', ' ', ' '],
        ];

        this.players = players.map(p => new WeakRef(p));
    }

    public getData(forShape: 'X' | 'O'): BoardData {
        const playfield = `${this.board[0].join('')}${this.board[1].join('')}${this.board[2].join('')}`;
        return {
            nextMove: this.xMove ? 'X' : 'O',
            playerNameX: this.playerNameX,
            playerNameO: this.playerNameO,
            result: this.winner,
            playfield,
            yourShape: forShape,
        };
    }

    public getPlayers(): WeakRef<Socket>[] {
        return [...this.players];
    }

    public makeMove(xMove: boolean, x: number, y: number): boolean {
        if (this.winner !== undefined) {
            return false;
        }

        if (xMove !== this.xMove) {
            return false;
        }

        if (x < 0 || x >= 3 || y < 0 || y >= 3) {
            return false;
        }

        if (this.board[y][x] !== ' ') {
            return false;
        }

        this.board[y][x] = this.xMove ? 'X' : 'O';
        this.xMove = !this.xMove;
        this.updateWinner();
        return true;
    }

    public forceWin(winner: 'X' | 'O') {
        this.winner = winner;
    }

    public getWinner(): 'X' | 'O' | '-' | undefined {
        return this.winner;
    }

    // Pile of shit:
    private updateWinner(): void {
        if (this.board[0][0] !== ' ' && this.board[0][0] === this.board[1][0] && this.board[1][0] === this.board[2][0]) {
            this.winner = this.board[0][0];
        }
        if (this.board[0][1] !== ' ' && this.board[0][1] === this.board[1][1] && this.board[1][1] === this.board[2][1]) {
            this.winner = this.board[0][1];
        }
        if (this.board[0][2] !== ' ' && this.board[0][2] === this.board[1][2] && this.board[1][2] === this.board[2][2]) {
            this.winner = this.board[0][2];
        }
        if (this.board[0][0] !== ' ' && this.board[0][0] === this.board[0][1] && this.board[0][1] === this.board[0][2]) {
            this.winner = this.board[0][0];
        }
        if (this.board[1][0] !== ' ' && this.board[1][0] === this.board[1][1] && this.board[1][1] === this.board[1][2]) {
            this.winner = this.board[1][0];
        }
        if (this.board[2][0] !== ' ' && this.board[2][0] === this.board[2][1] && this.board[2][1] === this.board[2][2]) {
            this.winner = this.board[2][0];
        }
        if (this.board[0][0] !== ' ' && this.board[0][0] === this.board[1][1] && this.board[1][1] === this.board[2][2]) {
            this.winner = this.board[0][0];
        }
        if (this.board[2][0] !== ' ' && this.board[2][0] === this.board[1][1] && this.board[1][1] === this.board[0][2]) {
            this.winner = this.board[2][0];
        }

        if (this.winner === undefined) {
            let fullBoard = true;
            for (let i = 0; i < 3; i++) {
                for (let j = 0; j < 3; j++) {
                    fullBoard &&= this.board[i][j] !== ' ';
                }
            }

            if (fullBoard) {
                this.winner = '-';
            }
        }
    }
}