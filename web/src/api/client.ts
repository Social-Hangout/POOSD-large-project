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
    throw new Error(body.error || "Something went wrong. Please try again.");
  }
  return body as T;
}
