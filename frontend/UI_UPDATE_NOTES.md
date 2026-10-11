# BookWise UI Update

## What's changed

- Added a collapsible desktop navigation sidebar. When collapsed, the navigation icons stay visible and show tooltips.
- Added a responsive bottom navigation bar for narrower screens.
- Updated the app palette to forest green, warm ivory, and gold with more consistent buttons, cards, borders, and form fields.
- Added borrowing summary cards to Home, Explore Books, and Reading History.
- Summary counts use the signed-in user's `/history` records: total borrow actions, active outstanding borrows, and return actions. The fourth card shows page-specific information.
- Updated book cards with cover-image fallback, rating and genre chips, more responsive Borrow/Return buttons, and a Reserve option when no copies are available.
- Applied the refreshed palette to the login, welcome, profile, recommendations, book form, and admin screens.

## Test in VS Code

From the `frontend` directory, run:

```powershell
flutter pub get
flutter analyze
flutter run -d chrome
```

For local backend testing on port 5000, run:

```powershell
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:5000/api
```

The ZIP excludes generated `.dart_tool` and `build` output. They are recreated by Flutter as needed. No backend `.env` file or credentials are included.
