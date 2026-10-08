import path from "path";

import react from "@vitejs/plugin-react";
import { defineConfig } from "vite";

// https://vitejs.dev/config/
export default defineConfig(({ mode }) => ({
  server: {
    host: "::",
    port: 8080,
    hmr: {
      overlay: false,
    },
  },
  plugins: [react()],
  build: {
    chunkSizeWarningLimit: 900,
    rolldownOptions: {
      output: {
        // Keep the statute dataset and the heavy vendor bundle in their own
        // long-lived chunks so UI changes don't invalidate them.
        manualChunks(id: string) {
          if (id.includes("/src/data/sections.json")) return "sections";
          if (id.includes("node_modules/react-dom") || id.includes("node_modules/react-router")) return "react";
          return undefined;
        },
      },
    },
  },
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./src"),
    },
  },
  // Expose both VITE_* (Vite default) and EXPO_PUBLIC_* (Rork's cross-platform
  // public-env convention, written by tools like getOrCreateAuthConfig).
  envPrefix: ["VITE_", "EXPO_PUBLIC_"],
}));
