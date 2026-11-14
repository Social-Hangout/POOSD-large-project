import { useEffect, useState } from "react";
import { useSearchParams } from "react-router-dom";
import { errorMessage } from "../api/client";
import { searchRecipes } from "../api/recipes";
import AppShell from "../components/AppShell";
import Pagination from "../components/Pagination";
import RecipeCard from "../components/RecipeCard";
import type { SearchResponse } from "../types";

// Matches the server's limit (docs/api-contract.md, route 10)
const MAX_QUERY = 200;
const DEBOUNCE_MS = 250;

// Server-side ingredient search that updates as you type.
// The text lives in the URL (?q=chick,rice) so a search can be shared or refreshed.
export default function SearchPage() {
  const [params, setParams] = useSearchParams();
  const query = params.get("q") ?? "";
  const [page, setPage] = useState(1);
  const [data, setData] = useState<SearchResponse | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  function setQuery(text: string) {
    setPage(1);
    setParams(text ? { q: text } : {}, { replace: true });
  }

  useEffect(() => {
    setError("");
    // Commas and spaces alone are not a search; the server would answer 400
    if (!query.replace(/[,\s]/g, "")) {
      setData(null);
      setLoading(false);
      return;
    }
    setLoading(true);
    // Wait 250 ms after the last keypress, and cancel the previous request,
    // so a slow old answer can never overwrite a newer one
    const controller = new AbortController();
    const timer = window.setTimeout(async () => {
      try {
        const response = await searchRecipes(query, page, controller.signal);
        setData(response);
        setLoading(false);
      } catch (caught) {
        if ((caught as Error).name === "AbortError") return;
        setError(errorMessage(caught, "Search failed. Please try again."));
        setLoading(false);
      }
    }, DEBOUNCE_MS);
    return () => {
      window.clearTimeout(timer);
      controller.abort();
    };
  }, [query, page]);

  const hasQuery = Boolean(query.replace(/[,\s]/g, ""));

  return (
    <AppShell>
      <section className="kitchen-hero">
        <div className="hero-heading">
          <div>
            <p className="eyebrow">SEARCH BY INGREDIENT</p>
            <h1>What’s in your kitchen?</h1>
            <p>Separate ingredients with commas. Partial words work too, like “chick, rice”.</p>
          </div>
        </div>
        <label className="hero-search">
          <img src="/assets/f3272.svg" alt="" />
          <input
            autoFocus
            value={query}
            maxLength={MAX_QUERY}
            onChange={(event) => setQuery(event.target.value)}
            placeholder="e.g. chicken, rice"
            aria-label="Search by ingredient"
          />
          {loading && <span className="search-spinner" aria-label="Searching" />}
        </label>
      </section>

      <section className="recipe-section">
        {!hasQuery ? (
          <div className="loading-grid">Start typing an ingredient to see matching recipes.</div>
        ) : error ? (
          <div className="loading-grid">{error}</div>
        ) : !data ? (
          <div className="loading-grid">Searching…</div>
        ) : data.results.length === 0 ? (
          <div className="loading-grid">No recipes match yet</div>
        ) : (
          <>
            {/* Shown in the order the server ranked them; never re-sorted here */}
            <div className="recipe-grid">
              {data.results.map((result) => (
                <RecipeCard
                  key={result.id}
                  recipe={result}
                  showAllIngredients
                  badge={`Matches ${result.matchedTerms} of ${result.totalTerms}`}
                />
              ))}
            </div>
            <Pagination page={page} totalPages={data.totalPages} onChange={setPage} />
          </>
        )}
      </section>
    </AppShell>
  );
}
