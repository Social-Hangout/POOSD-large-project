import type { Comment, CommentListResponse, Review, ReviewListResponse } from "../types";
import { api } from "./client";

const recipePath = (recipeId: string) => `/recipes/${encodeURIComponent(recipeId)}`;

// 15. A recipe's reviews, newest first
export function getReviews(recipeId: string, page = 1): Promise<ReviewListResponse> {
  return api<ReviewListResponse>(`${recipePath(recipeId)}/reviews?page=${page}&limit=10`);
}

// 16. Review a recipe (one per user; a second one returns 409)
export function createReview(recipeId: string, review: { rating: number; text: string }) {
  return api<Review>(`${recipePath(recipeId)}/reviews`, {
    method: "POST",
    body: JSON.stringify(review),
  });
}

// 17. Delete your own review
export function deleteReview(reviewId: string): Promise<void> {
  return api<void>(`/reviews/${encodeURIComponent(reviewId)}`, { method: "DELETE" });
}

// 18. A recipe's comments, oldest first
export function getComments(recipeId: string, page = 1): Promise<CommentListResponse> {
  return api<CommentListResponse>(`${recipePath(recipeId)}/comments?page=${page}&limit=20`);
}

// 19. Comment on a recipe
export function createComment(recipeId: string, text: string): Promise<Comment> {
  return api<Comment>(`${recipePath(recipeId)}/comments`, {
    method: "POST",
    body: JSON.stringify({ text }),
  });
}

// 20. Delete your own comment
export function deleteComment(commentId: string): Promise<void> {
  return api<void>(`/comments/${encodeURIComponent(commentId)}`, { method: "DELETE" });
}
