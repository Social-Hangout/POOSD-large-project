# Review: `docs/api-contract.md`

- **Reviewed:** branch `feature/docs-api-contract`, commit `e1b3061` (2026-10-26)
- **Checked against:** the graded requirements (email verification, password reset by email, JWT auth), converting to SwaggerHub/OpenAPI, and use by both the React and Flutter apps

This is a strong draft. The shared shapes, the single error format and the search rule are clear enough to build against today. Most of what's below is filling gaps, not redoing work. The biggest items are the missing **resend verification** route (graded), **types on every field** (needed for OpenAPI), and **pagination on reviews and comments**.

Items marked **Question** are places where I couldn't tell what you intended, so I didn't guess.

---

## 1. Missing (vital)

### 1.1 Resend verification route (graded requirement)

There's no way to get a new verification email. Under **1. `POST /api/auth/register`**, the link is "valid 24 hours". If it expires or the email gets lost, the user is stuck. Logging in returns 403 "Please verify your email first", and registering again returns 409 "Email already registered".

Add:

```md
### `POST /api/auth/resend-verification`

Sends a new verification link (valid 24 hours) and invalidates the old one.

- **Auth:** none (rate-limited)
- **Request:**

| Field | Type | Required | Rules |
| --- | --- | --- | --- |
| `email` | string | yes | valid email format |

- **Response 200** (same reply whether or not the account exists or is already verified):
{ "message": "If that account needs verifying, a new link was sent" }

- **Errors:**
| 400 | { "error": "A valid email is required" } | missing or badly formatted email |
| 429 | { "error": "Too many requests. Try again later." } | rate limit hit |
```

Then update the places that list routes: the route summary ("19 routes"), the **Public routes** line in **Conventions**, and the **Contents**. It would also help clients to add a line under **3. login**: "On 403, offer a *Resend verification email* button that calls `POST /auth/resend-verification`."

### 1.2 Types and required flags for every request field (needed for OpenAPI)

OpenAPI needs a `type` and a `required` flag for every field. Right now some routes have a "Rules" table with no types, and some have no table at all:

| Route | What's missing |
| --- | --- |
| **2. `POST /auth/verify`** | no field table (`token`) |
| **3. `POST /auth/login`** | no field table (`email`, `password`) |
| **4. `POST /auth/forgot-password`** | no field table (`email`) |
| **5. `POST /auth/reset-password`** | no field table (`token`, `newPassword`); the length rule only shows up in the error table |
| **7. `PUT /users/me`** | no field table; whether both names are required is only implied by the error message |
| **11. `POST /recipes`** / **12. `PUT /recipes/:id`** | no field table; the limits are in **Limits and validation**, away from the route, and have no types |
| **8.** and **9.** query params | no type column (for example, is `mine` a boolean? what happens with `mine=yes`?) |
| every `:id` route | the path parameter isn't described |

Suggested format, used the same way on every route (for example, **11. `POST /recipes`**):

```md
| Field | Type | Required | Rules |
| --- | --- | --- | --- |
| `title` | string | yes | trimmed, 1 to 100 characters |
| `ingredients` | array of `{ name, amount }` | yes | 1 to 10 items |
| `ingredients[].name` | string | yes | trimmed, stored lowercase |
| `ingredients[].amount` | string | no | up to 50 characters |
| `steps` | array of string | yes | 1 to 8 items, each up to 500 characters |
```

And once, under **Conventions**:

```md
| Path param | Type | Rules |
| `id` | string | 24-character hex MongoDB ObjectId; anything else returns 404 |
```

**Question:** is `ingredients[].amount` required? The shared shape always includes it, but no rule says so.

### 1.3 What happens when a token expires

**Conventions** says the token "expires in 24 hours", but no section tells the web and Flutter apps what to do when that happens. The login note ("a 401 from login is a wrong password, not an expired session") covers the opposite case. Add under **Conventions → Errors**:

```md
**Expired or invalid token:** any protected route returns 401 { "error": "Invalid or missing token" }.
There is no refresh token. On a 401 from any route except login, clients delete the saved token
and send the user to the login screen. After 24 hours, users log in again.
```

