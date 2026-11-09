import { useEffect, useState } from "react";
import { Link, useParams } from "react-router-dom";
import { errorMessage } from "../api/client";
import { getRecipe } from "../api/recipes";
import AppShell from "../components/AppShell";
import { authorName } from "../components/RecipeCard";
import type { Recipe } from "../types";

export default function RecipeDetailPage() {
  const { id = "" } = useParams();
  const [recipe, setRecipe] = useState<Recipe | null>(null);
  const [error, setError] = useState("");

  useEffect(() => {
    let active = true;
    setRecipe(null);
    setError("");
    getRecipe(id)
      .then((found) => active && setRecipe(found))
      .catch((caught) => active && setError(errorMessage(caught, "Could not load this recipe.")));
    return () => {
      active = false;
    };
  }, [id]);

  return (
    <AppShell>
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
            <p className="byline">By {authorName(recipe)}</p>
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
            {/* Reviews and comments go here */}
            <section id="reviews-section"></section>
          </>
        )}
      </article>
    </AppShell>
  );
}
