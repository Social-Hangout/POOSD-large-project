// Shapes from docs/api-contract.md ("Shared shapes")

export interface Ingredient {
  name: string;
  amount: string;
}

// The short user attached to recipes, reviews and comments.
// null if that account was deleted.
export type Author = { id: string; firstName: string } | null;

export interface Recipe {
  id: string;
  title: string;
  ingredients: Ingredient[];
  steps: string[];
  author: Author;
  createdAt: string;
}

// What create and edit send (12. POST /api/recipes, 13. PUT /api/recipes/:id)
export interface RecipeInput {
  title: string;
  ingredients: Ingredient[];
  steps: string[];
}

// Every list route returns { <items>, page, totalPages }
export interface Page {
  page: number;
  totalPages: number;
}

// 9. GET /api/recipes
export interface RecipeListResponse extends Page {
  recipes: Recipe[];
}

// 10. GET /api/recipes/search
export interface SearchResult extends Recipe {
  matchedTerms: number;
  totalTerms: number;
}

export interface SearchResponse extends Page {
  results: SearchResult[];
}

export interface Review {
  id: string;
  rating: number;
  text: string;
  author: Author;
  createdAt: string;
}

export interface ReviewListResponse extends Page {
  reviews: Review[];
}

export interface Comment {
  id: string;
  text: string;
  author: Author;
  createdAt: string;
}

export interface CommentListResponse extends Page {
  comments: Comment[];
}

export interface User {
  id: string;
  firstName: string;
  lastName: string;
  email: string;
}
