import { render } from "@testing-library/react";
import type { ReactNode } from "react";
import { MemoryRouter, Route, Routes } from "react-router-dom";
import { vi } from "vitest";
import { AuthProvider } from "../context/AuthContext";
import type { User } from "../types";

export const testUser: User = {
  id: "a".repeat(24),
  firstName: "Mo",
  lastName: "Landais",
  email: "mo@test.com",
};

// A fetch reply with a JSON body, like the API sends
export function jsonResponse(status: number, body: unknown) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

// Replaces fetch for one test. The handler gets the path after /api and the request options.
export function mockApi(handler: (path: string, init?: RequestInit) => Response | Promise<Response>) {
  const fetchMock = vi.fn((url: string, init?: RequestInit) => Promise.resolve(handler(url.replace(/^\/api/, ""), init)));
  vi.stubGlobal("fetch", fetchMock);
  return fetchMock;
}

// Saves a login the way AuthContext does, so protected pages render
export function logIn(user: User = testUser) {
  localStorage.setItem("token", "test-token");
  localStorage.setItem("user", JSON.stringify(user));
}

// Renders one page at a URL, inside the router and AuthProvider like the real app.
// "/" shows a marker so tests can tell when a page redirected to the login page.
export function renderPage(path: string, routePath: string, page: ReactNode) {
  return render(
    <MemoryRouter initialEntries={[path]}>
      <AuthProvider>
        <Routes>
          <Route path={routePath} element={page} />
          <Route path="/" element={<p>Login page</p>} />
        </Routes>
      </AuthProvider>
    </MemoryRouter>,
  );
}
