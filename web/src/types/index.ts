export interface Ingredient {
  name: string;
  amount: string;
}

export interface Recipe {
  id: string;
  title: string;
  ingredients: Ingredient[];
  steps: string[];
  author: { id: string; firstName: string };
  createdAt: string;
}

export interface RecipeListResponse {
  results: Recipe[];
  page: number;
  totalPages: number;
}

export interface User {
  id: string;
  firstName: string;
  lastName: string;
  email: string;
}
