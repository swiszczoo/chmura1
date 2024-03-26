import { createContext, useContext, useRef } from "react";
import { io, Socket } from "socket.io-client";

const WsContext = createContext<Socket | undefined>(undefined);

export const WebsocketContextProvider = (props: React.PropsWithChildren) => {
    const ioRef = useRef(io());

    return (
        <WsContext.Provider value={ioRef.current}>
            {props.children}
        </WsContext.Provider>
    );
};

export const useWebsocket = () => {
    return useContext(WsContext);
};
