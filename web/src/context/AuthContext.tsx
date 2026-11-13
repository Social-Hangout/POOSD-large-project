import { createContext, useCallback, useContext, useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import type { User } from "../types";

interface AuthContextValue {
  token: string | null;
  user: User | null;
  login: (token: string, user: User) => void;
  logout: () => void;
}

const AuthContext = createContext<AuthContextValue | null>(null);

function readUser() {
  try {
    return JSON.parse(localStorage.getItem("user") || "null") as User | null;
  } catch {
    return null;
  }
}

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const navigate = useNavigate();
  const [token, setToken] = useState(() => localStorage.getItem("token"));
  const [user, setUser] = useState<User | null>(readUser);

  const login = useCallback((nextToken: string, nextUser: User) => {
    localStorage.setItem("token", nextToken);
    localStorage.setItem("user", JSON.stringify(nextUser));
    setToken(nextToken);
    setUser(nextUser);
  }, []);

  const logout = useCallback(() => {
    localStorage.removeItem("token");
    localStorage.removeItem("user");
    setToken(null);
    setUser(null);
    navigate("/");
  }, [navigate]);

  const value = useMemo(() => ({ token, user, login, logout }), [login, logout, token, user]);
  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const value = useContext(AuthContext);
  if (!value) throw new Error("useAuth must be used within AuthProvider");
  return value;
}
