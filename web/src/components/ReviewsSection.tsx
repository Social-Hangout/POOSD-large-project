import { FormEvent, useCallback, useEffect, useState } from "react";
import { ApiError, errorMessage } from "../api/client";
import {
  createComment,
  createReview,
  deleteComment,
  deleteReview,
  getComments,
  getReviews,
} from "../api/reviews";
import { useAuth } from "../context/AuthContext";
import type { Comment, Review } from "../types";

const MAX_TEXT = 500;

function formatDate(iso: string) {
  return new Date(iso).toLocaleDateString(undefined, { month: "short", day: "numeric", year: "numeric" });
}

function Stars({ rating }: { rating: number }) {
  return (
    <span className="stars" aria-label={`${rating} out of 5 stars`}>
      {"★".repeat(rating)}
      <span>{"★".repeat(5 - rating)}</span>
    </span>
  );
}

// Reviews (routes 15-17) and comments (routes 18-20) for one recipe
export default function ReviewsSection({ recipeId }: { recipeId: string }) {
  return (
    <section id="reviews-section" className="reviews-section">
      <Reviews recipeId={recipeId} />
      <Comments recipeId={recipeId} />
    </section>
  );
}

function Reviews({ recipeId }: { recipeId: string }) {
  const { user } = useAuth();
  const [reviews, setReviews] = useState<Review[]>([]);
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(0);
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState("");

  const [rating, setRating] = useState(0);
  const [text, setText] = useState("");
  const [error, setError] = useState("");
  const [saving, setSaving] = useState(false);

  const load = useCallback(
    async (nextPage: number) => {
      setLoading(true);
      setLoadError("");
      try {
        const response = await getReviews(recipeId, nextPage);
        setReviews((current) => (nextPage === 1 ? response.reviews : [...current, ...response.reviews]));
        setPage(response.page);
        setTotalPages(response.totalPages);
      } catch (caught) {
        setLoadError(errorMessage(caught, "Could not load reviews."));
      } finally {
        setLoading(false);
      }
    },
    [recipeId],
  );

  useEffect(() => {
    load(1);
  }, [load]);

  const mine = reviews.find((review) => review.author?.id === user?.id);

  async function submit(event: FormEvent) {
    event.preventDefault();
    setError("");
    if (rating < 1) return setError("Pick a rating from 1 to 5 stars.");
    setSaving(true);
    try {
      await createReview(recipeId, { rating, text: text.trim() });
      setRating(0);
      setText("");
      await load(1);
    } catch (caught) {
      setError(
        caught instanceof ApiError && caught.status === 409
          ? "You already reviewed this recipe."
          : errorMessage(caught, "Could not post your review."),
      );
    } finally {
      setSaving(false);
    }
  }

  async function remove(id: string) {
    try {
      await deleteReview(id);
      await load(1);
    } catch (caught) {
      setLoadError(errorMessage(caught, "Could not delete the review."));
    }
  }

  return (
    <div className="feedback-block">
      <h2>Reviews</h2>

      {!mine && (
        <form className="feedback-form" onSubmit={submit}>
          <div className="star-picker" role="radiogroup" aria-label="Your rating">
            {[1, 2, 3, 4, 5].map((value) => (
              <button
                key={value}
                type="button"
                role="radio"
                aria-checked={rating === value}
                aria-label={`${value} star${value > 1 ? "s" : ""}`}
                className={value <= rating ? "on" : ""}
                onClick={() => setRating(value)}
              >
                ★
              </button>
            ))}
          </div>
          <textarea
            value={text}
            maxLength={MAX_TEXT}
            rows={3}
            onChange={(event) => setText(event.target.value)}
            placeholder="What did you think? (optional)"
            aria-label="Review text"
          />
          <div className="feedback-form-footer">
            <small>
              {text.length}/{MAX_TEXT}
            </small>
            <button className="primary-button" disabled={saving}>
              {saving ? "Posting…" : "Post Review"}
            </button>
          </div>
          {error && <p className="form-status error">{error}</p>}
        </form>
      )}

      {loadError && <p className="form-status error">{loadError}</p>}
      {!loading && reviews.length === 0 && !loadError && (
        <p className="muted-copy">No reviews yet. Be the first!</p>
      )}
      <ul className="feedback-list">
        {reviews.map((review) => (
          <li key={review.id}>
            <div className="feedback-meta">
              <strong>{review.author?.firstName ?? "Former member"}</strong>
              <Stars rating={review.rating} />
              <time dateTime={review.createdAt}>{formatDate(review.createdAt)}</time>
              {review.author?.id === user?.id && (
                <DeleteButton label="review" onConfirm={() => remove(review.id)} />
              )}
            </div>
            {review.text && <p>{review.text}</p>}
          </li>
        ))}
      </ul>
      {page < totalPages && (
        <button type="button" className="secondary-button" disabled={loading} onClick={() => load(page + 1)}>
          {loading ? "Loading…" : "Show more reviews"}
        </button>
      )}
    </div>
  );
}

