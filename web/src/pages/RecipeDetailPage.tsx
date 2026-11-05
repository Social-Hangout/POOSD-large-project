import { useEffect, useState } from "react";
import { Link, useParams } from "react-router-dom";
import { getRecipe } from "../api/recipes";
import MealDbCredit from "../components/MealDbCredit";
import { useAuth } from "../context/AuthContext";
import type { Recipe } from "../types";

export default function RecipeDetailPage() {
  const { id = "" } = useParams();
  const { logout } = useAuth();
  const [recipe, setRecipe] = useState<Recipe | null>(null);
  const [error, setError] = useState("");
  useEffect(() => {
    setRecipe(null);
    setError("");
    getRecipe(id)
      .then(setRecipe)
      .catch((caught) => setError(caught.message));
  }, [id]);

  return (
    <main className="detail-page">
      <header>
        <Link className="brand" to="/recipes">
          Savory<span>.</span>
        </Link>
        <button onClick={logout}>Log out</button>
      </header>
      <article className="detail-card">
        <Link className="back-link detail-back" to="/recipes">
          ← &nbsp;Back to recipes
        </Link>
        {error ? (
          <h1>{error}</h1>
        ) : !recipe ? (
          <h1>Preparing your recipe…</h1>
        ) : (
          <>
            <p className="eyebrow">SAVORY RECIPE</p>
            <h1>{recipe.title}</h1>
            <p className="byline">By {recipe.author?.firstName || "a Savory cook"}</p>
            <div className="detail-columns">
              <section>
                <h2>Ingredients</h2>
                <ul>
                  {recipe.ingredients.map((item, index) => (
                    <li key={`${item.name}-${index}`}>
                      <span>{item.name}</span>
                      <strong>{item.amount}</strong>
                    </li>
                  ))}
                </ul>
              </section>
              <section>
                <h2>Method</h2>
                <ol>
                  {recipe.steps.map((step, index) => (
                    <li key={index}>
                      <span>{index + 1}</span>
                      <p>{step}</p>
                    </li>
                  ))}
                </ol>
              </section>
            </div>
            <section id="reviews-section"></section>
          </>
        )}
      </article>
      <footer className="page-footer">
        <MealDbCredit />
      </footer>
    </main>
  );
}
