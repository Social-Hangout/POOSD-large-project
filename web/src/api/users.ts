import type { User } from "../types";
import { api } from "./client";

// 7. The logged-in user
export function getMe(): Promise<User> {
  return api<User>("/users/me");
}

// 8. Change first and last name (email can't change)
export function updateMe(fields: { firstName: string; lastName: string }): Promise<User> {
  return api<User>("/users/me", { method: "PUT", body: JSON.stringify(fields) });
}
