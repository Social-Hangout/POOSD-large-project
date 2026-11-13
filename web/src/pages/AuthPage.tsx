import { FormEvent, useMemo, useState } from "react";
import { Link, useNavigate, useSearchParams } from "react-router-dom";
import * as authApi from "../api/auth";
import { ApiError, errorMessage } from "../api/client";
import AuthShell from "../components/AuthShell";
import { FormField, StatusMessage } from "../components/FormControls";
import { useAuth } from "../context/AuthContext";

type Mode = "login" | "register" | "forgot" | "reset" | "resend";

const content = {
  login: {
    step: "01 / Welcome to Savory",
    kicker: "YOUR KITCHEN AWAITS",
    title: "Welcome back.",
    copy: "Log in to find your next delicious idea.",
  },
  register: {
    step: "02 / Create your account",
    kicker: "A FRESH START",
    title: "Join the kitchen.",
    copy: "",
  },
  forgot: {
    step: "07 / Recover your account",
    kicker: "BACK TO GOOD THINGS",
    title: "Forgot your password?",
    copy: "It happens. Enter the email you use for Savory and we'll send you a link to reset it.",
  },
  resend: {
    step: "03 / Verify your email",
    kicker: "ALMOST THERE",
    title: "Need a new link?",
    copy: "Enter the email you signed up with and we'll send a fresh verification link.",
  },
  reset: {
    step: "09 / Choose a new password",
    kicker: "A NEW BEGINNING",
    title: "Make it a fresh one.",
    copy: "Choose a new password for your Savory account. Make it unique and keep it just for you.",
  },
};

export default function AuthPage({ mode }: { mode: Mode }) {
  const details = content[mode];
  return (
    <AuthShell step={details.step}>
      <div className={`auth-card ${mode === "register" ? "register-card" : ""}`}>
        <div className="auth-intro">
          <p className="eyebrow">{details.kicker}</p>
          <h2>{details.title}</h2>
          {details.copy && <p>{details.copy}</p>}
        </div>
        {mode === "login" && <LoginForm />}
        {mode === "register" && <RegisterForm />}
        {mode === "forgot" && <ForgotForm />}
        {mode === "reset" && <ResetForm />}
        {mode === "resend" && <ResendForm />}
      </div>
    </AuthShell>
  );
}

function LoginForm() {
  const navigate = useNavigate();
  const auth = useAuth();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [unverified, setUnverified] = useState(false);
  const [loading, setLoading] = useState(false);

  async function submit(event: FormEvent) {
    event.preventDefault();
    setError("");
    setUnverified(false);
    setLoading(true);
    try {
      const response = await authApi.login({ email, password });
      auth.login(response.token, response.user);
      navigate("/home");
    } catch (caught) {
      // 403 means the password was right but the email isn't verified yet
      const notVerified = caught instanceof ApiError && caught.status === 403;
      setUnverified(notVerified);
      setError(
        notVerified
          ? "Please verify your email before logging in."
          : errorMessage(caught, "Unable to log in."),
      );
    } finally {
      setLoading(false);
    }
  }

  return (
    <>
      <form className="auth-form" onSubmit={submit}>
        <FormField
          label="Email"
          name="email"
          type="email"
          placeholder="you@email.com"
          value={email}
          onChange={setEmail}
          autoComplete="email"
        />
        <FormField
          label="Password"
          name="password"
          type="password"
          placeholder="Enter your password"
          value={password}
          onChange={setPassword}
          autoComplete="current-password"
        />
        <Link className="forgot-link" to="/forgot-password">
          Forgot password?
        </Link>
        {error && <StatusMessage error>{error}</StatusMessage>}
        {unverified && <ResendButton email={email} />}
        <button className="primary-button" disabled={loading}>
          {loading ? "Logging in…" : "Log In"}
        </button>
      </form>
      <p className="auth-switch">
        Don&apos;t have an account? <Link to="/register">Sign up</Link>
      </p>
    </>
  );
}

