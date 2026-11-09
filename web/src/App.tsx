import type { ReactNode } from "react";
import { BrowserRouter, Navigate, Route, Routes } from "react-router-dom";
import { AuthProvider, useAuth } from "./context/AuthContext";
import AuthPage from "./pages/AuthPage";
import HomePage from "./pages/HomePage";
import RecipeDetailPage from "./pages/RecipeDetailPage";
import RecipesPage from "./pages/RecipesPage";
import VerifyPage from "./pages/VerifyPage";

// Pages that need a login send everyone else to the landing page
function ProtectedRoute({ children }: { children: ReactNode }) {
  const { token } = useAuth();
  return token ? children : <Navigate to="/" replace />;
}

const protectedPages: [string, ReactNode][] = [
  ["/home", <HomePage />],
  ["/recipes", <RecipesPage />],
  ["/recipes/:id", <RecipeDetailPage />],
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
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </AuthProvider>
    </BrowserRouter>
  );
}
