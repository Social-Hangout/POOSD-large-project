import type { ReactNode } from "react";
import { Link } from "react-router-dom";
import type { Recipe } from "../types";

// Our recipes have no image field, so each card gets one of the wireframe's
// food photos, picked the same way every time from the recipe's id.
const images = [
  "/assets/3ecaf.png",
  "/assets/412f6.png",
  "/assets/1df21.png",
  "/assets/da300.png",
  "/assets/31edd.png",
  "/assets/3751d.png",
];

export function imageFor(id: string) {
  let hash = 0;
  for (const char of id) hash = (hash * 31 + char.charCodeAt(0)) >>> 0;
  return images[hash % images.length];
}

export function authorName(recipe: Recipe) {
  return recipe.author?.firstName || "a former member";
}

// badge: optional extra line, such as "Matches 2 of 2" on search results.
// actions: optional buttons, such as Edit and Delete on My Recipes.
export default function RecipeCard({
  recipe,
  badge,
  actions,
  showAllIngredients = false,
}: {
  recipe: Recipe;
  badge?: ReactNode;
  actions?: ReactNode;
  showAllIngredients?: boolean;
}) {
  const names = recipe.ingredients.map((item) => item.name);
  const shown = showAllIngredients ? names : names.slice(0, 3);
  const more = names.length - shown.length;
  return (
    <article className="recipe-card">
      <img className="recipe-image" src={imageFor(recipe.id)} alt="" />
      {badge && <p className="match-badge">{badge}</p>}
      <h3>{recipe.title}</h3>
      <p>
        {shown.join(", ")}
        {more > 0 && ` +${more} more`}
      </p>
      <footer>
        <span>By {authorName(recipe)}</span>
        <Link to={`/recipes/${recipe.id}`}>View Recipe</Link>
      </footer>
      {actions && <div className="card-actions">{actions}</div>}
    </article>
  );
}
