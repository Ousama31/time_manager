# Cybersecurity Architecture & Safeguards Guide

This document details the cybersecurity posture, threat model, vulnerabilities analysis, and defensive implementations for the **Time Manager** application (Phoenix API backend + Vue 3 / Capacitor mobile frontend).

---

## 1. Threat Model & Risk Profile

Time Manager processes corporate attendance, working times, employee identities, and manager assignments. The primary attack surfaces and risk profiles include:

1. **Unauthorized Clock Manipulation**: Fraudulent clock-in/out or backdating work intervals.
2. **Horizontal Privilege Escalation (IDOR)**: An employee viewing or modifying another employee's records or salary/hours data.
3. **Vertical Privilege Escalation**: An employee or manager escalating their privileges to Administrator.
4. **Credential Harvesting & Brute Force**: Attacking authentication endpoints to compromise accounts.
5. **Session Hijacking & Replay Attacks**: Tampering with tokens or intercepted offline requests.
6. **Data Leakage on Mobile Devices**: Storing sensitive records in unprotected client storage or logs.

---

## 2. OWASP API Security Top 10 Mitigations

### API 1: Broken Object Level Authorization (BOLA / IDOR)
- **Risk**: An attacker changes `userID` in the URL (e.g. `GET /api/workingtime/99`) to spy on or tamper with other users' time records.
- **Mitigation in Time Manager**:
  - The application never trusts client-supplied user IDs without validation.
  - `TimeManager.Accounts.can_access_user_data?/2` verifies that:
    - Employees can **only** access their own ID.
    - Managers can **only** access users assigned directly to their `manager_id`.
    - Only Admins can access records across different users.
  - In `WorkingtimeController.create/2`, the `user_id` is derived from the verified URL scope rather than trusting JSON payload bodies.

### API 2: Broken Authentication
- **Risk**: Weak passwords, credential stuffing, predictable session tokens, lack of expiration.
- **Mitigation in Time Manager**:
  - **Bcrypt Work Factor 12**: Secure password hashing with unique salt per user.
  - **Constant-Time Verification**: Use of `Bcrypt.no_user_verify()` prevents user enumeration via response timing differences.
  - **Cryptographically Signed Tokens**: `Phoenix.Token` uses HMAC-SHA256 signature with high-entropy `SECRET_KEY_BASE`.
  - **Session Expiration**: Tokens expire after 3600 seconds (1 hour).
  - **Immediate Account Revocation**: Database status check (`status: :active`) on every request blocks suspended users instantly.

### API 3: Broken Object Property Level Authorization (Mass Assignment)
- **Risk**: An employee registers or updates their profile with `"role": "admin"` or `"manager_id": null`.
- **Mitigation in Time Manager**:
  - Separate changesets in `TimeManager.Accounts.User`:
    - `registration_changeset`: strictly permits only `[:username, :email, :full_name, :password]`. Default role is locked to `:employee` and status to `:active`.
    - `profile_changeset`: permits only non-privilege fields.
    - `role_changeset`: only invoked in admin controller actions after checking `current_user.role == :admin`.
    - `manager_changeset`: enforces foreign key integrity and ensures only accounts with `role: :manager` can be assigned as managers.

### API 4: Unrestricted Resource Consumption (DoS Prevention)
- **Risk**: Attackers sending unbounded database queries or uploading massive payload bodies.
- **Mitigation in Time Manager**:
  - **Phoenix Endpoint Parsers**: Limits JSON body size (default 8MB).
  - **Query Filters**: Working time queries accept bounded date-time range filters (`start` and `end`).
  - **Database Connection Pooling**: Ecto manages connection pools (default 10) to prevent PostgreSQL resource exhaustion.

### API 5: Broken Function Level Authorization (BFLA)
- **Risk**: Regular users calling administrative endpoints like `DELETE /api/users/:id` or changing other users' roles.
- **Mitigation in Time Manager**:
  - Every controller checks caller role prior to invoking sensitive context functions:
    ```elixir
    # In UserController:
    if conn.assigns.current_user.role != :admin do
      conn |> put_status(:forbidden) |> json(%{error: "Forbidden"}) |> halt()
    end
    ```

### API 6: Unrestricted Access to Sensitive Business Flows
- **Risk**: Clocking in multiple times concurrently or fabricating overlapping working intervals.
- **Mitigation in Time Manager**:
  - The clock state machine enforces valid transitions:
    - `off` -> `working` (clock in)
    - `working` -> `break` (pause for break)
    - `break` -> `working` (resume work)
    - `working` or `break` -> `off` (clock out)
  - Changesets validate interval logic: `start` must strictly precede `end`.

