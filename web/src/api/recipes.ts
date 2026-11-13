import type { Recipe, RecipeListResponse } from "../types";
import { api } from "./client";

// Real routes from API2 (docs/api-contract.md). Both need a token, which api() adds.
export function getRecipes(page = 1, limit = 12): Promise<RecipeListResponse> {
  return api<RecipeListResponse>(`/recipes?page=${page}&limit=${limit}`);
}

export function getRecipe(id: string): Promise<Recipe> {
  return api<Recipe>(`/recipes/${encodeURIComponent(id)}`);
}
