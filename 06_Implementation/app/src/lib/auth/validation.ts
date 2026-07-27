export interface ValidationResult {
  isValid: boolean;
  errors: string[];
}

/**
 * Validates an email address format.
 */
export function validateEmail(email: string): ValidationResult {
  const errors: string[] = [];
  const trimmed = email.trim();

  if (!trimmed) {
    errors.push("Email address is required.");
  } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(trimmed)) {
    errors.push("Invalid email address format.");
  }

  return {
    isValid: errors.length === 0,
    errors,
  };
}

/**
 * Validates password complexity according to OWASP guidelines:
 * - Minimum 12 characters
 * - Must contain uppercase letter
 * - Must contain lowercase letter
 * - Must contain a number
 * - Must contain a special character
 */
export function validatePassword(password: string): ValidationResult {
  const errors: string[] = [];

  if (!password) {
    errors.push("Password is required.");
    return { isValid: false, errors };
  }

  if (password.length < 12) {
    errors.push("Password must be at least 12 characters long.");
  }
  if (!/[A-Z]/.test(password)) {
    errors.push("Password must contain at least one uppercase letter.");
  }
  if (!/[a-z]/.test(password)) {
    errors.push("Password must contain at least one lowercase letter.");
  }
  if (!/[0-9]/.test(password)) {
    errors.push("Password must contain at least one number.");
  }
  if (!/[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]/.test(password)) {
    errors.push("Password must contain at least one special character.");
  }

  return {
    isValid: errors.length === 0,
    errors,
  };
}