### API 7: Server-Side Request Forgery (SSRF)
- **Risk**: Application server relaying arbitrary network requests or emails.
- **Mitigation in Time Manager**:
  - Employee feedback and manager messages **do not** use a server-side open mail relay or webhooks.
  - Communication is generated on the client device using the standard, safe `mailto:` URI scheme (`createEmailDraftUrl` utility). The native email application handles network transport, ensuring zero server-side SSRF exposure.

### API 8: Security Misconfiguration
- **Risk**: Debug dashboards exposed in production, permissive CORS, cleartext headers.
- **Mitigation in Time Manager**:
  - **Phoenix LiveDashboard**: Gated behind `Application.compile_env(:time_manager, :dev_routes)` and never exposed in production releases without authentication.
  - **CORS Restricted**: Handled by `cors_plug` with explicit allowed headers (`x-xsrf-token`, `content-type`, `authorization`).
  - **Security Headers**: Standard production configurations include:
    - `X-Frame-Options: DENY` (Clickjacking defense)
    - `X-Content-Type-Options: nosniff` (MIME-sniffing defense)
    - `Referrer-Policy: strict-origin-when-cross-origin`

### API 9: Improper Inventory Management
- **Risk**: Unused or deprecated API versions running silently.
- **Mitigation in Time Manager**:
  - Strict routing under `/api` in `TimeManagerWeb.Router`.
  - Machine-readable OpenAPI 3.0 specification (`openapi.yaml`) synchronized with active endpoints.
  - Exhaustive markdown documentation (`API_DOCUMENTATION.md`).

### API 10: Unsafe Consumption of APIs
- **Risk**: Blindly trusting third-party or queued client data.
- **Mitigation in Time Manager**:
  - All input parameters are strictly parsed through Ecto Changesets.
  - Type casting, string truncation, and format regexes protect backend state from poisoning.

---

## 3. SQL Injection Defense

Time Manager uses **Ecto** with PostgreSQL.

- **Parameterized Queries**: All queries generated with Ecto (e.g. `where(User, [u], u.username == ^identifier)`) use parameterized prepared statements.
- **Zero Raw SQL Concatenation**: No user input is ever concatenated into raw SQL strings (`Ecto.Adapters.SQL.query` with raw strings is prohibited).
- **Type Coercion**: Parameters are validated and cast into Elixir native types (`integer`, `datetime`, `boolean`) before reaching the query planner.

---

## 4. Mobile & Offline Security (MASVS Standard)

### Offline Sync Security
The mobile app features offline support via `src/offlineSync.js`. This presents unique security considerations:

1. **FIFO Queue Ordering**: Offline requests are stored in a strict First-In-First-Out queue and replayed sequentially.
2. **Server-Authoritative Validation**:
   - The client optimistically displays cached state to provide a seamless mobile UX.
   - However, when the client reconnects, the server executes each queued request with full permission and changeset checks. If a request is invalid (e.g. user was suspended while offline), the server rejects it with `401 Unauthorized` or `422 Unprocessable Entity`.
3. **Queue Replay Safety**:
   - Replay fails gracefully: on the first unexpected error, the replay loop stops and notifies the user with haptic and visual cues.
   - Cached dashboard data is immediately refreshed from the server once online.

### Client Storage Security
- Authentication tokens and user metadata are isolated within client application storage (`sessionStorage` / `localStorage`).
- In iOS Capacitor wrapper, WebKit sandbox isolates local storage from other mobile applications.
- Passwords are never cached in storage under any circumstances.

---

## 5. Security Checklist for Production Deployment

Before deploying Time Manager to production:

- [x] Set strong, high-entropy `SECRET_KEY_BASE` (minimum 64 characters) via `openssl rand -base64 48`.
- [x] Set unique `PGPASSWORD` for the PostgreSQL service.
- [x] Ensure `PHX_HOST` matches the production domain name.
- [x] Enforce TLS / HTTPS in the Nginx reverse proxy configuration.
- [x] Disable `dev_routes` in Phoenix production releases (`config/prod.exs`).
- [x] Verify CORS settings in `endpoint.ex` match the production frontend origin.
- [x] Run regular dependency vulnerability audits with `mix deps.audit` and `npm audit`.
