# Recipe App API Contract

This file is the source of truth for every API route. The web app (React) and the mobile app (Flutter) build against exactly what is written here.

**Changing this file:** announce the change in the group chat first, then update this file in the same PR as the code change.

- Owner: API2 (drafted), API1 (reviewed)
- Status: draft for review, Week 1

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

## Conventions

| Rule | Value |
| --- | --- |
| Base path | `/api` (production: `https://<your-domain>/api`, local: `http://localhost:5000/api`) |
| Body format | JSON, with `Content-Type: application/json` |
| Field names | camelCase (`firstName`, `matchedTerms`) |
| Ids | strings (`"id": "6721f0c2a1b2c3d4e5f60718"`); the API returns `id`, never `_id` |
| Dates | ISO 8601 strings (`"2026-10-26T15:04:14.195Z"`) |
| Auth header | `Authorization: Bearer <token>` on every protected route |
| Token | JWT holding `{ userId }`, signed with `JWT_SECRET`, expires in 24 hours |

**Public routes (no token):** `GET /api/health`, `POST /auth/register`, `POST /auth/verify`, `POST /auth/login`, `POST /auth/forgot-password`, `POST /auth/reset-password`. Every other route needs a token.

### Errors

Every error has the same body:

```json
{ "error": "Human-readable message" }
```

| Status | Meaning |
| --- | --- |
| 400 | Bad input (missing field, wrong format, over a limit, bad or expired email token) |
| 401 | No token, invalid or expired token, or wrong login credentials |
| 403 | Logged in but not allowed (not the author, or email not verified) |
| 404 | The thing does not exist |
| 409 | Duplicate (email already registered, recipe already reviewed) |
| 500 | Server bug; clients show a generic "Something went wrong" |

Success statuses: **200** OK, **201** created, **204** deleted (no body).

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

- `ingredients[].name` is stored lowercase and trimmed, and should be singular ("tomato").
- `ingredients[].amount` is plain text ("2 cups", "a pinch"). There is no unit conversion.

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

19 routes (plus the health check). All paths below start with `/api`.

| # | Method | Path | Auth | Owner | Success |
| --- | --- | --- | --- | --- | --- |
| - | GET | `/health` | none | API1 | 200 |
| 1 | POST | `/auth/register` | none | API1 | 201 |
| 2 | POST | `/auth/verify` | none | API1 | 200 |
| 3 | POST | `/auth/login` | none | API1 | 200 |
| 4 | POST | `/auth/forgot-password` | none | API1 | 200 |
| 5 | POST | `/auth/reset-password` | none | API1 | 200 |
| 6 | GET | `/users/me` | token | API1 | 200 |
| 7 | PUT | `/users/me` | token | API1 | 200 |
| 8 | GET | `/recipes` | token | API2 | 200 |
| 9 | GET | `/recipes/search` | token | API2 | 200 |
| 10 | GET | `/recipes/:id` | token | API2 | 200 |
| 11 | POST | `/recipes` | token | API2 | 201 |
| 12 | PUT | `/recipes/:id` | token | API2 | 200 |
| 13 | DELETE | `/recipes/:id` | token | API2 | 204 |
| 14 | GET | `/recipes/:id/reviews` | token | API2 | 200 |
| 15 | POST | `/recipes/:id/reviews` | token | API2 | 201 |
| 16 | DELETE | `/reviews/:id` | token | API2 | 204 |
| 17 | GET | `/recipes/:id/comments` | token | API2 | 200 |
| 18 | POST | `/recipes/:id/comments` | token | API2 | 201 |
| 19 | DELETE | `/comments/:id` | token | API2 | 204 |

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

Creates an unverified account and emails a verification link to `https://<your-domain>/verify?token=<token>` (valid 24 hours).

- **Auth:** none
- **Request:**

```json
{ "firstName": "Ana", "lastName": "Diaz", "email": "ana@test.com", "password": "Passw0rd!" }
```

| Field | Rules |
| --- | --- |
| `firstName`, `lastName` | required, trimmed, 1 to 50 characters |
| `email` | required, valid email format, stored lowercase |
| `password` | required, at least 8 characters |

- **Response 201:**

```json
{ "message": "Verification email sent" }
```

- **Errors:**

| Status | Body | When |
| --- | --- | --- |
| 400 | `{ "error": "A valid email is required" }` | missing field, bad email, short password |
| 409 | `{ "error": "Email already registered" }` | email already has an account |

### 2. `POST /api/auth/verify`

