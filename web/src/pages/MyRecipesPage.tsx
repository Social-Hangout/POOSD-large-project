import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { errorMessage } from "../api/client";
import { deleteRecipe, getRecipes } from "../api/recipes";
import AppShell from "../components/AppShell";
import Pagination from "../components/Pagination";
import RecipeCard from "../components/RecipeCard";
import type { Recipe, RecipeListResponse } from "../types";

const PAGE_SIZE = 12;

// The logged-in user's own recipes, with edit and delete
export default function MyRecipesPage() {
  const [page, setPage] = useState(1);
  const [data, setData] = useState<RecipeListResponse | null>(null);
  const [error, setError] = useState("");
  const [reload, setReload] = useState(0);

  useEffect(() => {
    let active = true;
    setError("");
    getRecipes(page, PAGE_SIZE, true)
      .then((response) => {
        if (!active) return;
        // Deleting the last recipe on a page leaves it empty; go back one page
        if (response.recipes.length === 0 && page > 1) setPage(page - 1);
        else setData(response);
      })
      .catch((caught) => active && setError(errorMessage(caught, "Could not load your recipes.")));
    return () => {
      active = false;
    };
  }, [page, reload]);

  return (
    <AppShell>
      <section className="recipe-section">
        <div className="section-heading">
          <div>
            <p className="eyebrow">YOUR KITCHEN</p>
            <h1 className="page-title">My Recipes</h1>
          </div>
          <Link className="primary-button link-button inline-button" to="/recipes/new">
            + New Recipe
          </Link>
        </div>

        {error ? (
          <div className="loading-grid">{error}</div>
        ) : !data ? (
          <div className="loading-grid">Loading your recipes…</div>
        ) : data.recipes.length === 0 ? (
          <div className="loading-grid">
            <div>
              <p>You haven’t shared any recipes yet.</p>
              <Link className="primary-button link-button inline-button" to="/recipes/new">
                Share your first recipe
              </Link>
            </div>
          </div>
        ) : (
          <div className="recipe-grid">
            {data.recipes.map((recipe) => (
              <RecipeCard
                key={recipe.id}
                recipe={recipe}
                actions={<OwnerActions recipe={recipe} onDeleted={() => setReload((n) => n + 1)} />}
              />
            ))}
          </div>
        )}

        {data && <Pagination page={page} totalPages={data.totalPages} onChange={setPage} />}
      </section>
    </AppShell>
  );
}

// Edit and a two-step Delete (asks for confirmation first)
export function OwnerActions({ recipe, onDeleted }: { recipe: Recipe; onDeleted: () => void }) {
  const [confirming, setConfirming] = useState(false);
  const [deleting, setDeleting] = useState(false);
  const [error, setError] = useState("");

  async function remove() {
    setDeleting(true);
    setError("");
    try {
      await deleteRecipe(recipe.id);
      onDeleted();
    } catch (caught) {
      setError(errorMessage(caught, "Could not delete the recipe."));
      setDeleting(false);
      setConfirming(false);
    }
  }

  if (confirming) {
    return (
      <div className="confirm-row" role="group" aria-label="Confirm delete">
        <span>Delete “{recipe.title}”? Its reviews and comments go too.</span>
        <button type="button" className="danger-button" onClick={remove} disabled={deleting}>
          {deleting ? "Deleting…" : "Yes, delete"}
        </button>
        <button type="button" className="text-button" onClick={() => setConfirming(false)} disabled={deleting}>
          Cancel
        </button>
      </div>
    );
  }
  return (
    <>
      {error && <p className="form-status error">{error}</p>}
      <Link className="text-button" to={`/recipes/${recipe.id}/edit`}>
        Edit
      </Link>
      <button type="button" className="text-button danger-text" onClick={() => setConfirming(true)}>
        Delete
      </button>
    </>
  );
}
