import { useWebsocket } from "./WebsocketContext";

interface BoardTileProps {
    tile: 'X' | 'O' | ' ';
    ourMove: boolean;
    x: number;
    y: number;
}

function BoardTile(props: BoardTileProps) {
    const socket = useWebsocket();

    let classes = "w-[150px] h-[150px] mr-2 mb-2 rounded-lg flex items-center justify-center bg-white bg-opacity-10";
    if (props.ourMove) {
        classes += ' hover:bg-opacity-20 cursor-pointer';
    }

    const handleClick = () => {
        socket?.emit('move', [props.x, props.y], () => {});
    };

    return (
        <div className={classes} onClick={handleClick}>
            <p className="text-5xl">{props.tile}</p>
        </div>
    );
}

export interface BoardProps {
    nextMove: 'X' | 'O';
    playerNameX: string;
    playerNameO: string;
    result: 'X' | 'O' | undefined;
    playfield: ('X' | 'O' | ' ')[];
    yourShape: 'X' | 'O';
}

function Board(props: BoardProps & { onRestart?: () => void }) {
    const ourMove = props.yourShape === props.nextMove;

    return (
        <>
            <h1>Gra w kółko i krzyżyk</h1>
            <h2 className="text-lg text-center">
                <strong>{props.playerNameX}</strong> (X) vs <strong>{props.playerNameO}</strong> (O)
            </h2>
            <h2 className="text-lg text-center mb-8">
                Następny ruch: <strong>{props.nextMove === 'X' ? props.playerNameX : props.playerNameO}</strong>
            </h2>
            <div className="flex">
                <BoardTile x={0} y={0} tile={props.playfield[0]} ourMove={ourMove} />
                <BoardTile x={1} y={0} tile={props.playfield[1]} ourMove={ourMove} />
                <BoardTile x={2} y={0} tile={props.playfield[2]} ourMove={ourMove} />
            </div>
            <div className="flex">
                <BoardTile x={0} y={1} tile={props.playfield[3]} ourMove={ourMove} />
                <BoardTile x={1} y={1} tile={props.playfield[4]} ourMove={ourMove} />
                <BoardTile x={2} y={1} tile={props.playfield[5]} ourMove={ourMove} />
            </div>
            <div className="flex mb-8">
                <BoardTile x={0} y={2} tile={props.playfield[6]} ourMove={ourMove} />
                <BoardTile x={1} y={2} tile={props.playfield[7]} ourMove={ourMove} />
                <BoardTile x={2} y={2} tile={props.playfield[8]} ourMove={ourMove} />
            </div>
            {
                props.result !== undefined && 
                <>
                    { props.result === props.yourShape && <p className="text-green-500 text-lg text-center">Wygrałeś!</p> }
                    { props.result !== props.yourShape && <p className="text-red-500 text-lg text-center">Przegrałeś!</p> }
                    <button className="mt-4 w-full" onClick={props.onRestart}>Zagraj ponownie</button>
                </>
            }
        </>
    );
}

export default Board;
