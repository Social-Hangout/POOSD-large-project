# Recipe App API Contract

This file is the source of truth for every API route. The web app (React) and the mobile app (Flutter) build against exactly what is written here.

**Changing this file:** announce the change in the group chat first, then update this file in the same PR as the code change.

- Owner: API2 (drafted), API1 (reviewed)
- Status: draft, revised after review. See [Open questions](#open-questions) for what the team still has to decide.

## Contents

1. [Conventions](#conventions)
2. [Shared shapes](#shared-shapes)
3. [Route summary](#route-summary)
4. [Health](#health)
5. [Accounts](#accounts)
6. [Profile](#profile)
7. [Recipes and search](#recipes-and-search)
8. [Reviews](#reviews)
9. [Comments](#comments)
10. [Search rule](#search-rule)
11. [Limits and validation](#limits-and-validation)
12. [Notes for implementers](#notes-for-implementers)
13. [OpenAPI conversion notes](#openapi-conversion-notes)
14. [Open questions](#open-questions)

## Conventions

| Rule | Value |
| --- | --- |
| Base path | `/api` (production: `https://<your-domain>/api`, local: `http://localhost:5000/api`) |
| Body format | JSON, with `Content-Type: application/json` |
| Field names | camelCase (`firstName`, `matchedTerms`) |
| Ids | strings (`"id": "6721f0c2a1b2c3d4e5f60718"`); the API returns `id`, never `_id` |
| Dates | ISO 8601 strings (`"2026-10-26T15:04:14.195Z"`) |
| Auth header | `Authorization: Bearer <token>` on every protected route |
| Token | JWT holding `{ userId }`, signed with `JWT_SECRET`, expires in 24 hours. There is no refresh token. |

**Public routes (no token):** `GET /api/health`, `POST /api/auth/register`, `POST /api/auth/verify`, `POST /api/auth/resend-verification`, `POST /api/auth/login`, `POST /api/auth/forgot-password`, `POST /api/auth/reset-password`. Every other route needs a token, including all recipe routes, so guests can't browse (see [Open questions](#open-questions)).

### Path parameter

Every route with `:id` in the path uses it the same way:

| Path param | Type | Rules |
| --- | --- | --- |
| `id` | string | 24-character hex MongoDB ObjectId; anything else returns 404, not 500 |

### Pagination

Every list route (**9**, **10**, **15**, **18**) takes the same query parameters and returns the same envelope.

| Query param | Type | Required | Default | Rules |
| --- | --- | --- | --- | --- |
| `page` | integer | no | 1 | whole number, 1 or more |
| `limit` | integer | no | 20 | whole number, 1 to 50 |

```json
{ "<items>": [ ... ], "page": 1, "totalPages": 3 }
```

- `<items>` is `recipes`, `results`, `reviews` or `comments`, depending on the route.
- An empty list returns `{ "<items>": [], "page": 1, "totalPages": 0 }`.
- A `page` past the last page returns 200 with an empty list, not 404.
- A bad value is rejected, not clamped (`limit=500` and `page=0` are errors):

| Status | Body | When |
| --- | --- | --- |
| 400 | `{ "error": "page must be a whole number, 1 or more" }` | `page` is not a whole number, or is less than 1 |
| 400 | `{ "error": "limit must be a whole number from 1 to 50" }` | `limit` is not a whole number, or is outside 1 to 50 |

### Rate limits

Routes that check passwords or send email are rate-limited. Free email plans have a small daily quota, so without limits one script could use it up and stop real verification emails.

| Route | Limit | 429 body |
| --- | --- | --- |
| `POST /api/auth/login` | 5 attempts per 15 minutes per email + IP | `{ "error": "Too many login attempts. Try again later." }` |
| `POST /api/auth/register`, `POST /api/auth/resend-verification`, `POST /api/auth/forgot-password` | 3 per hour per email, 20 per hour per IP | `{ "error": "Too many requests. Try again later." }` |

### Errors

Every error has the same body:

```json
{ "error": "Human-readable message" }
```

| Status | Meaning |
| --- | --- |
| 400 | Bad input (missing field, wrong format, over a limit, bad query parameter, bad or expired email token) |
| 401 | No token, invalid or expired token, or wrong login credentials |
| 403 | Logged in but not allowed (not the author), or email not verified (login only) |
| 404 | The thing does not exist |
| 409 | Duplicate (email already registered, recipe already reviewed) |
| 429 | Too many requests (see [Rate limits](#rate-limits)) |
| 500 | Server bug; clients show a generic "Something went wrong" |

Success statuses: **200** OK, **201** created, **204** deleted (no body).

Each 400 message names one problem, because clients show `error` to the user as is.

**Expired or invalid token:** any protected route returns 401 `{ "error": "Invalid or missing token" }`. On a 401 from any route except login, clients delete the saved token and send the user to the login screen. After 24 hours, users log in again.

## Shared shapes

These shapes are returned the same way by every route that uses them.

### `user`

Email cannot be changed after registering. The password hash is never returned by any route.

```json
{
  "id": "6721f0c2a1b2c3d4e5f60718",
  "firstName": "Ana",
  "lastName": "Diaz",
  "email": "ana@test.com"
}
```

### `author`

A short version of a user, attached to recipes, reviews, and comments.

```json
{ "id": "6721f0c2a1b2c3d4e5f60718", "firstName": "Ana" }
```

### `recipe`

```json
{
  "id": "6721f3aa9b8c7d6e5f403122",
  "title": "Garlic Butter Pasta",
  "ingredients": [
    { "name": "pasta", "amount": "200 g" },
    { "name": "butter", "amount": "2 tbsp" },
    { "name": "garlic", "amount": "3 cloves" }
  ],
  "steps": ["Boil the pasta.", "Melt the butter and cook the garlic.", "Toss together and serve."],
  "author": { "id": "6721f0c2a1b2c3d4e5f60718", "firstName": "Ana" },
  "createdAt": "2026-10-26T15:04:14.195Z"
}
```

- `ingredients[].name` is stored lowercase and trimmed. Use the singular ("tomato") when entering recipes. This is advice, not validation: search still finds plurals, because it does contains matching and strips plural endings from search terms.
- `ingredients[].amount` is plain text ("2 cups", "a pinch"). There is no unit conversion. It is optional on create and edit, and is returned as `""` when not given, so the field is always present.

### `review`

```json
{
  "id": "6721f5d01a2b3c4d5e6f7081",
  "rating": 4,
  "text": "Easy and tasty.",
  "author": { "id": "6721f0c2a1b2c3d4e5f60718", "firstName": "Ana" },
  "createdAt": "2026-10-27T18:20:00.000Z"
}
```

### `comment`

```json
{
  "id": "6721f6e11b2c3d4e5f607182",
  "text": "I added chili flakes.",
  "author": { "id": "6721f0c2a1b2c3d4e5f60718", "firstName": "Ana" },
  "createdAt": "2026-10-27T18:25:00.000Z"
}
```

## Route summary

20 routes (plus the health check). All paths below start with `/api`.

| # | Method | Path | Auth | Owner | Success |
| --- | --- | --- | --- | --- | --- |
| - | GET | `/health` | none | API1 | 200 |
| 1 | POST | `/auth/register` | none | API1 | 201 |
| 2 | POST | `/auth/verify` | none | API1 | 200 |
| 3 | POST | `/auth/resend-verification` | none | API1 | 200 |
| 4 | POST | `/auth/login` | none | API1 | 200 |
| 5 | POST | `/auth/forgot-password` | none | API1 | 200 |
| 6 | POST | `/auth/reset-password` | none | API1 | 200 |
| 7 | GET | `/users/me` | token | API1 | 200 |
| 8 | PUT | `/users/me` | token | API1 | 200 |
| 9 | GET | `/recipes` | token | API2 | 200 |
| 10 | GET | `/recipes/search` | token | API2 | 200 |
| 11 | GET | `/recipes/:id` | token | API2 | 200 |
| 12 | POST | `/recipes` | token | API2 | 201 |
| 13 | PUT | `/recipes/:id` | token | API2 | 200 |
| 14 | DELETE | `/recipes/:id` | token | API2 | 204 |
| 15 | GET | `/recipes/:id/reviews` | token | API2 | 200 |
| 16 | POST | `/recipes/:id/reviews` | token | API2 | 201 |
| 17 | DELETE | `/reviews/:id` | token | API2 | 204 |
| 18 | GET | `/recipes/:id/comments` | token | API2 | 200 |
| 19 | POST | `/recipes/:id/comments` | token | API2 | 201 |
| 20 | DELETE | `/comments/:id` | token | API2 | 204 |

## Health

### `GET /api/health`

Proves the server is running. Already in `api/server.js`.

- **Auth:** none
- **Response 200:**

```json
{ "status": "ok" }
```

## Accounts

### 1. `POST /api/auth/register`

Creates an unverified account and emails a verification link to `<APP_URL>/verify?token=<token>` (valid 24 hours).

- **Auth:** none (rate-limited)
- **Request:**

```json
{ "firstName": "Ana", "lastName": "Diaz", "email": "ana@test.com", "password": "Passw0rd!" }
```

| Field | Type | Required | Rules |
| --- | --- | --- | --- |
| `firstName` | string | yes | trimmed, 1 to 50 characters |
| `lastName` | string | yes | trimmed, 1 to 50 characters |
| `email` | string | yes | valid email format, stored lowercase |
| `password` | string | yes | at least 8 characters |

- **Response 201:**

```json
{ "message": "Verification email sent" }
```

- **Errors:**

| Status | Body | When |
| --- | --- | --- |
| 400 | `{ "error": "First and last name must be 1 to 50 characters" }` | missing, empty or too long name |
| 400 | `{ "error": "A valid email is required" }` | missing or badly formatted email |
| 400 | `{ "error": "Password must be at least 8 characters" }` | missing or short password |
| 409 | `{ "error": "Email already registered" }` | email already has an account |
| 429 | `{ "error": "Too many requests. Try again later." }` | rate limit hit |

The 409 tells anyone whether an email has an account, while **5. forgot-password** deliberately hides that. This is a known tradeoff: the clearer sign-up message is worth it here.

### 2. `POST /api/auth/verify`

Called by the web page at `/verify?token=...`. Phone users open the link in their phone's browser, then log in to the app.

- **Auth:** none
- **Request:**

```json
{ "token": "9f2c4e...e81a" }
```

| Field | Type | Required | Rules |
| --- | --- | --- | --- |
| `token` | string | yes | the token from the email link |

- **Response 200:**

```json
{ "message": "Email verified. You can log in now." }
```

- **Errors:**

| Status | Body | When |
| --- | --- | --- |
| 400 | `{ "error": "Invalid or expired link" }` | token missing, wrong, already used, replaced by a newer one, or older than 24 hours |

### 3. `POST /api/auth/resend-verification`

Sends a new verification link (valid 24 hours) and invalidates the old one. Used when the first link expired or the email got lost.

- **Auth:** none (rate-limited)
- **Request:**

```json
{ "email": "ana@test.com" }
```

| Field | Type | Required | Rules |
| --- | --- | --- | --- |
| `email` | string | yes | valid email format |

- **Response 200** (the same reply whether or not the account exists or is already verified):

```json
{ "message": "If that account needs verifying, a new link was sent" }
```

- **Errors:**

| Status | Body | When |
| --- | --- | --- |
| 400 | `{ "error": "A valid email is required" }` | missing or badly formatted email |
| 429 | `{ "error": "Too many requests. Try again later." }` | rate limit hit |

### 4. `POST /api/auth/login`

- **Auth:** none (rate-limited)
- **Request:**

```json
{ "email": "ana@test.com", "password": "Passw0rd!" }
```

| Field | Type | Required | Rules |
| --- | --- | --- | --- |
| `email` | string | yes | compared lowercase |
| `password` | string | yes | |

- **Response 200:**

```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": { "id": "6721f0c2a1b2c3d4e5f60718", "firstName": "Ana", "lastName": "Diaz", "email": "ana@test.com" }
}
```

- **Errors:**

| Status | Body | When |
| --- | --- | --- |
| 400 | `{ "error": "Email and password are required" }` | a field is missing |
| 401 | `{ "error": "Invalid credentials" }` | wrong email **or** wrong password (same message for both) |
| 403 | `{ "error": "Please verify your email first" }` | right password, but the account is not verified |
| 429 | `{ "error": "Too many login attempts. Try again later." }` | rate limit hit |

Clients:
- A 401 from login is a wrong password, not an expired session. Show the message; do not log the user out.
- On 403, offer a *Resend verification email* button that calls **3. `POST /api/auth/resend-verification`**.

### 5. `POST /api/auth/forgot-password`

Emails a reset link to `<APP_URL>/reset-password?token=<token>` (valid 1 hour, single use). Unverified accounts get the reset email too; see **6.**

- **Auth:** none (rate-limited)
- **Request:**

```json
{ "email": "ana@test.com" }
```

| Field | Type | Required | Rules |
| --- | --- | --- | --- |
| `email` | string | yes | valid email format |

- **Response 200** (the same reply whether or not the email has an account, so strangers cannot find out who is registered):

```json
{ "message": "If that email has an account, a reset link was sent" }
```

- **Errors:**

| Status | Body | When |
| --- | --- | --- |
| 400 | `{ "error": "A valid email is required" }` | missing or badly formatted email |
| 429 | `{ "error": "Too many requests. Try again later." }` | rate limit hit |

### 6. `POST /api/auth/reset-password`

Called by the web page at `/reset-password?token=...`. Phone users open the link in their phone's browser, reset the password there, then log in to the app.

A successful reset also marks the email as verified, since opening the link proves the user owns the inbox.

- **Auth:** none
- **Request:**

```json
{ "token": "4b7d1a...c09f", "newPassword": "N3wPassw0rd!" }
```

| Field | Type | Required | Rules |
| --- | --- | --- | --- |
| `token` | string | yes | the token from the email link |
| `newPassword` | string | yes | at least 8 characters |

- **Response 200:**

```json
{ "message": "Password updated. You can log in now." }
```

- **Errors:**

| Status | Body | When |
| --- | --- | --- |
| 400 | `{ "error": "Invalid or expired link" }` | token missing, wrong, used, or older than 1 hour |
| 400 | `{ "error": "Password must be at least 8 characters" }` | new password missing or too short |

## Profile

### 7. `GET /api/users/me`

Returns the logged-in user. The app also calls this on launch to check a saved token.

- **Auth:** token
- **Response 200:** a `user`

```json
{ "id": "6721f0c2a1b2c3d4e5f60718", "firstName": "Ana", "lastName": "Diaz", "email": "ana@test.com" }
```

- **Errors:**

| Status | Body | When |
| --- | --- | --- |
| 401 | `{ "error": "Invalid or missing token" }` | no or bad token |

### 8. `PUT /api/users/me`

Updates the logged-in user's name. Email cannot be changed. The user id comes from the token, never the body.

- **Auth:** token
- **Request:**

```json
{ "firstName": "Ana", "lastName": "Diaz-Lopez" }
```

| Field | Type | Required | Rules |
| --- | --- | --- | --- |
| `firstName` | string | yes | trimmed, 1 to 50 characters |
| `lastName` | string | yes | trimmed, 1 to 50 characters |

- **Response 200:** the updated `user`

```json
{ "id": "6721f0c2a1b2c3d4e5f60718", "firstName": "Ana", "lastName": "Diaz-Lopez", "email": "ana@test.com" }
```

- **Errors:**

| Status | Body | When |
| --- | --- | --- |
| 400 | `{ "error": "First and last name must be 1 to 50 characters" }` | missing, empty or too long name |
| 401 | `{ "error": "Invalid or missing token" }` | no or bad token |

## Recipes and search

### 9. `GET /api/recipes?page=1&limit=20&mine=true`

Lists recipes, newest first.

- **Auth:** token
- **Query parameters:** `page` and `limit` (see [Pagination](#pagination)), plus:

| Name | Type | Required | Default | Rules |
| --- | --- | --- | --- | --- |
| `mine` | boolean | no | false | `true` or `false`; `true` returns only the caller's recipes |

- **Response 200:**

```json
{
  "recipes": [
    {
      "id": "6721f3aa9b8c7d6e5f403122",
      "title": "Garlic Butter Pasta",
      "ingredients": [{ "name": "pasta", "amount": "200 g" }, { "name": "butter", "amount": "2 tbsp" }],
      "steps": ["Boil the pasta.", "Toss with butter."],
      "author": { "id": "6721f0c2a1b2c3d4e5f60718", "firstName": "Ana" },
      "createdAt": "2026-10-26T15:04:14.195Z"
    }
  ],
  "page": 1,
  "totalPages": 2
}
```

An empty list returns `{ "recipes": [], "page": 1, "totalPages": 0 }`.

- **Errors:**

| Status | Body | When |
| --- | --- | --- |
| 400 | `{ "error": "page must be a whole number, 1 or more" }` | bad `page` |
| 400 | `{ "error": "limit must be a whole number from 1 to 50" }` | bad `limit` |
| 400 | `{ "error": "mine must be true or false" }` | `mine` is anything else, such as `yes` |
| 401 | `{ "error": "Invalid or missing token" }` | no or bad token |

### 10. `GET /api/recipes/search?q=chick,rice&page=1&limit=20`

Partial-match ingredient search, done on the server. Clients call it as the user types (250 ms debounce). See the [search rule](#search-rule) for exactly how it works.

- **Auth:** token
- **Query parameters:** `page` and `limit` (see [Pagination](#pagination)), plus:

| Name | Type | Required | Rules |
| --- | --- | --- | --- |
| `q` | string | yes | comma-separated terms, for example `chick,rice` (URL-encode it) |

- **Response 200:** each result is a `recipe` plus `matchedTerms` and `totalTerms`, best match first.

```json
{
  "results": [
    {
      "id": "6721f3aa9b8c7d6e5f403199",
      "title": "Chicken Fried Rice",
      "ingredients": [{ "name": "chicken", "amount": "1 cup" }, { "name": "rice", "amount": "2 cups" }],
      "steps": ["Cook the rice.", "Fry the chicken and rice together."],
      "author": { "id": "6721f0c2a1b2c3d4e5f60718", "firstName": "Ana" },
      "createdAt": "2026-10-26T15:04:14.195Z",
      "matchedTerms": 2,
      "totalTerms": 2
    },
    {
      "id": "6721f3aa9b8c7d6e5f4031a0",
      "title": "Lemon Chicken",
      "ingredients": [{ "name": "chicken", "amount": "2 breasts" }, { "name": "lemon", "amount": "1" }],
      "steps": ["Season the chicken.", "Bake with lemon."],
      "author": { "id": "6721f0c2a1b2c3d4e5f60718", "firstName": "Ana" },
      "createdAt": "2026-10-26T15:04:14.195Z",
      "matchedTerms": 1,
      "totalTerms": 2
    }
  ],
  "page": 1,
  "totalPages": 1
}
```

No matches returns 200 with `{ "results": [], "page": 1, "totalPages": 0 }`, not an error.

- **Errors:**

| Status | Body | When |
| --- | --- | --- |
| 400 | `{ "error": "Search text is required" }` | `q` is missing or has no terms after trimming |
| 400 | `{ "error": "page must be a whole number, 1 or more" }` | bad `page` |
| 400 | `{ "error": "limit must be a whole number from 1 to 50" }` | bad `limit` |
| 401 | `{ "error": "Invalid or missing token" }` | no or bad token |

Clients show "Matches 2 of 2" from `matchedTerms` and `totalTerms`, and never re-sort or filter the results.

### 11. `GET /api/recipes/:id`

- **Auth:** token
- **Response 200:** a `recipe`
- **Errors:**

| Status | Body | When |
| --- | --- | --- |
| 401 | `{ "error": "Invalid or missing token" }` | no or bad token |
| 404 | `{ "error": "Recipe not found" }` | no recipe with that id, or the id is not a valid id |

### 12. `POST /api/recipes`

Creates a recipe owned by the caller (author comes from the token).

- **Auth:** token
- **Request:**

```json
{
  "title": "Garlic Butter Pasta",
  "ingredients": [
    { "name": "pasta", "amount": "200 g" },
    { "name": "butter", "amount": "2 tbsp" },
    { "name": "garlic", "amount": "3 cloves" }
  ],
  "steps": ["Boil the pasta.", "Melt the butter and cook the garlic.", "Toss together and serve."]
}
```

| Field | Type | Required | Rules |
| --- | --- | --- | --- |
| `title` | string | yes | trimmed, 1 to 100 characters |
| `ingredients` | array of `{ name, amount }` | yes | 1 to 10 items |
| `ingredients[].name` | string | yes | trimmed, not empty, stored lowercase |
| `ingredients[].amount` | string | no | up to 50 characters; `""` if not given |
| `steps` | array of string | yes | 1 to 8 items, each trimmed, 1 to 500 characters |

- **Response 201:** the new `recipe`
- **Errors:**

| Status | Body | When |
| --- | --- | --- |
| 400 | `{ "error": "Title must be 1 to 100 characters" }` | missing, empty or too long title |
| 400 | `{ "error": "A recipe needs 1 to 10 ingredients" }` | no ingredients, over 10, or not an array |
| 400 | `{ "error": "Every ingredient needs a name" }` | an ingredient's name is missing or empty |
| 400 | `{ "error": "Ingredient amounts can be at most 50 characters" }` | an amount is too long |
| 400 | `{ "error": "A recipe needs 1 to 8 steps" }` | no steps, over 8, or not an array |
| 400 | `{ "error": "Each step must be 1 to 500 characters" }` | a step is empty or too long |
| 401 | `{ "error": "Invalid or missing token" }` | no or bad token |

### 13. `PUT /api/recipes/:id`

Replaces the title, ingredients, and steps. Only the author can edit.

- **Auth:** token
- **Request:** same body and field rules as **12. `POST /api/recipes`** (all three fields required)
- **Response 200:** the updated `recipe`
- **Errors:**

| Status | Body | When |
| --- | --- | --- |
| 400 | same messages as **12.** | bad input or over the limits |
| 401 | `{ "error": "Invalid or missing token" }` | no or bad token |
| 403 | `{ "error": "Not your recipe" }` | caller is not the author |
| 404 | `{ "error": "Recipe not found" }` | no recipe with that id |

### 14. `DELETE /api/recipes/:id`

Deletes the recipe **and** all of its reviews and comments. Only the author can delete.

- **Auth:** token
- **Response 204:** no body
- **Errors:**

| Status | Body | When |
| --- | --- | --- |
| 401 | `{ "error": "Invalid or missing token" }` | no or bad token |
| 403 | `{ "error": "Not your recipe" }` | caller is not the author |
| 404 | `{ "error": "Recipe not found" }` | no recipe with that id |

## Reviews

### 15. `GET /api/recipes/:id/reviews?page=1&limit=20`

Lists a recipe's reviews, newest first.

- **Auth:** token
- **Query parameters:** `page` and `limit` (see [Pagination](#pagination))
- **Response 200:**

```json
{
  "reviews": [
    {
      "id": "6721f5d01a2b3c4d5e6f7081",
      "rating": 4,
      "text": "Easy and tasty.",
      "author": { "id": "6721f0c2a1b2c3d4e5f60718", "firstName": "Ana" },
      "createdAt": "2026-10-27T18:20:00.000Z"
    }
  ],
  "page": 1,
  "totalPages": 1
}
```

- **Errors:**

| Status | Body | When |
| --- | --- | --- |
| 400 | `{ "error": "page must be a whole number, 1 or more" }` | bad `page` |
| 400 | `{ "error": "limit must be a whole number from 1 to 50" }` | bad `limit` |
| 401 | `{ "error": "Invalid or missing token" }` | no or bad token |
| 404 | `{ "error": "Recipe not found" }` | no recipe with that id |

### 16. `POST /api/recipes/:id/reviews`

One review per user per recipe (enforced by a unique index on `recipe + author`).

- **Auth:** token
- **Request:**

```json
{ "rating": 4, "text": "Easy and tasty." }
```

| Field | Type | Required | Rules |
| --- | --- | --- | --- |
| `rating` | integer | yes | whole number 1 to 5 |
| `text` | string | no | trimmed, up to 500 characters; `""` if not given |

- **Response 201:** the new `review`
- **Errors:**

| Status | Body | When |
| --- | --- | --- |
| 400 | `{ "error": "Rating must be a whole number from 1 to 5" }` | missing or bad rating |
| 400 | `{ "error": "Review text can be at most 500 characters" }` | text too long |
| 401 | `{ "error": "Invalid or missing token" }` | no or bad token |
| 404 | `{ "error": "Recipe not found" }` | no recipe with that id |
| 409 | `{ "error": "You already reviewed this recipe" }` | caller already reviewed it |

### 17. `DELETE /api/reviews/:id`

Only the review's author can delete it.

- **Auth:** token
- **Response 204:** no body
- **Errors:**

| Status | Body | When |
| --- | --- | --- |
| 401 | `{ "error": "Invalid or missing token" }` | no or bad token |
| 403 | `{ "error": "Not your review" }` | caller did not write it |
| 404 | `{ "error": "Review not found" }` | no review with that id |

## Comments

### 18. `GET /api/recipes/:id/comments?page=1&limit=20`

Lists a recipe's comments, oldest first (so they read like a conversation).

- **Auth:** token
- **Query parameters:** `page` and `limit` (see [Pagination](#pagination))
- **Response 200:**

```json
{
  "comments": [
    {
      "id": "6721f6e11b2c3d4e5f607182",
      "text": "I added chili flakes.",
      "author": { "id": "6721f0c2a1b2c3d4e5f60718", "firstName": "Ana" },
      "createdAt": "2026-10-27T18:25:00.000Z"
    }
  ],
  "page": 1,
  "totalPages": 1
}
```

- **Errors:**

| Status | Body | When |
| --- | --- | --- |
| 400 | `{ "error": "page must be a whole number, 1 or more" }` | bad `page` |
| 400 | `{ "error": "limit must be a whole number from 1 to 50" }` | bad `limit` |
| 401 | `{ "error": "Invalid or missing token" }` | no or bad token |
| 404 | `{ "error": "Recipe not found" }` | no recipe with that id |

### 19. `POST /api/recipes/:id/comments`

Any number of comments per user.

- **Auth:** token
- **Request:**

```json
{ "text": "I added chili flakes." }
```

| Field | Type | Required | Rules |
| --- | --- | --- | --- |
| `text` | string | yes | trimmed, 1 to 500 characters |

- **Response 201:** the new `comment`
- **Errors:**

| Status | Body | When |
| --- | --- | --- |
| 400 | `{ "error": "Comment text is required" }` | missing or empty after trimming |
| 400 | `{ "error": "Comment text can be at most 500 characters" }` | too long |
| 401 | `{ "error": "Invalid or missing token" }` | no or bad token |
| 404 | `{ "error": "Recipe not found" }` | no recipe with that id |

### 20. `DELETE /api/comments/:id`

Only the comment's author can delete it.

- **Auth:** token
- **Response 204:** no body
- **Errors:**

| Status | Body | When |
| --- | --- | --- |
| 401 | `{ "error": "Invalid or missing token" }` | no or bad token |
| 403 | `{ "error": "Not your comment" }` | caller did not write it |
| 404 | `{ "error": "Comment not found" }` | no comment with that id |

## Search rule

**In one sentence:** the server splits `q` on commas, matches each term as a partial ("contains") match against ingredient names and the title, counts how many terms each recipe matched, and returns the best matches first.

Step by step:

1. Read `q`, split it on commas, trim and lowercase each piece, drop empty pieces, and keep the first 10 terms.
2. For each term longer than 3 letters, strip one trailing `es` or `s` ("tomatoes" becomes "tomato", "eggs" becomes "egg").
3. Escape regex special characters in each term, so input like `(` cannot crash or abuse the query.
4. Find recipes where any term appears in an ingredient name or the title (case-insensitive contains).
5. For each recipe, `matchedTerms` = how many terms matched; `totalTerms` = how many terms were searched.
6. Sort by `matchedTerms` high to low, then by title A to Z, and return `limit` per page (default 20, see [Pagination](#pagination)).
7. Web and Flutter only display what comes back. They never re-rank.

| Typed | Terms searched | Example result |
| --- | --- | --- |
| `chick` | `chick` | "Chicken Fried Rice" (1 of 1) |
| `chick, rice` | `chick`, `rice` | "Chicken Fried Rice" (2 of 2) ranks above "Lemon Chicken" (1 of 2) |
| `Tomatoes, EGGS` | `tomato`, `egg` | recipes with tomato or egg, both first |
| `(` | `(` (escaped) | 200 with an empty list, not a server error |
| `,  ,` | none | 400 "Search text is required" |

## Limits and validation

Enforced in both the route validation and the Mongoose schema.

| Thing | Limit |
| --- | --- |
| First and last name | required, trimmed, 1 to 50 characters each |
| Password | at least 8 characters |
| Recipe title | required, trimmed, 1 to 100 characters |
| Ingredients | 1 to 10 per recipe; `name` required, lowercase, trimmed |
| Ingredient amount | optional plain text, up to 50 characters |
| Steps | 1 to 8 per recipe; each 1 to 500 characters |
| Review rating | whole number 1 to 5 |
| Review text | optional, up to 500 characters |
| Comment text | required, 1 to 500 characters |
| Search terms | first 10 terms only |
| `page` / `limit` | `page` 1 or more; `limit` 1 to 50 |

## Notes for implementers

- **Route order:** declare `GET /recipes/search` **before** `GET /recipes/:id`, or Express treats the word "search" as an id.
- **Who is calling:** every protected route reads the user from `req.userId` (set by `requireAuth` from the token), never from the request body.
- **Ownership:** every edit and delete (recipe, review, comment) checks the author against `req.userId` and returns 403 if they differ.
- **Bad ids:** an id that is not a valid MongoDB ObjectId returns 404, not 500.
- **Duplicates:** MongoDB error code `11000` maps to 409 (duplicate email on register, second review on the same recipe).
- **Never returned:** `passwordHash`, `verifyToken`, `resetToken`, and their expiry dates.
- **Cascade delete:** deleting a recipe also runs `deleteMany` on its reviews and comments.
- **Email links:** the server builds links from the `APP_URL` env variable (`<APP_URL>/verify?token=...`, `<APP_URL>/reset-password?token=...`), so local testing sends `http://localhost:5173/...` and production sends the real domain. All mail goes through `sendEmail` in `api/utils/mailer.js`.
- **Email tokens:** store verify and reset tokens hashed (SHA-256) in the database, the same idea as password hashing, so a database leak doesn't hand out working links. Compare by hashing the token from the request.
- **Resend verification:** replaces the stored verify token and expiry, so older links stop working.

## OpenAPI conversion notes

For converting this file to SwaggerHub/OpenAPI:

- `:id` becomes `{id}`, described once as a path parameter (see [Path parameter](#path-parameter)).
- The shared shapes (`user`, `author`, `recipe`, `review`, `comment`) and the error body go under `components/schemas`.
- `Authorization: Bearer` becomes a `bearerAuth` security scheme (`type: http`, `scheme: bearer`, `bearerFormat: JWT`), applied to every route not in the public list.
- `page` and `limit` become shared `components/parameters`.
- Each field table maps to a schema property with `type` and the `required` list.

## Open questions

The team still needs to decide these. Until then, build against the routes above.

1. **How does "generate recipes from my ingredients" work?** **10. search** only searches recipes already in our database. Either:
   - **(a)** search is the feature. Then we need a plan for the starting recipes (a seed script, or users only), since an empty database means empty results; or
   - **(b)** recipes come from an outside recipe API or an AI model. Then that needs its own route, with failure cases such as 502 or 503 when the outside service is down.
2. **Can guests browse?** Right now every recipe route needs a login.
3. **Recipe images?** If yes, `recipe` needs an `imageUrl` field, and someone has to decide how uploads work.
4. **Proposed additions** (not part of the contract until agreed):
   - `averageRating` and `reviewCount` on `recipe`, so lists can show stars without calling **15.** per recipe.
   - `PUT /api/reviews/:id` (author only, same body as create), since one review per recipe means a typo can only be fixed by deleting and re-posting.
   - `missingIngredients` in search results, so the apps can show "You're missing 2 ingredients".
   - Reject tokens issued before a password reset (store `passwordChangedAt` on the user). Right now old sessions stay valid for up to 24 hours after a reset.
