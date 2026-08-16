# TVtracker

A clean and simple Flutter application for tracking movies, TV series, and anime. The app works fully offline and stores data locally on the device using `shared_preferences`.

## App Purpose

TVtracker helps users maintain a personal watch list. Users can add titles, organize them by category, update their watch status, search through the list, filter items, and create JSON backups.

## Main Features

- Add new watch items
- Edit existing items
- Delete one item or clear the full list
- Track three categories: `Series`, `Movie`, and `Anime`
- Track three statuses: `Watched`, `Watching`, and `To Watch`
- Search items by name
- Filter by category and status
- View summary counters for total, watched, watching, and to-watch items
- Load included TV Time import data
- Export the current list as JSON
- Import a JSON backup
- Save data locally on the device

## How to Run

Make sure Flutter is installed first. Then open the project folder in VS Code or Android Studio and run:

```bash
flutter pub get
flutter run
```

For web testing, run:

```bash
flutter run -d chrome
```

## How to Use the App

### Add an Item

1. Enter the movie, series, or anime name.
2. Select a category.
3. Select a watch status.
4. Click **Add**.

### Edit an Item

1. Click **Edit** on an item in the list.
2. Update the name, category, or status.
3. Click **Save**.
4. Click **Cancel** to stop editing.

### Delete Items

- Click **Delete** on a single item to remove it.
- Click **Delete All** to clear the full list.

### Search and Filter

Use the search box to find items by name. Use the category and status dropdowns to filter the list. Click **Clear Filters** to show all items again.

### Load TV Time Import

Click **Load TV Time Import** to load the included sample/imported watch list. This replaces the current list, so export a backup first if needed.

### Export Backup

1. Click **Export**.
2. Copy the generated JSON.
3. Save it in a text file or notes app.

### Import Backup

1. Click **Import**.
2. Paste a previously exported JSON backup.
3. Confirm the import.

The imported backup replaces the current list.

## Data Storage

The app uses local device storage through the `shared_preferences` package. No database, server, or login is required.

Saved item fields:

```json
{
  "id": "unique item id",
  "name": "Item name",
  "category": "Series | Movie | Anime",
  "status": "Watched | Watching | To Watch"
}
```

## Backup Format

The export feature creates JSON with metadata and an `items` array:

```json
{
  "metadata": {
    "app": "TVtracker",
    "version": 1,
    "exportedAt": "date and time",
    "fields": ["id", "name", "category", "status"]
  },
  "items": []
}
```

The import feature also accepts a plain JSON array of items.

## Project Structure

```text
lib/
├── main.dart
├── app/
│   └── watch_tracker_app.dart
├── core/
│   ├── constants/
│   ├── theme/
│   └── utils/
└── features/
    └── watch_tracker/
        ├── controllers/
        ├── data/
        ├── models/
        ├── services/
        └── ui/
            ├── pages/
            └── widgets/
```

## Clean Coding Approach

The app is organized into simple layers:

- `models` hold data classes.
- `services` handle storage and backup logic.
- `controllers` manage app state and operations.
- `ui/pages` contain main screens.
- `ui/widgets` contain reusable UI components.
- `core` contains shared constants, theme, and utility classes.

This keeps the application easier to extend later with features such as ratings, notes, episode progress, SQLite, Firebase, or user accounts.
