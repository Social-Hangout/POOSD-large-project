import { FormEvent, useEffect, useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import { ApiError, errorMessage } from "../api/client";
import { createRecipe, getRecipe, updateRecipe } from "../api/recipes";
import AppShell from "../components/AppShell";
import { useAuth } from "../context/AuthContext";
import type { Ingredient } from "../types";

// The contract's limits (docs/api-contract.md, "Limits and validation")
export const MAX_INGREDIENTS = 10;
export const MAX_STEPS = 8;
const MAX_TITLE = 100;
const MAX_NAME = 50;
const MAX_AMOUNT = 50;
const MAX_STEP = 500;

const emptyIngredient = (): Ingredient => ({ name: "", amount: "" });

// Checks the form before sending it, with the same messages the server uses
function validate(title: string, ingredients: Ingredient[], steps: string[]) {
  if (!title.trim() || title.trim().length > MAX_TITLE) return "Title must be 1 to 100 characters";
  if (ingredients.length < 1 || ingredients.length > MAX_INGREDIENTS)
    return "A recipe needs 1 to 10 ingredients";
  if (ingredients.some((item) => !item.name.trim() || item.name.trim().length > MAX_NAME))
    return "Ingredient names must be 1 to 50 characters";
  if (steps.length < 1 || steps.length > MAX_STEPS) return "A recipe needs 1 to 8 steps";
  if (steps.some((step) => !step.trim() || step.trim().length > MAX_STEP))
    return "Each step must be 1 to 500 characters";
  return "";
}

// /recipes/new creates a recipe; /recipes/:id/edit edits one of your own
export default function RecipeFormPage() {
  const { id } = useParams();
  const editing = Boolean(id);
  const navigate = useNavigate();
  const { user } = useAuth();

  const [title, setTitle] = useState("");
  const [ingredients, setIngredients] = useState<Ingredient[]>([emptyIngredient()]);
  const [steps, setSteps] = useState<string[]>([""]);
  const [loading, setLoading] = useState(editing);
  const [loadError, setLoadError] = useState("");
  const [error, setError] = useState("");
  const [saving, setSaving] = useState(false);

  // When editing, fill the form with the current recipe
  useEffect(() => {
    if (!id) return;
    getRecipe(id)
      .then((recipe) => {
        if (recipe.author?.id !== user?.id) {
          setLoadError("You can only edit your own recipes.");
          return;
        }
        setTitle(recipe.title);
        setIngredients(recipe.ingredients.map((item) => ({ ...item })));
        setSteps([...recipe.steps]);
      })
      .catch((caught) => setLoadError(errorMessage(caught, "Could not load this recipe.")))
      .finally(() => setLoading(false));
  }, [id, user?.id]);

  // An old error goes away as soon as the user edits the form
  useEffect(() => {
    setError("");
  }, [title, ingredients, steps]);

  function changeIngredient(index: number, field: keyof Ingredient, value: string) {
    setIngredients((current) =>
      current.map((item, i) => (i === index ? { ...item, [field]: value } : item)),
    );
  }

  async function submit(event: FormEvent) {
    event.preventDefault();
    const problem = validate(title, ingredients, steps);
    setError(problem);
    if (problem) return;

    const body = {
      title: title.trim(),
      ingredients: ingredients.map((item) => ({ name: item.name.trim(), amount: item.amount.trim() })),
      steps: steps.map((step) => step.trim()),
    };
    setSaving(true);
    try {
      const saved = id ? await updateRecipe(id, body) : await createRecipe(body);
      navigate(`/recipes/${saved.id}`);
    } catch (caught) {
      // Show the server's own message, e.g. "Not your recipe" or a limit it rejected
      setError(
        caught instanceof ApiError && caught.status === 404
          ? "This recipe no longer exists."
          : errorMessage(caught, "Could not save the recipe."),
      );
      setSaving(false);
    }
  }

  return (
    <AppShell>
      <article className="detail-card form-card">
        <Link className="back-link detail-back" to={id ? `/recipes/${id}` : "/my-recipes"}>
          ← &nbsp;Back
        </Link>
        <p className="eyebrow">{editing ? "EDIT RECIPE" : "NEW RECIPE"}</p>
        <h1>{editing ? "Edit your recipe" : "Share a recipe"}</h1>

        {loading ? (
          <p className="muted-copy">Loading your recipe…</p>
        ) : loadError ? (
          <p className="form-status error">{loadError}</p>
        ) : (
          <form className="recipe-form" onSubmit={submit} noValidate>
            <label className="form-field">
              <span>Title</span>
              <div className="input-wrap">
                <input
                  value={title}
                  maxLength={MAX_TITLE}
                  onChange={(event) => setTitle(event.target.value)}
                  placeholder="Garlic Butter Pasta"
                />
              </div>
            </label>

            <fieldset>
              <legend>
                Ingredients <small>{ingredients.length} of {MAX_INGREDIENTS}</small>
              </legend>
              <p className="field-hint">Use a singular name, like tomato.</p>
              {ingredients.map((item, index) => (
                <div className="ingredient-row" key={index}>
                  <input
                    aria-label={`Ingredient ${index + 1} name`}
                    value={item.name}
                    maxLength={MAX_NAME}
                    onChange={(event) => changeIngredient(index, "name", event.target.value)}
                    placeholder="tomato"
                  />
                  <input
                    aria-label={`Ingredient ${index + 1} amount`}
                    value={item.amount}
                    maxLength={MAX_AMOUNT}
                    onChange={(event) => changeIngredient(index, "amount", event.target.value)}
                    placeholder="2 cups (optional)"
                  />
                  <button
                    type="button"
                    className="row-remove"
                    aria-label={`Remove ingredient ${index + 1}`}
                    disabled={ingredients.length === 1}
                    onClick={() => setIngredients((current) => current.filter((_, i) => i !== index))}
                  >
                    ×
                  </button>
                </div>
              ))}
              <button
                type="button"
                className="secondary-button"
                disabled={ingredients.length >= MAX_INGREDIENTS}
                onClick={() => setIngredients((current) => [...current, emptyIngredient()])}
              >
                {ingredients.length >= MAX_INGREDIENTS ? "10 ingredients max" : "+ Add ingredient"}
              </button>
            </fieldset>

            <fieldset>
              <legend>
                Steps <small>{steps.length} of {MAX_STEPS}</small>
              </legend>
              {steps.map((step, index) => (
                <div className="step-row" key={index}>
                  <span className="step-number">{index + 1}</span>
                  <textarea
                    aria-label={`Step ${index + 1}`}
                    value={step}
                    maxLength={MAX_STEP}
                    rows={2}
                    onChange={(event) =>
                      setSteps((current) =>
                        current.map((text, i) => (i === index ? event.target.value : text)),
                      )
                    }
                    placeholder="Describe this step"
                  />
                  <button
                    type="button"
                    className="row-remove"
                    aria-label={`Remove step ${index + 1}`}
                    disabled={steps.length === 1}
                    onClick={() => setSteps((current) => current.filter((_, i) => i !== index))}
                  >
                    ×
                  </button>
                </div>
              ))}
              <button
                type="button"
                className="secondary-button"
                disabled={steps.length >= MAX_STEPS}
                onClick={() => setSteps((current) => [...current, ""])}
              >
                {steps.length >= MAX_STEPS ? "8 steps max" : "+ Add step"}
              </button>
            </fieldset>

            {error && (
              <p className="form-status error" role="alert">
                {error}
              </p>
            )}
            <button className="primary-button" disabled={saving}>
              {saving ? "Saving…" : editing ? "Save Changes" : "Publish Recipe"}
            </button>
          </form>
        )}
      </article>
    </AppShell>
  );
}
