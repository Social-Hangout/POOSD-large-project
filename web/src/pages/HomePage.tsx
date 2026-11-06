import { useAuth } from "../context/AuthContext";

// Placeholder landing page after login, to test that sign-in works end to end
export default function HomePage() {
  const { user, logout } = useAuth();
  return (
    <main className="state-page">
      <section className="state-card">
        <h1>Home page</h1>
        {user && <p>Logged in as {user.firstName} ({user.email})</p>}
        <button className="primary-button" style={{ width: "100%" }} onClick={logout}>
          Log out
        </button>
      </section>
    </main>
  );
}
