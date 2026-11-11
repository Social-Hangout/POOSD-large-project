import { fireEvent, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import AuthPage from "../pages/AuthPage";
import { jsonResponse, mockApi, renderPage } from "./helpers";

function fillAndSubmit(email: string, password: string) {
  fireEvent.change(screen.getByLabelText("Email"), { target: { value: email } });
  fireEvent.change(screen.getByLabelText("Password"), { target: { value: password } });
  fireEvent.click(screen.getByRole("button", { name: "Log In" }));
}

describe("Login form", () => {
  it("shows the server's error message on a wrong password", async () => {
    mockApi(() => jsonResponse(401, { error: "Invalid credentials" }));
    renderPage("/", "/", <AuthPage mode="login" />);

    fillAndSubmit("mo@test.com", "wrong-password");

    expect(await screen.findByText("Invalid credentials")).toBeInTheDocument();
    // Still on the login form (a wrong password must not log you out or reload)
    expect(screen.getByRole("button", { name: "Log In" })).toBeEnabled();
  });

  it("asks to verify the email when the account isn't verified (403)", async () => {
    mockApi(() => jsonResponse(403, { error: "Please verify your email first" }));
    renderPage("/", "/", <AuthPage mode="login" />);

    fillAndSubmit("new@test.com", "Passw0rd!");

    expect(await screen.findByText("Please verify your email before logging in.")).toBeInTheDocument();
  });

  it("explains an expired login when sent back to the login page", () => {
    renderPage("/?expired=1", "/", <AuthPage mode="login" />);
    expect(screen.getByText("Your session expired. Please log in again.")).toBeInTheDocument();
  });

  it("shows the TheMealDB credit in the footer", () => {
    renderPage("/", "/", <AuthPage mode="login" />);
    expect(screen.getByRole("link", { name: "TheMealDB" })).toHaveAttribute("href", "https://www.themealdb.com");
  });
});
