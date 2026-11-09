import { FormEvent, useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { errorMessage } from "../api/client";
import { getMe, updateMe } from "../api/users";
import AppShell from "../components/AppShell";
import { FormField, StatusMessage } from "../components/FormControls";
import { useAuth } from "../context/AuthContext";

// GET and PUT /api/users/me: view your account and change your name
export default function ProfilePage() {
  const { user, updateUser, logout } = useAuth();
  const [firstName, setFirstName] = useState(user?.firstName ?? "");
  const [lastName, setLastName] = useState(user?.lastName ?? "");
  const [email, setEmail] = useState(user?.email ?? "");
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [status, setStatus] = useState("");
  const [error, setError] = useState("");

  // Load the latest copy from the server, in case it changed on another device
  useEffect(() => {
    getMe()
      .then((me) => {
        updateUser(me);
        setFirstName(me.firstName);
        setLastName(me.lastName);
        setEmail(me.email);
      })
      .catch((caught) => setError(errorMessage(caught, "Could not load your profile.")))
      .finally(() => setLoading(false));
  }, [updateUser]);

  async function submit(event: FormEvent) {
    event.preventDefault();
    setStatus("");
    setError("");
    const first = firstName.trim();
    const last = lastName.trim();
    if (!first || !last || first.length > 50 || last.length > 50) {
      setError("First and last name must be 1 to 50 characters");
      return;
    }
    setSaving(true);
    try {
      const saved = await updateMe({ firstName: first, lastName: last });
      updateUser(saved);
      setStatus("Your profile was saved.");
    } catch (caught) {
      setError(errorMessage(caught, "Could not save your profile."));
    } finally {
      setSaving(false);
    }
  }

  const changed = firstName.trim() !== (user?.firstName ?? "") || lastName.trim() !== (user?.lastName ?? "");

  return (
    <AppShell>
      <article className="detail-card form-card profile-card">
        <p className="eyebrow">YOUR ACCOUNT</p>
        <h1>Profile</h1>
        {loading && !user ? (
          <p className="muted-copy">Loading your profile…</p>
        ) : (
          <form className="auth-form" onSubmit={submit} noValidate>
            <div className="name-row">
              <FormField
                label="First name"
                name="firstName"
                value={firstName}
                onChange={(value) => {
                  setFirstName(value);
                  setStatus("");
                }}
                autoComplete="given-name"
              />
              <FormField
                label="Last name"
                name="lastName"
                value={lastName}
                onChange={(value) => {
                  setLastName(value);
                  setStatus("");
                }}
                autoComplete="family-name"
              />
            </div>
            <label className="form-field">
              <span>Email</span>
              <div className="input-wrap">
                <input value={email} readOnly disabled aria-describedby="email-note" />
              </div>
              <small id="email-note" className="field-hint">
                Email can’t be changed.
              </small>
            </label>
            {error && <StatusMessage error>{error}</StatusMessage>}
            {status && <StatusMessage>{status}</StatusMessage>}
            <button className="primary-button" disabled={saving || !changed}>
              {saving ? "Saving…" : "Save Changes"}
            </button>
          </form>
        )}
        <div className="profile-links">
          <Link to="/my-recipes">My recipes</Link>
          <Link to="/forgot-password">Change password</Link>
          <button type="button" className="text-button" onClick={logout}>
            Log out
          </button>
        </div>
      </article>
    </AppShell>
  );
}
