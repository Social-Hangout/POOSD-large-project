import type { Recipe, RecipeInput, RecipeListResponse, SearchResponse } from "../types";
import { api } from "./client";

// 9. List recipes, newest first. mine=true returns only the logged-in user's recipes.
export function getRecipes(page = 1, limit = 12, mine = false): Promise<RecipeListResponse> {
  const params = new URLSearchParams({ page: String(page), limit: String(limit) });
  if (mine) params.set("mine", "true");
  return api<RecipeListResponse>(`/recipes?${params}`);
}

// 10. Server-side ingredient search, best match first. Pass a signal so an older,
// slower request can be cancelled when the user keeps typing.
export function searchRecipes(q: string, page = 1, signal?: AbortSignal): Promise<SearchResponse> {
  const params = new URLSearchParams({ q, page: String(page), limit: "20" });
  return api<SearchResponse>(`/recipes/search?${params}`, { signal });
}

// 11. One recipe
export function getRecipe(id: string): Promise<Recipe> {
  return api<Recipe>(`/recipes/${encodeURIComponent(id)}`);
}

// 12. Create a recipe (the author comes from the token)
export function createRecipe(recipe: RecipeInput): Promise<Recipe> {
  return api<Recipe>("/recipes", { method: "POST", body: JSON.stringify(recipe) });
}

// 13. Replace a recipe's title, ingredients and steps (author only)
export function updateRecipe(id: string, recipe: RecipeInput): Promise<Recipe> {
  return api<Recipe>(`/recipes/${encodeURIComponent(id)}`, {
    method: "PUT",
    body: JSON.stringify(recipe),
  });
}

// 14. Delete a recipe and its reviews and comments (author only)
export function deleteRecipe(id: string): Promise<void> {
  return api<void>(`/recipes/${encodeURIComponent(id)}`, { method: "DELETE" });
}