### 1.4 Pagination on reviews and comments

**14. `GET /recipes/:id/reviews`** and **17. `GET /recipes/:id/comments`** return every item at once. A recipe with a lot of activity sends one huge response, and the two list routes behave differently from **8.** and **9.** Use the same query params and response shape as **8.**:

```md
GET /api/recipes/:id/comments?page=1&limit=20

{ "comments": [ ... ], "page": 1, "totalPages": 3 }
```

If you'd rather keep them unpaginated, say so explicitly in the doc and give a reason, so it's clearly a choice and not an oversight.

### 1.5 Error responses that are missing or have no body

- **Conventions → Errors** lists 400 to 500 but not **429**, even though **3. login** returns it. Add a row for 429.
- **8. `GET /recipes`** only lists 401. Add 400 for a bad `page` or `limit` (for example `limit=500` or `page=0`). **Question:** should an out-of-range value return 400 or be clamped (`limit=500` treated as 50)? Either works; the doc just needs to say which.
- **9. `GET /recipes/search`** doesn't say what a bad `page` does.
- **14.** and **17.** write errors as "401 (no or bad token)" with no body, while every other route shows the body. Use the full table format so the OpenAPI conversion is mechanical.
- **Question:** what should a `page` past the last page return: an empty list or 404? (An empty list is the usual choice.)

### 1.6 Password reset on mobile

**2. verify** explains the mobile path ("Phone users open the link in their phone's browser"), but **5. reset-password** only says "Called by the web page." The flow does work on phones, since the link opens the React page in the phone's browser, so this is one sentence to keep it from looking web-only:

```md
Phone users open the link in their phone's browser, reset the password there, then log in to the app.
```

### 1.7 Question: how does "generate recipes from my ingredients" work?

The app's main feature is "type in the ingredients you have at home and it generates potential recipes." The closest route is **9. `GET /recipes/search`**, which only searches recipes **already in our database**. I can't tell which of these you intended:

- **(a)** Search is the feature. Then say so at the top of **Recipes and search**, and plan where the starting recipes come from (seed script? users only?). An empty database means empty results.
- **(b)** Recipes come from an outside recipe API or an AI model. Then it needs its own route and documented failure cases (for example, 502 or 503 when the outside service is down).

This decision affects grading, so it's worth settling with the whole team.

---

## 2. Inconsistencies or errors

### 2.1 One error message used for several different problems

Clients show `error` to the user, so a single message that covers several causes ends up showing wrong text:

- **1. register:** a short password returns "A valid email is required".
- **11. `POST /recipes`:** an empty ingredient name, no ingredients, or no steps all return "Title is required".
- **15. `POST /reviews`:** text that's too long returns "Rating must be a whole number from 1 to 5".

Give each cause its own row and message. For example, for **1. register**:

```md
| 400 | { "error": "First and last name are required" } | missing or empty name |
| 400 | { "error": "A valid email is required" } | missing or badly formatted email |
| 400 | { "error": "Password must be at least 8 characters" } | short password |
```

### 2.2 Search pagination doesn't match list pagination

**8. `GET /recipes`** accepts `limit` (1 to 50). **9. `GET /recipes/search`** is fixed at "20 results per page" with no `limit`. Accept the same `page` and `limit` params on both, so each app can use one pagination helper.

### 2.3 Route list formatting

The **Public routes** line writes `GET /api/health` with the `/api` prefix but `POST /auth/register` and the rest without it. Pick one style. (This list also needs the new resend route from 1.1.)

### 2.4 Rate limits: only login has one, and it has no numbers

**3. login** says "rate-limited" without saying how much. The routes that **send email** (**1. register**, **4. forgot-password** and the new resend route) aren't rate-limited at all. Free email tiers are small, so one script hammering `forgot-password` could use up the daily quota, and then real verification emails stop going out. Suggest documenting concrete limits, for example:

```md
| Route | Limit |
| login | 5 attempts per 15 minutes per email + IP |
| register, forgot-password, resend-verification | 3 per hour per email, 20 per hour per IP |
```

