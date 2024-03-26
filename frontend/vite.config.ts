import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vitejs.dev/config/
export default defineConfig((meta) => ({
  plugins: [react()],
  server: {
    proxy: {
      '/socket.io': {
        changeOrigin: true,
        target: meta.isPreview ? 'http://backend:3000/' : 'http://localhost:3000/',
        secure: false,
        ws: true
      }
    }
  }
}));