function RegisterForm() {
  const [fields, setFields] = useState({
    firstName: "",
    lastName: "",
    email: "",
    password: "",
    confirm: "",
  });
  const [submitted, setSubmitted] = useState(false);
  const [status, setStatus] = useState("");
  const [error, setError] = useState("");
  const [done, setDone] = useState(false);
  const [loading, setLoading] = useState(false);
  const errors = useMemo(
    () => ({
      firstName: fields.firstName.trim() ? "" : "Enter your first name.",
      lastName: fields.lastName.trim() ? "" : "Enter your last name.",
      email: /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(fields.email)
        ? ""
        : "Enter a valid email, e.g. kai@email.com.",
      password: /^(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$/.test(fields.password)
        ? ""
        : "Use at least 8 characters, a number and a symbol.",
      confirm: fields.password === fields.confirm && fields.confirm ? "" : "Passwords don't match.",
    }),
    [fields],
  );
  const set = (key: keyof typeof fields) => (value: string) =>
    setFields((current) => ({ ...current, [key]: value }));

  async function submit(event: FormEvent) {
    event.preventDefault();
    setSubmitted(true);
    setStatus("");
    setError("");
    if (Object.values(errors).some(Boolean)) return;
    setLoading(true);
    try {
      const { confirm: _confirm, ...body } = fields;
      await authApi.register(body);
      setDone(true);
      setStatus(`We sent a verification link to ${fields.email}. Open it to activate your account.`);
    } catch (caught) {
      setError(errorMessage(caught, "Unable to register."));
    } finally {
      setLoading(false);
    }
  }

  const strength = Math.min(
    4,
    [
      fields.password.length >= 8,
      /[A-Z]/.test(fields.password),
      /\d/.test(fields.password),
      /[^A-Za-z0-9]/.test(fields.password),
    ].filter(Boolean).length,
  );

  return (
    <>
      <form className="auth-form compact" onSubmit={submit}>
        <div className="name-row">
          <FormField
            label="First name"
            name="firstName"
            placeholder="First name"
            value={fields.firstName}
            onChange={set("firstName")}
            error={submitted ? errors.firstName : ""}
          />
          <FormField
            label="Last name"
            name="lastName"
            placeholder="Last name"
            value={fields.lastName}
            onChange={set("lastName")}
            error={submitted ? errors.lastName : ""}
          />
        </div>
        <FormField
          label="Email"
          name="email"
          type="email"
          placeholder="you@email.com"
          value={fields.email}
          onChange={set("email")}
          error={submitted ? errors.email : ""}
        />
        <FormField
          label="Password"
          name="password"
          type="password"
          placeholder="Create a password"
          value={fields.password}
          onChange={set("password")}
          error={submitted ? errors.password : ""}
        />
        {fields.password && (
          <div className="strength">
            <div>
              {[1, 2, 3, 4].map((part) => (
                <i
                  key={part}
                  className={part <= strength ? (strength < 3 ? "weak" : "strong") : ""}
                />
              ))}
            </div>
            <span>{strength < 3 ? "Weak password" : "Strong password"}</span>
          </div>
        )}
        <FormField
          label="Confirm Password"
          name="confirm"
          type="password"
          placeholder="Repeat your password"
          value={fields.confirm}
          onChange={set("confirm")}
          error={submitted ? errors.confirm : ""}
        />
        {error && <StatusMessage error>{error}</StatusMessage>}
        {status && <StatusMessage>{status}</StatusMessage>}
        {done ? (
          <ResendButton email={fields.email} />
        ) : (
          <button className="primary-button" disabled={loading}>
            {loading ? "Creating…" : "Create Account"}
          </button>
        )}
      </form>
      <p className="legal-copy">
        By creating an account, you agree to our <a href="#terms">Terms of use</a> and{" "}
        <a href="#privacy">Privacy policy</a>.
      </p>
      <p className="auth-switch">
        Already have an account? <Link to="/">Log in</Link>
      </p>
    </>
  );
}

function ForgotForm() {
  const [email, setEmail] = useState("");
  const [status, setStatus] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  async function submit(event: FormEvent) {
    event.preventDefault();
    setStatus("");
    setError("");
    setLoading(true);
    try {
      const response = await authApi.forgotPassword(email);
      setStatus(response.message);
    } catch (caught) {
      setError(errorMessage(caught, "Unable to send the link."));
    } finally {
      setLoading(false);
    }
  }
  return (
    <>
      <form className="auth-form" onSubmit={submit}>
        <FormField
          label="Email"
          name="email"
          type="email"
          placeholder="you@email.com"
          value={email}
          onChange={setEmail}
          autoComplete="email"
        />
        {error && <StatusMessage error>{error}</StatusMessage>}
        {status && <StatusMessage>{status}</StatusMessage>}
        <button className="primary-button" disabled={loading}>
          {loading ? "Sending…" : "Send Reset Link"}
        </button>
      </form>
      <Link className="back-link" to="/">
        ← &nbsp;Back to login
      </Link>
    </>
  );
}

function ResetForm() {
  const [params] = useSearchParams();
  const token = params.get("token") || "";
  const [password, setPassword] = useState("");
  const [confirm, setConfirm] = useState("");
  const [status, setStatus] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const valid = /^(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$/.test(password);
  async function submit(event: FormEvent) {
    event.preventDefault();
    setError("");
    if (!token) return setError("This reset link is invalid or expired.");
    if (!valid) return setError("Use at least 8 characters, a number and a symbol.");
    if (password !== confirm) return setError("Passwords don't match.");
    setLoading(true);
    try {
      const response = await authApi.resetPassword(token, password);
      setStatus(response.message || "Password reset. You can now log in.");
    } catch (caught) {
      setError(errorMessage(caught, "Unable to reset password."));
    } finally {
      setLoading(false);
    }
  }
  if (status) {
    return (
      <>
        <StatusMessage>{status}</StatusMessage>
        <Link className="primary-button" to="/">
          Go to login
        </Link>
      </>
    );
  }
  return (
    <>
      <form className="auth-form" onSubmit={submit}>
        <FormField
          label="New Password"
          name="password"
          type="password"
          placeholder="New password"
          value={password}
          onChange={setPassword}
        />
        {password && (
          <div className="strength">
            <div>
              {[1, 2, 3, 4].map((part) => (
                <i key={part} className={valid ? "strong" : part === 1 ? "weak" : ""} />
              ))}
            </div>
            <span>{valid ? "Strong password" : "Keep going"}</span>
          </div>
        )}
        <FormField
          label="Confirm Password"
          name="confirm"
          type="password"
          placeholder="Confirm password"
          value={confirm}
          onChange={setConfirm}
        />
        {confirm && password === confirm && (
          <small className="match-copy">Your passwords match.</small>
        )}
        {error && <StatusMessage error>{error}</StatusMessage>}
        {status && <StatusMessage>{status}</StatusMessage>}
        <button className="primary-button" disabled={loading}>
          {loading ? "Saving…" : "Reset Password"}
        </button>
      </form>
      <Link className="back-link" to="/">
        ← &nbsp;Back to login
      </Link>
    </>
  );
}

// Sends POST /auth/resend-verification for the given email
function ResendButton({ email }: { email: string }) {
  const [state, setState] = useState<"idle" | "sending" | "sent">("idle");
  const [error, setError] = useState("");
  async function resend() {
    setError("");
    setState("sending");
    try {
      await authApi.resendVerification(email);
      setState("sent");
    } catch (caught) {
      setError(errorMessage(caught, "Unable to resend the link."));
      setState("idle");
    }
  }
  return (
    <>
      {error && <StatusMessage error>{error}</StatusMessage>}
      {state === "sent" && <StatusMessage>A new verification link is on its way.</StatusMessage>}
      <button
        type="button"
        className="secondary-button"
        onClick={resend}
        disabled={state === "sending" || !email}
      >
        {state === "sending" ? "Sending…" : "Resend verification email"}
      </button>
    </>
  );
}

function ResendForm() {
  const [email, setEmail] = useState("");
  const [status, setStatus] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  async function submit(event: FormEvent) {
    event.preventDefault();
    setStatus("");
    setError("");
    setLoading(true);
    try {
      const response = await authApi.resendVerification(email);
      setStatus(response.message);
    } catch (caught) {
      setError(errorMessage(caught, "Unable to resend the link."));
    } finally {
      setLoading(false);
    }
  }
  return (
    <>
      <form className="auth-form" onSubmit={submit}>
        <FormField
          label="Email"
          name="email"
          type="email"
          placeholder="you@email.com"
          value={email}
          onChange={setEmail}
          autoComplete="email"
        />
        {error && <StatusMessage error>{error}</StatusMessage>}
        {status && <StatusMessage>{status}</StatusMessage>}
        <button className="primary-button" disabled={loading}>
          {loading ? "Sending…" : "Send Verification Link"}
        </button>
      </form>
      <Link className="back-link" to="/">
        ← &nbsp;Back to login
      </Link>
    </>
  );
}