Called by the web page at `/verify?token=...`. Phone users open the link in their phone's browser, then log in to the app.

- **Auth:** none
- **Request:**

```json
{ "token": "9f2c4e...e81a" }
```

- **Response 200:**

```json
{ "message": "Email verified. You can log in now." }
```

- **Errors:**

| Status | Body | When |
| --- | --- | --- |
| 400 | `{ "error": "Invalid or expired link" }` | token missing, wrong, already used, or older than 24 hours |

### 3. `POST /api/auth/login`

- **Auth:** none (rate-limited)
- **Request:**

```json
{ "email": "ana@test.com", "password": "Passw0rd!" }
```

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

Clients: a 401 from login is a wrong password, not an expired session. Show the message; do not log the user out.

### 4. `POST /api/auth/forgot-password`

Emails a reset link to `https://<your-domain>/reset-password?token=<token>` (valid 1 hour, single use).

- **Auth:** none
- **Request:**

```json
{ "email": "ana@test.com" }
```

- **Response 200** (the same reply whether or not the email has an account, so strangers cannot find out who is registered):

```json
{ "message": "If that email has an account, a reset link was sent" }
```

- **Errors:**

| Status | Body | When |
| --- | --- | --- |
| 400 | `{ "error": "A valid email is required" }` | missing or badly formatted email |

### 5. `POST /api/auth/reset-password`

Called by the web page at `/reset-password?token=...`.

- **Auth:** none
- **Request:**

```json
{ "token": "4b7d1a...c09f", "newPassword": "N3wPassw0rd!" }
```

- **Response 200:**

```json
{ "message": "Password updated. You can log in now." }
```

- **Errors:**

| Status | Body | When |
| --- | --- | --- |
| 400 | `{ "error": "Invalid or expired link" }` | token wrong, used, or older than 1 hour |
| 400 | `{ "error": "Password must be at least 8 characters" }` | new password too short |

## Profile

### 6. `GET /api/users/me`

Returns the logged-in user. The app also calls this on launch to check a saved token.

- **Auth:** token
- **Response 200:** a `user`

```json
{ "id": "6721f0c2a1b2c3d4e5f60718", "firstName": "Ana", "lastName": "Diaz", "email": "ana@test.com" }
```

- **Errors:** 401 `{ "error": "Invalid or missing token" }`

### 7. `PUT /api/users/me`

Updates the logged-in user's name. Email cannot be changed. The user id comes from the token, never the body.

- **Auth:** token
- **Request:**

```json
{ "firstName": "Ana", "lastName": "Diaz-Lopez" }
```

- **Response 200:** the updated `user`

```json
{ "id": "6721f0c2a1b2c3d4e5f60718", "firstName": "Ana", "lastName": "Diaz-Lopez", "email": "ana@test.com" }
```

- **Errors:**

| Status | Body | When |
| --- | --- | --- |
| 400 | `{ "error": "First and last name are required" }` | missing or empty name |
| 401 | `{ "error": "Invalid or missing token" }` | no or bad token |

## Recipes and search

### 8. `GET /api/recipes?page=1&limit=20&mine=true`

Lists recipes, newest first.

- **Auth:** token
- **Query parameters:**

| Name | Default | Rules |
| --- | --- | --- |
| `page` | 1 | whole number, 1 or more |
| `limit` | 20 | whole number, 1 to 50 |
| `mine` | false | `true` returns only the caller's recipes |

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

- **Errors:** 401 `{ "error": "Invalid or missing token" }`

### 9. `GET /api/recipes/search?q=chick,rice&page=1`

