import react from '@vitejs/plugin-react'
import { defineConfig } from 'vite'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    // Mirrors Apache in production: the app calls relative /api/... URLs.
    // Override with API_URL if the API runs on another port (e.g. 5001 on macOS, where AirPlay holds 5000).
    proxy: {
      '/api': process.env.API_URL ?? 'http://localhost:5000',
    },
  },
})
