# Savory web app (React + TypeScript + Vite)

## Run it
1. `npm install`
2. Copy `.env.example` to `.env` and set `API_TARGET` to the backend
   (e.g. `http://localhost:5000` or `https://your-domain.com`).
3. `npm run dev` and open the link it prints.

`npm run build` puts the production site in `dist/` (Nginx serves this).

## Where things live
- `src/api/client.ts` – the only place that calls `fetch` (adds the token, handles 401).
- `src/api/auth.ts`, `src/api/recipes.ts` – one function per backend route.
- `src/types/index.ts` – shapes from `docs/api-contract.md`.
- `src/components/MealDbCredit.tsx` – TheMealDB credit, shown on every page.
