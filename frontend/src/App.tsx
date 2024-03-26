import { useEffect, useState } from 'react';

import Board, { BoardProps } from './Board';
import Login from "./Login";
import Lobby from './Lobby';
import { useWebsocket } from './WebsocketContext';

type AppState = 'username' | 'lobby' | 'game';

function App() {
  const socket = useWebsocket();
  const [ state, setState ] = useState<AppState>('username');
  const [ gameState, setGameState ] = useState<BoardProps | undefined>(undefined);

  useEffect(() => {
    const handler = (newState: BoardProps) => {
      setState('game');
      setGameState(newState);
    };

    socket?.on('update_board', handler);

    return () => { socket?.off('update_board', handler) };
  }, [socket]);

  const handleJoinGame = () => {
    socket!.emit('join_game', {}, (success: boolean) => {
      if (success) {
        setState('lobby');
      }
    });
  };

  if (state === 'username') return <Login onNameAccepted={handleJoinGame}/>;
  if (state === 'lobby') return <Lobby/>;
  if (state === 'game' && gameState) return <Board {...gameState} onRestart={handleJoinGame} />;

  return <></>;
}

export default App;
