import { useState } from 'react';
import { useWebsocket } from './WebsocketContext';

interface LoginProps {
    onNameAccepted?: () => void;
}

function Login(props: LoginProps) {
    const [ username, setUsername ] = useState('');
    const socket = useWebsocket();

    const handleChange = (event: React.ChangeEvent<HTMLInputElement>) => {
        setUsername(event.target.value);
    };

    const handleLoginClick = () => {
        socket!.emit('set_player_name', username, (success: boolean) => {
            if (success) {
                if (success && props.onNameAccepted) {
                    props.onNameAccepted();
                }
            }
        });
    };

    return (
        <>
            <h1 className='font-bold'>Koło i krzyż</h1>
            <br/>
            <p>Wprowadź nazwę gracza:</p>
            <input className='w-full' type='text' value={username} onChange={handleChange} />
            <br/>
            <br/>
            <button onClick={handleLoginClick}>Zagraj z losowym przeciwnikiem</button>
        </>
    );
}

export default Login;
