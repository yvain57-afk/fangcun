import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import tailwindcss from '@tailwindcss/vite';
import { resolve } from 'node:path';
export default defineConfig({ plugins: [react(), tailwindcss()], build: { rollupOptions: { input: { app: resolve(import.meta.dirname, 'index.html'), characters: resolve(import.meta.dirname, 'character-studio.html'), brand: resolve(import.meta.dirname, 'brand-studio.html') } } } });