Partial-match ingredient search, done on the server. Clients call it as the user types (250 ms debounce). See the [search rule](#search-rule) for exactly how it works.

- **Auth:** token
- **Query parameters:**

| Name | Default | Rules |
| --- | --- | --- |
| `q` | none | required; comma-separated terms, for example `chick,rice` (URL-encode it) |
| `page` | 1 | whole number, 1 or more; 20 results per page |

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
| 401 | `{ "error": "Invalid or missing token" }` | no or bad token |

Clients show "Matches 2 of 2" from `matchedTerms` and `totalTerms`, and never re-sort or filter the results.

### 10. `GET /api/recipes/:id`

- **Auth:** token
- **Response 200:** a `recipe`
- **Errors:**

| Status | Body | When |
| --- | --- | --- |
| 401 | `{ "error": "Invalid or missing token" }` | no or bad token |
| 404 | `{ "error": "Recipe not found" }` | no recipe with that id, or the id is not a valid id |

### 11. `POST /api/recipes`

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

- **Response 201:** the new `recipe`
- **Errors:**

| Status | Body | When |
| --- | --- | --- |
| 400 | `{ "error": "A recipe can have at most 10 ingredients" }` | over 10 ingredients |
| 400 | `{ "error": "A recipe can have at most 8 steps" }` | over 8 steps |
| 400 | `{ "error": "Title is required" }` | missing title, empty ingredient name, no ingredients or steps, other bad input |
| 401 | `{ "error": "Invalid or missing token" }` | no or bad token |

### 12. `PUT /api/recipes/:id`

Replaces the title, ingredients, and steps. Only the author can edit.

- **Auth:** token
- **Request:** same body as `POST /api/recipes` (all three fields)
- **Response 200:** the updated `recipe`
- **Errors:**

| Status | Body | When |
| --- | --- | --- |
| 400 | same messages as create | bad input or over the limits |
| 401 | `{ "error": "Invalid or missing token" }` | no or bad token |
| 403 | `{ "error": "Not your recipe" }` | caller is not the author |
| 404 | `{ "error": "Recipe not found" }` | no recipe with that id |

### 13. `DELETE /api/recipes/:id`

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

### 14. `GET /api/recipes/:id/reviews`

Lists a recipe's reviews, newest first.

- **Auth:** token
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
  ]
}
```

- **Errors:** 401 (no or bad token); 404 `{ "error": "Recipe not found" }`

### 15. `POST /api/recipes/:id/reviews`

One review per user per recipe (enforced by a unique index on `recipe + author`).

- **Auth:** token
- **Request:**

```json
{ "rating": 4, "text": "Easy and tasty." }
```

| Field | Rules |
| --- | --- |
| `rating` | required, whole number 1 to 5 |
| `text` | optional, up to 500 characters |

- **Response 201:** the new `review`
- **Errors:**

| Status | Body | When |
| --- | --- | --- |
| 400 | `{ "error": "Rating must be a whole number from 1 to 5" }` | bad rating or text too long |
| 401 | `{ "error": "Invalid or missing token" }` | no or bad token |
| 404 | `{ "error": "Recipe not found" }` | no recipe with that id |
| 409 | `{ "error": "You already reviewed this recipe" }` | caller already reviewed it |

### 16. `DELETE /api/reviews/:id`

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

### 17. `GET /api/recipes/:id/comments`

Lists a recipe's comments, oldest first (so they read like a conversation).

- **Auth:** token
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
  ]
}
```

- **Errors:** 401 (no or bad token); 404 `{ "error": "Recipe not found" }`

### 18. `POST /api/recipes/:id/comments`

Any number of comments per user.

- **Auth:** token
- **Request:**

```json
{ "text": "I added chili flakes." }
```

| Field | Rules |
| --- | --- |
| `text` | required, trimmed, 1 to 500 characters |

- **Response 201:** the new `comment`
- **Errors:**

| Status | Body | When |
| --- | --- | --- |
| 400 | `{ "error": "Comment text is required" }` | empty or too long |
| 401 | `{ "error": "Invalid or missing token" }` | no or bad token |
| 404 | `{ "error": "Recipe not found" }` | no recipe with that id |

### 19. `DELETE /api/comments/:id`

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
6. Sort by `matchedTerms` high to low, then by title A to Z, and return 20 per page.
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
| Recipe title | required, up to 100 characters |
| Ingredients | 1 to 10 per recipe; `name` required, lowercase, trimmed |
| Ingredient amount | plain text, up to 50 characters |
| Steps | 1 to 8 per recipe; each up to 500 characters |
| Review rating | whole number 1 to 5 |
| Review text | up to 500 characters |
| Comment text | required, up to 500 characters |
| Password | at least 8 characters |
| Search terms | first 10 terms only |

## Notes for implementers

- **Route order:** declare `GET /recipes/search` **before** `GET /recipes/:id`, or Express treats the word "search" as an id.
- **Who is calling:** every protected route reads the user from `req.userId` (set by `requireAuth` from the token), never from the request body.
- **Ownership:** every edit and delete (recipe, review, comment) checks the author against `req.userId` and returns 403 if they differ.
- **Bad ids:** an id that is not a valid MongoDB ObjectId returns 404, not 500.
- **Duplicates:** MongoDB error code `11000` maps to 409 (duplicate email on register, second review on the same recipe).
- **Never returned:** `passwordHash`, `verifyToken`, `resetToken`, and their expiry dates.
- **Cascade delete:** deleting a recipe also runs `deleteMany` on its reviews and comments.
