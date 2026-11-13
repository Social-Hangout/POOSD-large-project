// Thrown for any non-2xx reply, carrying the API's { error } message and the status code
export class ApiError extends Error {
  status: number;
  constructor(message: string, status: number) {
    super(message);
    this.status = status;
  }
}

export async function api<T>(path: string, options: RequestInit = {}): Promise<T> {
  const token = localStorage.getItem("token");
  const carriesToken = Boolean(token && !path.startsWith("/auth/"));
  const response = await fetch(`/api${path}`, {
    ...options,
    headers: {
      ...(options.body ? { "Content-Type": "application/json" } : {}),
      ...(carriesToken ? { Authorization: `Bearer ${token}` } : {}),
      ...options.headers,
    },
  });

  const body = await response.json().catch(() => ({}));
  if (!response.ok) {
    if (response.status === 401 && carriesToken) {
      localStorage.removeItem("token");
      localStorage.removeItem("user");
      window.location.assign("/");
    }
    throw new ApiError(body.error || "Something went wrong. Please try again.", response.status);
  }
  return body as T;
}

export function errorMessage(caught: unknown, fallback: string) {
  return caught instanceof Error && caught.message ? caught.message : fallback;
}
