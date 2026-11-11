// Thrown for any non-2xx reply, carrying the API's { error } message and the status code
export class ApiError extends Error {
  status: number;
  constructor(message: string, status: number) {
    super(message);
    this.status = status;
  }
}

// Shown when the request never reaches the server (offline, server down, DNS)
export const NETWORK_ERROR = "Can't reach the server. Check your internet connection and try again.";

export async function api<T>(path: string, options: RequestInit = {}): Promise<T> {
  const token = localStorage.getItem("token");
  const carriesToken = Boolean(token && !path.startsWith("/auth/"));
  let response: Response;
  try {
    response = await fetch(`/api${path}`, {
      ...options,
      headers: {
        ...(options.body ? { "Content-Type": "application/json" } : {}),
        ...(carriesToken ? { Authorization: `Bearer ${token}` } : {}),
        ...options.headers,
      },
    });
  } catch (caught) {
    // A cancelled request (e.g. search typing) is not an error to show
    if ((caught as Error).name === "AbortError") throw caught;
    // Otherwise the browser's own text is just "Failed to fetch"
    throw new ApiError(NETWORK_ERROR, 0);
  }

  const body = await response.json().catch(() => ({}));
  if (!response.ok) {
    // An expired or invalid token: log out and say why on the login page.
    // A wrong password also returns 401, but carries no token, so its message shows instead.
    if (response.status === 401 && carriesToken) {
      localStorage.removeItem("token");
      localStorage.removeItem("user");
      window.location.assign("/?expired=1");
    }
    throw new ApiError(body.error || "Something went wrong. Please try again.", response.status);
  }
  return body as T;
}

export function errorMessage(caught: unknown, fallback: string) {
  return caught instanceof Error && caught.message ? caught.message : fallback;
}
