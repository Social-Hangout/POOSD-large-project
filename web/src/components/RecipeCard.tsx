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

export default function RecipeCard({ recipe }: { recipe: Recipe }) {
  const shown = recipe.ingredients.slice(0, 3).map((item) => item.name).join(", ");
  const more = recipe.ingredients.length > 3 ? ` +${recipe.ingredients.length - 3} more` : "";
  return (
    <article className="recipe-card">
      <img className="recipe-image" src={imageFor(recipe.id)} alt="" />
      <h3>{recipe.title}</h3>
      <p>
        {shown}
        {more}
      </p>
      <footer>
        <span>By {recipe.author?.firstName || "Savory cook"}</span>
        <Link to={`/recipes/${recipe.id}`}>View Recipe</Link>
      </footer>
    </article>
  );
}