function Comments({ recipeId }: { recipeId: string }) {
  const { user } = useAuth();
  const [comments, setComments] = useState<Comment[]>([]);
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(0);
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState("");

  const [text, setText] = useState("");
  const [error, setError] = useState("");
  const [saving, setSaving] = useState(false);

  // Comments come oldest first, so "show more" adds newer ones below
  const load = useCallback(
    async (nextPage: number) => {
      setLoading(true);
      setLoadError("");
      try {
        const response = await getComments(recipeId, nextPage);
        setComments((current) => {
          if (nextPage === 1) return response.comments;
          // Merge without duplicates (a comment you just posted may also be on this page),
          // then keep them oldest first
          const byId = new Map([...current, ...response.comments].map((c) => [c.id, c]));
          return [...byId.values()].sort((a, b) => a.createdAt.localeCompare(b.createdAt));
        });
        setPage(response.page);
        setTotalPages(response.totalPages);
      } catch (caught) {
        setLoadError(errorMessage(caught, "Could not load comments."));
      } finally {
        setLoading(false);
      }
    },
    [recipeId],
  );

  useEffect(() => {
    load(1);
  }, [load]);

  async function submit(event: FormEvent) {
    event.preventDefault();
    setError("");
    if (!text.trim()) return setError("Comment text is required");
    setSaving(true);
    try {
      const comment = await createComment(recipeId, text.trim());
      setText("");
      // It's the newest comment, so it goes at the end of the list
      setComments((current) => [...current, comment]);
    } catch (caught) {
      setError(errorMessage(caught, "Could not post your comment."));
    } finally {
      setSaving(false);
    }
  }

  async function remove(id: string) {
    try {
      await deleteComment(id);
      setComments((current) => current.filter((comment) => comment.id !== id));
    } catch (caught) {
      setLoadError(errorMessage(caught, "Could not delete the comment."));
    }
  }

  return (
    <div className="feedback-block">
      <h2>Comments</h2>
      {loadError && <p className="form-status error">{loadError}</p>}
      {!loading && comments.length === 0 && !loadError && (
        <p className="muted-copy">No comments yet. Start the conversation.</p>
      )}
      <ul className="feedback-list">
        {comments.map((comment) => (
          <li key={comment.id}>
            <div className="feedback-meta">
              <strong>{comment.author?.firstName ?? "Former member"}</strong>
              <time dateTime={comment.createdAt}>{formatDate(comment.createdAt)}</time>
              {comment.author?.id === user?.id && (
                <DeleteButton label="comment" onConfirm={() => remove(comment.id)} />
              )}
            </div>
            <p>{comment.text}</p>
          </li>
        ))}
      </ul>
      {page < totalPages && (
        <button type="button" className="secondary-button" disabled={loading} onClick={() => load(page + 1)}>
          {loading ? "Loading…" : "Show more comments"}
        </button>
      )}
      <form className="feedback-form" onSubmit={submit}>
        <textarea
          value={text}
          maxLength={MAX_TEXT}
          rows={2}
          onChange={(event) => setText(event.target.value)}
          placeholder="Add a comment"
          aria-label="Comment text"
        />
        <div className="feedback-form-footer">
          <small>
            {text.length}/{MAX_TEXT}
          </small>
          <button className="primary-button" disabled={saving}>
            {saving ? "Posting…" : "Post Comment"}
          </button>
        </div>
        {error && <p className="form-status error">{error}</p>}
      </form>
    </div>
  );
}

// Delete that asks "Sure?" first
function DeleteButton({ label, onConfirm }: { label: string; onConfirm: () => void }) {
  const [confirming, setConfirming] = useState(false);
  if (!confirming) {
    return (
      <button type="button" className="text-button danger-text" onClick={() => setConfirming(true)}>
        Delete
      </button>
    );
  }
  return (
    <span className="inline-confirm">
      Delete your {label}?
      <button type="button" className="text-button danger-text" onClick={onConfirm}>
        Yes
      </button>
      <button type="button" className="text-button" onClick={() => setConfirming(false)}>
        No
      </button>
    </span>
  );
}
