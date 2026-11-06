# Savory mobile app (Flutter)

The Flutter client of the recipe app. It uses the same API as the web app (`web/`) and
behaves the same way: **the web app defines the behaviour** (rules, messages, flows, data),
**the Figma file "Large ahh burger project", page Mobile Screens, defines the look**, and
**`api/` defines the data**.

Stack: Flutter, Dart, Riverpod, GoRouter, Dio. App name **Savory**
(Android `edu.ucf.poosd.savory_app`, iOS `edu.ucf.poosd.savoryApp`).

## Run

Requires Flutter 3.47 stable or newer. iOS needs macOS with Xcode.

```bash
cd frontend/mobile
flutter pub get
flutter run                                            # live API (contactshub.site)
flutter run --dart-define=API_BASE_URL=http://192.168.1.20:5000/api   # your local API
flutter run --dart-define=USE_SAMPLE_AUTH=true --dart-define=USE_SAMPLE_RECIPES=true  # offline
```

| Flag | Default | Meaning |
| --- | --- | --- |
| `API_BASE_URL` | `https://contactshub.site/api` | From a phone, use the computer's LAN IP, not `localhost`. |
| `USE_SAMPLE_AUTH` | `false` | `true`: offline sample account (any email + 8+ char password; `unverified…` gets 403; registering `taken…` gets 409). |
| `USE_SAMPLE_RECIPES` | `false` | `true`: offline sample recipes in the API's exact shape. |

Search turns on with `AppConfig.recipeSearchAvailable` once `GET /api/recipes/search` exists.

## Demo device

**iPhone 16e simulator, 390 × 844 points** (the size of every Figma mobile frame; iPhone
13/14 match). Android cross-check: **Pixel 7 emulator, 412 × 915 dp**. Layouts use flexible
widths and scrolling, not fixed screen sizes.

## Web ↔ mobile

| Feature | Web (`web/src`) | Mobile | Status |
| --- | --- | --- | --- |
| Login | `LoginForm`: no client checks; API message or "Unable to log in."; 403 → "Please verify your email before logging in." + Resend button; "Logging in…" | Same rules, messages and resend button, in the Figma 01 layout | Implemented, not run |
| Registration | `RegisterForm`: non-blank names, email regex, password 8+ with a number and a symbol, confirm must match; errors after first submit; 4-part strength meter (weak < 3) | Same rules, messages and meter, Figma 02/03 layout | Implemented, not run |
| Check your email | Same page shows "We sent a verification link to … Open it to activate your account." + Resend button | Own screen (mobile has no room to swap the form in place) with the same text, resend, and Back to Log In | Implemented, not run |
| Email verification link | `/verify` page calls `POST /auth/verify` | Not in the app: the emailed link opens the web page in the phone's browser | By design |
| Forgot password | `/forgot-password`: `POST /auth/forgot-password`, API message | Same, Figma 04 layout | Implemented, not run |
| Reset password | `/reset-password?token=` from the email | Not in the app: the link opens the web page | By design |
| Resend verification page | `/resend-verification` (linked from a failed `/verify`) | Covered by the resend button on login (403) and check-your-email | By design |
| Session | token + user in localStorage, restored without a request; token not sent to `/auth/*`; 401 on a request that sent it → logout to login | Same, in the iOS Keychain / Android Keystore (`flutter_secure_storage`) | Implemented, not run |
| After login | `/home`, a placeholder "Logged in as …" page | Straight to the recipe list; Account tab shows "Logged in as …" and Log Out | Intentional difference |
| Recipe listing | `GET /api/recipes?page&limit=12`; featured = first recipe on page 1; card: photo, title, first 3 ingredients "+N more", "By <name>"; loading, error + "Try again", "No recipes yet"; prev / pages / next | Same requests and content, Figma 08/13/14 layout, numbered pages windowed for phone width | Implemented, not run against the API |
| Recipe search | Disabled box, "Search by ingredient (coming soon)" | Same | Matches web (route not built) |
| Recipe details | `/recipes/:id`, `GET /api/recipes/:id`; "SAVORY RECIPE", title, "By <name>", Ingredients, Method; "Preparing your recipe…"; error message shown | Same content and messages; shows the recipe passed from the list at once, fetches by id otherwise | Implemented, not run |
| Photos | `imageFor(id)` picks 1 of 6 photos | Same function and photos (unit-tested against the web's JS) | Tested (logic) |
| TheMealDB credit | "Recipe data from TheMealDB", every page | Same text and link: legal footer (auth screens), list, recipe | Implemented |

### Found while comparing

- **Web bug:** `GET /api/recipes` returns `{ recipes, page, totalPages }` (api/routes/recipes.js
  and the contract), but `web/src/types/index.ts` and `RecipesPage.tsx` read `results`, so the
  web list breaks against the real API. Mobile reads `recipes`. Fix in the web: rename
  `results` to `recipes` in `RecipeListResponse` and `RecipesPage.tsx`. Not changed here.
- The API sends `author: null` for recipes whose author was deleted. Mobile handles it (web
  falls back to "a Savory cook" / "Savory cook", and so does mobile).
- The web asks for a number and a symbol in passwords; the API only checks 8 characters.
  Mobile follows the web.

## Assets

| File | What | Used by | Source |
| --- | --- | --- | --- |
| `assets/icons/*.svg` (9) | eye, eye-off, alert, search, green search, 4 tab icons | text field, search, empty state, tab bar | Figma Mobile Screens (eye and alert rebuilt from Figma's vector paths: the SVG export drops the pupil and "!") |
| `assets/images/recipes/recipe_photo_1…6.png` | food photos | recipe cards, featured card, recipe screen | `web/public/assets/` 3ecaf, 412f6, 1df21, da300, 31edd, 3751d (same order as the web) |
| `assets/images/grain_bowl.png` | bowl on the login banner | login | `web/public/assets/24a21.png`, 384 px. **Chosen by eye; not compared with the Figma "Grain bowl" layer.** |

All assets are in the repo and registered in `pubspec.yaml` (`assets/icons/`,
`assets/images/`, `assets/images/recipes/`). Nothing loads from Figma URLs.
Fonts load through `google_fonts` (DM Sans, Playfair Display).

## Native projects

`android/` and `ios/` hold what `flutter create . --platforms=android,ios` makes for
Flutter 3.47.9, rendered from Flutter's official templates (the SDK wasn't available where
this was written). iOS app icons are Flutter's default. Running
`flutter create . --platforms=android,ios` once only adds missing files.

## Testing status

Not yet run: `flutter analyze`, `flutter test`, `flutter run`, and Android/iOS builds.
What did run: every Dart file parses (`dart format`); the Dart analyzer and 33 checks on the
non-UI code (models, API shapes, web validation rules, photo picker, sample repositories).

```bash
flutter analyze && flutter test
flutter run -d "iPhone 16e"      # then a Pixel 7 emulator
```

## Layout

```
lib/core/       config, constants, network (Dio client = web/src/api/client.ts), router, storage, theme
lib/features/   authentication/, recipes/   (data: API + sample repos, domain: models, presentation)
lib/shared/     widgets: header, buttons, text field, cards, footer, TheMealDB credit, tab shell
assets/         icons/ (Figma SVG), images/ (photos)      test/   unit tests
android/ ios/   native projects
```

## Open items

- No Figma frames for "check your email" or the recipe screen; both reuse existing pieces.
- My kitchen and Saved tabs are placeholders; "Need help?" and Privacy/Terms are text only.
- The photo ring width is approximated from the Figma renders.
