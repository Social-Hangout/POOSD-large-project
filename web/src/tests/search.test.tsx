import { act, fireEvent, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";
import SearchPage from "../pages/SearchPage";
import type { SearchResult } from "../types";
import { jsonResponse, logIn, mockApi, renderPage } from "./helpers";

const chickenRice: SearchResult = {
  id: "1".repeat(24),
  title: "Chicken Fried Rice",
  ingredients: [
    { name: "chicken", amount: "1 cup" },
    { name: "rice", amount: "2 cups" },
  ],
  steps: ["Cook."],
  author: { id: "b".repeat(24), firstName: "Ana" },
  createdAt: "2026-11-01T00:00:00.000Z",
  matchedTerms: 2,
  totalTerms: 2,
};

function searchCalls(fetchMock: ReturnType<typeof mockApi>) {
  return fetchMock.mock.calls.filter(([url]) => String(url).includes("/recipes/search"));
}

describe("Search", () => {
  it("waits 250 ms after typing, then shows the server's results", async () => {
    vi.useFakeTimers();
    logIn();
    const fetchMock = mockApi(() => jsonResponse(200, { results: [chickenRice], page: 1, totalPages: 1 }));
    renderPage("/search", "/search", <SearchPage />);

    // Typing letter by letter: no request yet
    const box = screen.getByLabelText("Search by ingredient");
    for (const text of ["c", "ch", "chick", "chick,", "chick, rice"]) {
      fireEvent.change(box, { target: { value: text } });
      await act(() => vi.advanceTimersByTimeAsync(100));
    }
    expect(searchCalls(fetchMock)).toHaveLength(0);

    // 250 ms after the last keypress: exactly one request, for the full text
    await act(() => vi.advanceTimersByTimeAsync(150));
    expect(searchCalls(fetchMock)).toHaveLength(1);
    const sent = new URL(String(searchCalls(fetchMock)[0][0]), "http://localhost");
    expect(sent.searchParams.get("q")).toBe("chick, rice");

    // Back to the real clock so findByText can wait for the reply to render
    vi.useRealTimers();

    expect(await screen.findByText("Chicken Fried Rice")).toBeInTheDocument();
    expect(screen.getByText("Matches 2 of 2")).toBeInTheDocument();
  });

  it("says so when nothing matches", async () => {
    logIn();
    mockApi(() => jsonResponse(200, { results: [], page: 1, totalPages: 0 }));
    renderPage("/search?q=zzz", "/search", <SearchPage />);

    expect(await screen.findByText("No recipes match yet")).toBeInTheDocument();
  });

  it("shows a hint instead of searching when the box is empty", () => {
    logIn();
    const fetchMock = mockApi(() => jsonResponse(200, {}));
    renderPage("/search", "/search", <SearchPage />);

    expect(screen.getByText("Start typing an ingredient to see matching recipes.")).toBeInTheDocument();
    expect(searchCalls(fetchMock)).toHaveLength(0);
  });

  it("shows a clear message when the server can't be reached", async () => {
    logIn();
    vi.stubGlobal("fetch", vi.fn(() => Promise.reject(new TypeError("Failed to fetch"))));
    renderPage("/search?q=egg", "/search", <SearchPage />);

    expect(await screen.findByText(/Can't reach the server/)).toBeInTheDocument();
  });
});
