import type { User } from "../types";
import { api } from "./client";

export const register = (data: {
  firstName: string;
  lastName: string;
  email: string;
  password: string;
}) =>
  api<{ message: string }>("/auth/register", {
    method: "POST",
    body: JSON.stringify(data),
  });

export const login = (data: { email: string; password: string }) =>
  api<{ token: string; user: User }>("/auth/login", {
    method: "POST",
    body: JSON.stringify(data),
  });

export const verify = (token: string) =>
  api<{ message?: string }>("/auth/verify", {
    method: "POST",
    body: JSON.stringify({ token }),
  });

export const forgotPassword = (email: string) =>
  api<{ message: string }>("/auth/forgot-password", {
    method: "POST",
    body: JSON.stringify({ email }),
  });

export const resetPassword = (token: string, password: string) =>
  api<{ message?: string }>("/auth/reset-password", {
    method: "POST",
    body: JSON.stringify({ token, password }),
  });
