import { useEffect, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { errorMessage } from "../api/client";
import { getRecipes } from "../api/recipes";
import AppShell from "../components/AppShell";
import Pagination from "../components/Pagination";
import RecipeCard, { authorName, imageFor } from "../components/RecipeCard";
import type { RecipeListResponse } from "../types";

const PAGE_SIZE = 12;

export default function RecipesPage() {
  const navigate = useNavigate();
  const [page, setPage] = useState(1);
  const [data, setData] = useState<RecipeListResponse | null>(null);
  const [error, setError] = useState("");
  const [reload, setReload] = useState(0);

  useEffect(() => {
    let active = true;
    setData(null);
    setError("");
    getRecipes(page, PAGE_SIZE)
      .then((response) => active && setData(response))
      .catch((caught) => active && setError(errorMessage(caught, "Could not load recipes.")));
    return () => {
      active = false;
    };
  }, [page, reload]);

  const featured = page === 1 ? data?.recipes[0] : undefined;

  return (
    <AppShell>
      <section className="kitchen-hero">
        <div className="hero-heading">
          <div>
            <h1>What’s in your kitchen?</h1>
            <p>Type the ingredients you have, separated by commas.</p>
          </div>
        </div>
        {/* Typing here jumps to the search page, which searches as you type */}
        <label className="hero-search">
          <img src="/assets/f3272.svg" alt="" />
          <input
            placeholder="e.g. chicken, rice"
            aria-label="Search by ingredient"
            onChange={(event) =>
              navigate(`/search?q=${encodeURIComponent(event.target.value)}`)
            }
          />
        </label>
      </section>

      {featured && (
        <section className="featured">
          <img src={imageFor(featured.id)} alt="" />
          <div>
            <p className="eyebrow">NEWEST RECIPE</p>
            <h2>{featured.title}</h2>
            <p>
              {featured.ingredients.length} ingredients · {featured.steps.length} steps · by{" "}
              {authorName(featured)}
            </p>
            <Link to={`/recipes/${featured.id}`}>View recipe →</Link>
          </div>
        </section>
      )}

      <section className="recipe-section">
        <div className="section-heading">
          <div>
            <p className="eyebrow">FROM OUR COMMUNITY</p>
            <h2>Explore recipes</h2>
          </div>
        </div>

        {error ? (
          <div className="loading-grid">
            <div>
              <p>{error}</p>
              <button className="primary-button" onClick={() => setReload((n) => n + 1)}>
                Try again
              </button>
            </div>
          </div>
        ) : !data ? (
          <div className="loading-grid">Finding something delicious…</div>
        ) : data.recipes.length === 0 ? (
          <div className="loading-grid">No recipes yet</div>
        ) : (
          <div className="recipe-grid">
            {data.recipes.map((recipe) => (
              <RecipeCard key={recipe.id} recipe={recipe} />
            ))}
          </div>
        )}

        {data && <Pagination page={page} totalPages={data.totalPages} onChange={setPage} />}
      </section>
    </AppShell>
  );
}
