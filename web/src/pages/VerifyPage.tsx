import { useEffect, useRef, useState } from "react";
import { Link, useSearchParams } from "react-router-dom";
import { verify } from "../api/auth";
import MealDbCredit from "../components/MealDbCredit";

type State = "loading" | "success" | "error";

export default function VerifyPage() {
  const [params] = useSearchParams();
  const [state, setState] = useState<State>("loading");
  // A verify link works only once. StrictMode runs effects twice in development, and the
  // second request would get 400 and replace the success message, so send it only once.
  const sent = useRef(false);
  useEffect(() => {
    if (sent.current) return;
    sent.current = true;
    const token = params.get("token");
    if (!token) {
      setState("error");
      return;
    }
    verify(token)
      .then(() => setState("success"))
      .catch(() => setState("error"));
  }, [params]);

  return (
    <main className="state-page">
      <Link to="/" className="brand">
        Savory<span>.</span>
      </Link>
      <section className="state-card">
        <p className="eyebrow">YOUR KITCHEN AWAITS</p>
        <h1>
          {state === "loading"
            ? "Verifying…"
            : state === "success"
              ? "Email verified!"
              : "This link is invalid or expired"}
        </h1>
        {state === "success" && <p>You can now log in</p>}
        {state !== "loading" && (
          <Link className="primary-button link-button" to="/">
            Back to login
          </Link>
        )}
      </section>
      <footer className="page-footer">
        <MealDbCredit />
      </footer>
    </main>
  );
}
