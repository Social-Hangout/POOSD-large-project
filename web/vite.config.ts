import { defineConfig, loadEnv } from "vite";
import react from "@vitejs/plugin-react";
import tailwindcss from "@tailwindcss/vite";
import path from "node:path";

// During `npm run dev`, every request to /api is forwarded to the backend.
// Set API_TARGET in web/.env (see .env.example). In production, Nginx does this instead.
export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), "");
  return {
    plugins: [react(), tailwindcss()],
    resolve: {
      alias: { "@": path.resolve(__dirname, "./src") },
    },
    server: {
      proxy: {
        "/api": {
          target: env.API_TARGET || "http://localhost:5000",
          changeOrigin: true,
        },
      },
    },
  };
});
