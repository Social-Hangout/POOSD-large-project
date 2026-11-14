import type { ReactNode } from "react";
import { Link, NavLink } from "react-router-dom";
import { useAuth } from "../context/AuthContext";
import MealDbCredit from "./MealDbCredit";

const links = [
  { to: "/recipes", label: "Recipes", end: true },
  { to: "/search", label: "Search", end: false },
  { to: "/my-recipes", label: "My Recipes", end: false },
];

// The navigation bar, page width and footer shared by every logged-in page
export default function AppShell({ children }: { children: ReactNode }) {
  const { user, logout } = useAuth();
  return (
    <div className="app-shell">
      <header className="app-nav">
        <Link className="brand" to="/recipes">
          Savory<span>.</span>
        </Link>
        <nav aria-label="Main">
          {links.map((link) => (
            <NavLink key={link.to} to={link.to} end={link.end}>
              {link.label}
            </NavLink>
          ))}
          <NavLink className="nav-new" to="/recipes/new">
            + New Recipe
          </NavLink>
        </nav>
        <div className="nav-user">
          <NavLink to="/profile" className="nav-profile" title="Your profile">
            <span className="nav-avatar">{user?.firstName?.[0] ?? "?"}</span>
            {user?.firstName ?? "Profile"}
          </NavLink>
          <button type="button" onClick={logout}>
            Log out
          </button>
        </div>
      </header>
      <main className="app-main">{children}</main>
      <footer className="page-footer">
        <MealDbCredit />
      </footer>
    </div>
  );
}
