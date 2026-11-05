import { useState } from "react";

export function FormField({
  label,
  name,
  type = "text",
  placeholder,
  value,
  onChange,
  error,
  autoComplete,
}: {
  label: string;
  name: string;
  type?: string;
  placeholder?: string;
  value: string;
  onChange: (value: string) => void;
  error?: string;
  autoComplete?: string;
}) {
  const [visible, setVisible] = useState(false);
  const password = type === "password";
  return (
    <label className={`form-field ${error ? "has-error" : ""}`}>
      <span>{label}</span>
      <div className="input-wrap">
        <input
          name={name}
          type={password && visible ? "text" : type}
          placeholder={placeholder}
          value={value}
          onChange={(event) => onChange(event.target.value)}
          autoComplete={autoComplete}
          aria-invalid={Boolean(error)}
        />
        {password && (
          <button
            type="button"
            className="eye-button"
            onClick={() => setVisible((current) => !current)}
            aria-label={visible ? "Hide password" : "Show password"}
          >
            <img src={visible ? "/assets/1fc65.svg" : "/assets/ec3e1.svg"} alt="" />
          </button>
        )}
      </div>
      {error && <small>{error}</small>}
    </label>
  );
}

export function StatusMessage({
  children,
  error = false,
}: {
  children: React.ReactNode;
  error?: boolean;
}) {
  return (
    <p className={error ? "form-status error" : "form-status"} role="status">
      {children}
    </p>
  );
}
