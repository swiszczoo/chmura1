import ReactDOM from 'react-dom/client';
import App from './App.tsx';
import { WebsocketContextProvider } from './WebsocketContext.tsx';
import './index.css';

ReactDOM.createRoot(document.getElementById('root')!).render(
  <WebsocketContextProvider>
    <App />
  </WebsocketContextProvider>
);
