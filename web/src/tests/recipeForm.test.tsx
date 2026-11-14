import { fireEvent, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import RecipeFormPage from "../pages/RecipeFormPage";
import { jsonResponse, logIn, mockApi, renderPage } from "./helpers";

function renderForm() {
  logIn();
  const fetchMock = mockApi(() => jsonResponse(201, {}));
  renderPage("/recipes/new", "/recipes/new", <RecipeFormPage />);
  return fetchMock;
}

// Clicks a button as many times as it allows (stops when it becomes disabled)
function clickUntilDisabled(name: RegExp) {
  for (let i = 0; i < 20; i++) {
    const button = screen.getByRole("button", { name });
    if (button.hasAttribute("disabled")) return;
    fireEvent.click(button);
  }
}

describe("Recipe form", () => {
  it("stops at 10 ingredients (no 11th)", () => {
    renderForm();
    clickUntilDisabled(/Add ingredient|10 ingredients max/);

    expect(screen.getAllByLabelText(/^Ingredient \d+ name$/)).toHaveLength(10);
    expect(screen.queryByLabelText("Ingredient 11 name")).not.toBeInTheDocument();
    expect(screen.getByRole("button", { name: "10 ingredients max" })).toBeDisabled();
  });

  it("stops at 8 steps (no 9th)", () => {
    renderForm();
    clickUntilDisabled(/Add step|8 steps max/);

    expect(screen.getAllByLabelText(/^Step \d+$/)).toHaveLength(8);
    expect(screen.queryByLabelText("Step 9")).not.toBeInTheDocument();
    expect(screen.getByRole("button", { name: "8 steps max" })).toBeDisabled();
  });

  it("shows the singular-name hint", () => {
    renderForm();
    expect(screen.getByText("Use a singular name, like tomato.")).toBeInTheDocument();
  });

  it("explains what's missing instead of sending an empty recipe", () => {
    const fetchMock = renderForm();
    fireEvent.click(screen.getByRole("button", { name: "Publish Recipe" }));

    expect(screen.getByRole("alert")).toHaveTextContent("Title must be 1 to 100 characters");
    expect(fetchMock).not.toHaveBeenCalled();
  });
});
