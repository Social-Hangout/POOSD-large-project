const { MongoClient } = require("mongodb");

const MONGO_URI = process.env.MONGO_URI;
const DB_NAME = "recipies";
const API = "https://www.themealdb.com/api/json/v1/1";

function extractIngredients(meal) {
  const output = [];
  for (let i = 1; i <= 20; i++) {
    const name = (meal[`strIngredient${i}`] || "").trim();
    const amount = (meal[`strMeasure${i}`] || "").trim();
    if (name) output.push({ name, amount });
  }
  return output;
}

function extractSteps(text) {
  let steps = (text || "")
    .split(/\r?\n+/)
    .map(s => s.trim())
    .map(s => s.replace(/^(step\s*)?\d+\s*[.):\-]?\s*/i, "").trim())
    .filter(Boolean);

  if (steps.length === 1 && steps[0].length > 200) {
    steps = steps[0]
      .split(/(?<=[.!?])\s+(?=[A-Z])/)
      .map(s => s.trim())
      .filter(Boolean);
  }

  return steps;
}

function toRecipe(meal) {
  return {
    sourceId: `mealdb:${meal.idMeal}`,
    title: meal.strMeal,
    tags: [meal.strCategory, meal.strArea].filter(Boolean),
    ingredients: extractIngredients(meal),
    steps: extractSteps(meal.strInstructions),
    createdAt: new Date(),
  };
}

async function fetchAllMeals() {
  const byId = new Map();
  for (const letter of "abcdefghijklmnopqrstuvwxyz") {
    const res = await fetch(`${API}/search.php?f=${letter}`);
    const data = await res.json();
    for (const meal of data.meals || []) byId.set(meal.idMeal, meal);
    await new Promise(r => setTimeout(r, 200));
  }
  return [...byId.values()];
}

async function main() {
  const client = new MongoClient(MONGO_URI);
  try {
    await client.connect();
    const recipes = client.db(DB_NAME).collection("recipes");
    await recipes.createIndex({ sourceId: 1 }, { unique: true });

    const meals = await fetchAllMeals();
    const ops = meals.map(m => {
      const { createdAt, ...rest } = toRecipe(m);
      return {
        updateOne: {
          filter: { sourceId: rest.sourceId },
          update: { $set: rest, $setOnInsert: { createdAt } },
          upsert: true,
        },
      };
    });

    if (!ops.length) return console.log("No meals fetched");
    const result = await recipes.bulkWrite(ops);
    console.log(`Inserted ${result.upsertedCount}, updated ${result.modifiedCount}`);
  } finally {
    await client.close();
  }
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});