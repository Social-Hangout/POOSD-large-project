import type { ReactNode } from "react";
import { Link } from "react-router-dom";
import MealDbCredit from "./MealDbCredit";

export default function AuthShell({ step, children }: { step: string; children: ReactNode }) {
  return (
    <main className="auth-page">
      <header className="auth-header">
        <Link to="/" className="brand" aria-label="Savory home">
          Savory<span>.</span>
        </Link>
        <div className="help-nav">
          <span>{step}</span>
          <i />
          <a href="mailto:help@savory.example">Need help?</a>
        </div>
      </header>
      <div className="auth-layout">
        <aside className="inspiration-panel">
          <p className="eyebrow">LESS WASTE. MORE WONDER.</p>
          <h1>Cook with what you have.</h1>
          <p className="panel-copy">
            Turn everyday ingredients into something delicious. Your next favorite meal starts here.
          </p>
          <div className="food-collage" aria-hidden="true">
            <div className="fresh-badge">
              <img src="/assets/0dd93.svg" alt="" /> A fresh start, every day
            </div>
            <img className="bowl bowl-small" src="/assets/897b8.png" alt="" />
            <img className="bowl bowl-medium" src="/assets/8bda8.png" alt="" />
            <img className="bowl bowl-large" src="/assets/24a21.png" alt="" />
          </div>
          <p className="panel-foot">Good food. Simple ingredients. Endless possibilities.</p>
        </aside>
        <section className="auth-form-area">{children}</section>
      </div>
      <footer className="auth-footer">
        <span>© 2026 Savory. Made for your everyday kitchen.</span>
        <div>
          <MealDbCredit />
          <a href="#privacy">Privacy policy</a>
          <a href="#terms">Terms of use</a>
        </div>
      </footer>
    </main>
  );
}
