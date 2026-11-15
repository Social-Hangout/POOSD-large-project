import { render, screen } from "@testing-library/react";
import { afterEach, describe, expect, it } from "vitest";
import App from "../App";

// App uses the browser's real address bar, so set it before rendering
function openApp(path: string) {
  window.history.pushState({}, "", path);
  render(<App />);
}

describe("ProtectedRoute", () => {
  afterEach(() => window.history.pushState({}, "", "/"));

  it.each(["/recipes", "/search", "/my-recipes", "/recipes/new", "/profile"])(
    "sends a logged-out visitor from %s to the login page",
    (path) => {
      openApp(path);
      expect(window.location.pathname).toBe("/");
      expect(screen.getByRole("button", { name: "Log In" })).toBeInTheDocument();
    },
  );
});
