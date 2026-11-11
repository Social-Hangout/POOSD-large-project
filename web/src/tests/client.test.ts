import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { api, ApiError, NETWORK_ERROR } from "../api/client";
import { jsonResponse, logIn, mockApi } from "./helpers";

// jsdom can't really navigate, so record where the app tried to go
let assign: ReturnType<typeof vi.fn>;
const realLocation = window.location;
beforeEach(() => {
  assign = vi.fn();
  Object.defineProperty(window, "location", {
    configurable: true,
    value: { ...realLocation, assign },
  });
});
afterEach(() => {
  Object.defineProperty(window, "location", { configurable: true, value: realLocation });
});

describe("api() wrapper", () => {
  it("turns a network failure into a clear message", async () => {
    vi.stubGlobal("fetch", vi.fn(() => Promise.reject(new TypeError("Failed to fetch"))));
    await expect(api("/recipes")).rejects.toMatchObject({ message: NETWORK_ERROR, status: 0 });
  });

  it("logs out and returns to the login page when the saved login has expired", async () => {
    logIn();
    mockApi(() => jsonResponse(401, { error: "Invalid or missing token" }));

    await expect(api("/recipes")).rejects.toBeInstanceOf(ApiError);
    expect(localStorage.getItem("token")).toBeNull();
    expect(assign).toHaveBeenCalledWith("/?expired=1");
  });

  it("does not log out on a wrong password (a 401 with no token)", async () => {
    mockApi(() => jsonResponse(401, { error: "Invalid credentials" }));

    await expect(api("/auth/login", { method: "POST", body: "{}" })).rejects.toMatchObject({
      message: "Invalid credentials",
      status: 401,
    });
    expect(assign).not.toHaveBeenCalled();
  });

  it("sends the saved token on protected routes, but not on /auth routes", async () => {
    logIn();
    const fetchMock = mockApi(() => jsonResponse(200, {}));
    await api("/recipes");
    await api("/auth/login", { method: "POST", body: "{}" });

    const headers = fetchMock.mock.calls.map(([, init]) => (init?.headers ?? {}) as Record<string, string>);
    expect(headers[0].Authorization).toBe("Bearer test-token");
    expect(headers[1].Authorization).toBeUndefined();
  });
});
