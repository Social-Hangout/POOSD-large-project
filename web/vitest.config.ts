import { defineConfig } from "vitest/config";
import react from "@vitejs/plugin-react";

// Web tests: npm test (one run) or npm run test:watch (re-runs on save)
export default defineConfig({
  plugins: [react()],
  test: {
    environment: "jsdom",
    setupFiles: ["./src/tests/setup.ts"],
    css: false,
    restoreMocks: true,
  },
});
