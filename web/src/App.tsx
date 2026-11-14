import type { ReactNode } from "react";
import { BrowserRouter, Navigate, Route, Routes } from "react-router-dom";
import { AuthProvider, useAuth } from "./context/AuthContext";
import AuthPage from "./pages/AuthPage";
import MyRecipesPage from "./pages/MyRecipesPage";
import ProfilePage from "./pages/ProfilePage";
import RecipeDetailPage from "./pages/RecipeDetailPage";
import RecipeFormPage from "./pages/RecipeFormPage";
import RecipesPage from "./pages/RecipesPage";
import SearchPage from "./pages/SearchPage";
import VerifyPage from "./pages/VerifyPage";

// Pages that need a login send everyone else to the landing page
function ProtectedRoute({ children }: { children: ReactNode }) {
  const { token } = useAuth();
  return token ? children : <Navigate to="/" replace />;
}

const protectedPages: [string, ReactNode][] = [
  ["/recipes", <RecipesPage />],
  ["/recipes/new", <RecipeFormPage />],
  ["/recipes/:id", <RecipeDetailPage />],
  ["/recipes/:id/edit", <RecipeFormPage />],
  ["/search", <SearchPage />],
  ["/my-recipes", <MyRecipesPage />],
  ["/profile", <ProfilePage />],
];

export default function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <Routes>
          <Route path="/" element={<AuthPage mode="login" />} />
          <Route path="/register" element={<AuthPage mode="register" />} />
          <Route path="/forgot-password" element={<AuthPage mode="forgot" />} />
          <Route path="/reset-password" element={<AuthPage mode="reset" />} />
          <Route path="/resend-verification" element={<AuthPage mode="resend" />} />
          <Route path="/verify" element={<VerifyPage />} />
          {protectedPages.map(([path, page]) => (
            <Route key={path} path={path} element={<ProtectedRoute>{page}</ProtectedRoute>} />
          ))}
          {/* The old placeholder home page now goes to the recipe list */}
          <Route path="/home" element={<Navigate to="/recipes" replace />} />
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </AuthProvider>
    </BrowserRouter>
  );
}