### 2.5 Register reveals which emails have accounts; forgot-password deliberately hides it

**4. forgot-password** gives "the same reply whether or not the email has an account, so strangers cannot find out who is registered". But **1. register** returns 409 "Email already registered", which tells anyone exactly that. Keeping the 409 is reasonable (it's simpler and the UX is clearer). Just add a sentence saying it's a known tradeoff, so the two routes don't look like they contradict each other.

### 2.6 "Should be singular" isn't enforced

**Shared shapes → `recipe`** says ingredient names "should be singular ('tomato')", but **Limits and validation** only enforces lowercase and trimming. Either say it's advice for whoever enters recipes, or add it to the validation rules. It doesn't break search, since the search does "contains" matching and strips plurals from the search terms.

### 2.7 Question: forgot-password for an unverified account

What should happen when an unverified user requests a password reset: send the reset email, send a verification email instead, or do nothing? The doc doesn't say. Sending the reset and marking the email verified when the reset succeeds is a common choice, since clicking the reset link proves they own the inbox.

---

## 3. Suggestions (optional)

- **Rating summary on recipes.** Add `averageRating` and `reviewCount` to the `recipe` shape. Without them, a recipe list has to call **14.** once per recipe just to show stars.
  ```json
  "averageRating": 4.3, "reviewCount": 12
  ```
- **Edit a review.** Because of the one-review-per-recipe rule (409), the only way to fix a typo or change a rating is to delete and re-post. A `PUT /api/reviews/:id` (author only, same body and limits as create) would fix that. `PUT /api/comments/:id` is less important.
- **"What's missing" in search results.** For the "what can I make?" feature, users care more about how many of the recipe's ingredients they *don't* have. Something like `"missingIngredients": ["soy sauce", "egg"]` next to `matchedTerms` would let the apps show "You're missing 2 ingredients."
- **Link base URL from an environment variable.** The emails link to `https://<your-domain>/verify?...`. Note that the server builds this from an env variable such as `APP_URL`, so local testing sends `http://localhost:5173/verify?...` and production sends the real domain.
- **Store verify and reset tokens hashed** (for example SHA-256) in the database, the same way passwords are, so a database leak doesn't hand out working reset links.
- **Old sessions after a password reset.** Right now, JWTs issued before a reset stay valid for up to 24 hours. If that matters, store a `passwordChangedAt` on the user and reject tokens issued before it.
- **OpenAPI conversion notes.** `:id` becomes `{id}`, the shared shapes go under `components/schemas`, and `Authorization: Bearer` becomes a `bearerAuth` security scheme. The doc is already organized so these map one-to-one.
- **Question:** does every recipe route need a login on purpose? Right now guests can't browse anything. That's fine if intended; it's worth one sentence in **Conventions** either way.
- **Question:** are recipe images planned? If yes, the `recipe` shape needs an `imageUrl` field, and someone has to decide how uploads work.

---

## 4. What's already good (keep these)

- One error shape (`{ "error": "..." }`) and a status code table.
- Shared shapes defined once and reused, which map directly to OpenAPI components.
- `id` instead of `_id`, camelCase fields, ISO 8601 dates, and invalid ObjectIds returning 404 instead of 500.
- An explicit "never returned" list (`passwordHash`, `verifyToken`, `resetToken`, and their expiry dates).
- Ownership: the user always comes from the token, never the body, and every edit or delete checks the author and returns 403.
- Verify and reset are `POST` routes with the token in the body, not `GET` links. That stops email link scanners from using up tokens, and the routes work the same from Flutter.
- `forgot-password` doesn't reveal whether an account exists, and the reset link is single-use and lasts 1 hour.
- Auth is a Bearer header only, with no cookies, so nothing is web-only.
- The search rule is precise: regex escaping, a 10-term cap, ranking, and an edge-case table.
- The implementer notes (route order for `/search`, mapping error 11000 to 409, cascade deletes) will save real debugging time.
- The client note about login 401 versus session expiry.
