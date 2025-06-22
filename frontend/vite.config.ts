import { defineConfig } from "vite";
import vue from "@vitejs/plugin-vue";

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [vue()],
  
  // Build configuration for Chromium file:// protocol
  base: './',
  
  build: {
    outDir: 'dist',
    assetsDir: 'assets',
    // Ensure CSS is inlined for file:// protocol compatibility
    cssCodeSplit: false,
    rollupOptions: {
      output: {
        // Don't hash filenames for simpler file:// access
        entryFileNames: '[name].js',
        chunkFileNames: '[name].js',
        assetFileNames: '[name].[ext]'
      }
    }
  }
});