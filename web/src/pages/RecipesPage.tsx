import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { getRecipes } from "../api/recipes";
import MealDbCredit from "../components/MealDbCredit";
import RecipeCard, { imageFor } from "../components/RecipeCard";
import { useAuth } from "../context/AuthContext";
import type { RecipeListResponse } from "../types";

const PAGE_SIZE = 12;

export default function RecipesPage() {
  const { user, logout } = useAuth();
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
      .catch((caught: Error) => active && setError(caught.message || "Could not load recipes."));
    return () => {
      active = false;
    };
  }, [page, reload]);

  const featured = data?.results[0];

  return (
    <main className="dashboard-page">
      <aside className="sidebar">
        <span className="side-brand">
          Savory<span>.</span>
        </span>
        <div className="avatar">
          {user?.firstName?.[0] || ""}
          {user?.lastName?.[0] || ""}
        </div>
        <nav aria-label="Dashboard navigation">
          <button className="active" aria-label="Recipes">
            <img src="/assets/f7713.svg" alt="" />
          </button>
        </nav>
        <button className="side-logout" onClick={logout} aria-label="Log out">
          <img src="/assets/4d6b2.svg" alt="" />
        </button>
      </aside>
      <section className="dashboard-content">
        <header className="dashboard-header">
          {/* Search is wired up in Week 3 (GET /api/recipes/search). */}
          <label>
            <img src="/assets/f3272.svg" alt="" />
            <input placeholder="Search by ingredient (coming soon)" disabled />
          </label>
          <div className="header-user">
            <span>Hi, {user?.firstName || "Chef"}</span>
            <button onClick={logout}>Log out</button>
          </div>
        </header>

        <section className="kitchen-hero">
          <div className="hero-heading">
            <div>
              <h1>What’s in your kitchen?</h1>
              <p>Browse recipes from the Savory community.</p>
            </div>
          </div>
        </section>

        {featured && page === 1 && (
          <section className="featured">
            <img src={imageFor(featured.id)} alt="" />
            <div>
              <p className="eyebrow">FEATURED RECIPE</p>
              <h2>{featured.title}</h2>
              <p>
                {featured.ingredients.length} ingredients · {featured.steps.length} steps · by{" "}
                {featured.author?.firstName || "a Savory cook"}
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
              <p>{error}</p>
              <button className="primary-button" onClick={() => setReload((n) => n + 1)}>
                Try again
              </button>
            </div>
          ) : !data ? (
            <div className="loading-grid">Finding something delicious…</div>
          ) : data.results.length === 0 ? (
            <div className="loading-grid">No recipes yet</div>
          ) : (
            <div className="recipe-grid">
              {data.results.map((recipe) => (
                <RecipeCard key={recipe.id} recipe={recipe} />
              ))}
            </div>
          )}

          {data && data.totalPages > 1 && (
            <nav className="pagination" aria-label="Recipe pages">
              <button disabled={page === 1} onClick={() => setPage((value) => value - 1)}>
                ←
              </button>
              {Array.from({ length: data.totalPages }, (_, index) => (
                <button
                  key={index}
                  className={page === index + 1 ? "active" : ""}
                  onClick={() => setPage(index + 1)}
                >
                  {index + 1}
                </button>
              ))}
              <button
                disabled={page >= data.totalPages}
                onClick={() => setPage((value) => value + 1)}
              >
                →
              </button>
            </nav>
          )}
        </section>
        <footer className="page-footer">
          <MealDbCredit />
        </footer>
      </section>
    </main>
  );
}
