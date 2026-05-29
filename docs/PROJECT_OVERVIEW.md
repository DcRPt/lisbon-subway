# Project Overview and Architecture

This file explains the structure of the Flutter app and how the main layers work together. It is intended for someone who is opening the project for the first time and wants a complete overview of the data flow, models, HTTP integration, and screen navigation.

---

## 1. What the project does

This app is a metro station dashboard for Lisboa transit data. It combines:

- a `Dashboard` with network status, nearest station, favorites, and a subway map
- a `Station list` with search and filters
- a `Map` view with the metro image
- a `Station detail` screen with incidents and waiting times
- an `Incident report` form for recording problems

It uses a remote API for station and transport status data and local SQLite storage for caching station information and incident reports.

---

## 2. How the app starts: `main.dart`

The entry point is `lib/main.dart`.

Important actions in `main.dart`:

- `WidgetsFlutterBinding.ensureInitialized()` ensures Flutter is ready before using native plugins like SQLite.
- `HttpOverrides.global = _HttpOverrides();` disables certificate validation for HTTP calls. This is a local workaround so the app can connect to the API without strict SSL checks.
- `SqfliteMetroDataSource` is created and initialized with `init()`. This sets up a local SQLite database.
- `HttpClient` is created. It wraps the `http` package with logging support from `pretty_http_logger`.
- `MultiProvider` creates shared services for the app:
  - `HttpMetroDataSource` for remote API calls
  - `SqfliteMetroDataSource` for local SQLite station and incident storage
  - `ConnectivityService` for checking network availability
  - `GpsLocationService` for location support (though the app currently uses a mock location in some places)
  - `MyGenericDataSource` for miscellaneous data operations that do not fit cleanly into the other sources
- `MyApp` renders `MainScreen()`.

So the app is built around providers and dependency injection, and the screens access the provided services from `main.dart`.

---

## 3. The data layer

The `lib/data/` folder contains the core data architecture.

### 3.1 `models/`

This folder contains simple Dart classes that represent the app's data structures.

- `Station` (`lib/models/station.dart`)
  - Represents a metro station.
  - Contains id, name, coordinates, line name, favorite status, incident reports, and waiting times.
  - Has helper logic for average incident severity and estimated frequency.
  - Can be converted from API JSON (`fromJson`) and from SQLite rows (`fromDB`).

- `IncidentReport` (`lib/models/incident_report.dart`)
  - Represents a user report about a station problem.
  - Contains date/time, severity rating, type, and optional notes.
  - Can be stored in SQLite and loaded back.

- `LineStatus` (`lib/models/line_status.dart`)
  - Represents the status of a metro line.
  - Used for the dashboard line state cards and list filters.
  - Parses API responses from `estadoLinha/todos` and `estadoLinha/{linha}`.

- `WaitingTime` (`lib/models/waiting_time.dart`)
  - Represents upcoming train arrival times for a station.
  - Converts API response values like `tempoChegada1`, `tempoChegada2`, and `tempoChegada3` into seconds and minutes.

- `Destination` (`lib/models/destination.dart`)
  - Used to map destination IDs to display names for waiting time directions. (This model is used by `MyGenericDataSource`.)

### 3.2 Data source abstractions

The app uses abstract classes to define what data can be fetched or stored.

- `MetroDataSource` (`lib/data/metro_datasource.dart`)
  - An abstract base class declaring operations for stations and incidents.
  - Methods include `insertStation`, `getAllStations`, `getStationsByName`, `getStationDetail`, and `attachIncident`.

- `GenericDataSource` (`lib/data/generic_data_source.dart`)
  - A flexible abstract interface for operations that do not fit in the main source.
  - It uses an enum `GenericOperationType` to dispatch a variety of utility operations.

### 3.3 Remote data source: `HttpMetroDataSource`

- `lib/data/http_metro_datasource.dart`
- Implements `MetroDataSource` for the remote API.
- Fetches an OAuth-like token from `https://api.metrolisboa.pt:8243/token`.
- Uses this token to request station details from:
  - `/infoEstacao/todos`
  - `/infoEstacao/{estacao}`
- There is no direct API endpoint for station search, so `getStationsByName` fetches all stations and filters them locally.
- The token is refreshed automatically on HTTP 401.
- Note: methods like `insertStation` and `attachIncident` are not supported by this remote source.

### 3.4 Local data source: `SqfliteMetroDataSource`

- `lib/data/sqflite_metro_datasource.dart`
- Uses `sqflite` to store station data and incident reports locally.
- The local database schema includes:
  - `stations` table with fields: `id`, `name`, `latitude`, `longitude`, `lineName`, `isFavourite`
  - `incident_reports` table with fields: `id`, `station_id`, `timestamp`, `rate`, `type`, `notes`
- This data source supports:
  - inserting station rows
  - fetching station lists and station detail
  - searching station names in the database
  - attaching new incident reports to a station
- When remote station data is refreshed, the app updates station fields but keeps local favorite flags.

### 3.5 Flexible operations: `MyGenericDataSource`

- `lib/data/my_generic_data_source.dart`
- Implements `GenericDataSource` and handles operations such as:
  - `GetFavourites`
  - `ToggleFavourite`
  - `GetIncidentsForStation`
  - `GetLineStatuses`
  - `GetLineStatus`
  - `GetWaitingTimes`
  - `GetDestinations`
- It combines local database reads for favorites and incidents with remote HTTP API calls for line statuses, waiting times, and destination labels.
- This file is the bridge for app features that need both local and remote data from a single interface.

### 3.6 HTTP helper: `HttpClient`

- `lib/http/http_client.dart`
- A small wrapper around `http` with request logging.
- It exposes `get(...)` and `post(...)` methods that convert strings to `Uri` and return HTTP responses.

### 3.7 Repository pattern: `MetroRepository`

- `lib/data/metro_repository.dart`
- This is the main API used by screens.
- It receives:
  - `HttpMetroDataSource` for remote station data
  - `SqfliteMetroDataSource` for local persistence
  - `ConnectivityModule` for network availability
  - `GenericDataSource` for utility operations
- It wraps data source logic and chooses where the data comes from:
  - `getAllStations()` fetches remote data when online, caches it locally, and returns the local list.
  - `getStationDetail()` fetches remote detail when online and otherwise returns local data.
  - `getStationsByLine()` filters the cached station list by line.
  - `getFavourites()` and `toggleFavourite()` use `GenericDataSource`.
  - `attachIncident()` writes incident reports to local storage.
  - `getIncidentsForStation()` loads station-specific reports.
  - `getAllLineStatuses()` and `getWaitingTimes()` call generic helper operations.

So the repository centralizes the app logic and keeps screens from depending directly on low-level database or HTTP details.

---

## 4. Screen architecture: `lib/screens/`

The screens define the user interface and their interactions.

### 4.1 `MainScreen`

- `lib/screens/main_screen.dart`
- Shows a bottom navigation bar with 4 tabs:
  1. Home (`DashboardScreen`)
  2. Estações (`ListScreen`)
  3. Mapa (`MapScreen`)
  4. Reportar (`IncidentReportScreen`)
- The currently selected screen is shown in the `Scaffold` body.
- This is the app root UI container.

### 4.2 `DashboardScreen`

- `lib/screens/dashboard_screen.dart`
- Loads two pieces of data in parallel:
  - all stations via `_repo.getAllStations()`
  - favorite stations via `_repo.getFavourites()`
- Builds these sections:
  - `ESTADO DA LINHA`: a small grid of line cards that indicate whether the line has recent incidents
  - `ESTAÇÃO MAIS PRÓXIMA`: shows a station card and a quick preview of minutes until the next trains
  - `FAVORITOS`: favorite stations list with a small severity badge
  - `MAPA DO METRO`: a subway map image that opens fullscreen when tapped
- User interactions:
  - tap a line card to open `ListScreen` filtered by that line
  - tap the nearest station or a favorite to open `StationDetailScreen`
- Note: the current version uses a mock location to calculate distances; it does not use the real GPS position for these cards.

### 4.3 `ListScreen`

- `lib/screens/list_screen.dart`
- Displays the full station list and includes search, filters, and an optional line selection.
- Loads:
  - all stations from `_repo.getAllStations()`
  - all line statuses from `_repo.getAllLineStatuses()`
- Search and filter features:
  - search bar filters station names
  - favorites toggle shows only stations marked as favorite
  - line chips allow filtering by a single metro line
  - filters include sort mode, distance radius, incident-free stations, severity thresholds, and excluded incident types
- It constructs a filtered station list in `_filtered(...)` and then renders cards.
- Tap on a station card to open `StationDetailScreen`.

### 4.4 `MapScreen`

- `lib/screens/map_screen.dart`
- This screen shows an embedded map image.
- The implementation is simpler than the other screens: it renders an image asset and a title.
- It does not currently use real map interactions or location services.

### 4.5 `StationDetailScreen`

- `lib/screens/station_detail_screen.dart`
- Shows full details for a selected station.
- Loads in parallel:
  - station detail via `_repo.getStationDetail(...)`
  - waiting times via `_repo.getWaitingTimes(...)`
  - destination labels via `_repo.generic.execute(type: GenericOperationType.GetDestinations)`
- Displays:
  - station name and line color in the app bar
  - number of incident reports and average severity
  - upcoming train times per platform/direction
  - list of incident reports sorted by newest first
  - a `+ Reportar` button to add a new incident
- Also supports toggling favorite status using `_repo.toggleFavourite(...)`.
- When the report screen closes, it reloads station details to show new incidents.

### 4.6 `IncidentReportScreen`

- `lib/screens/incident_report_screen.dart`
- A form for recording a new incident.
- It can receive a `preselectedStation` when opened from `StationDetailScreen`.
- Loads the full station list so the user can select any station.
- Form fields include:
  - station selector
  - incident type selector
  - severity rating from 1 to 5
  - date/time picker
  - optional notes
- When submitted, it uses `_repo.attachIncident(...)` and stores the report in the local SQLite database.
- The screen validates required fields and shows success or error feedback.

---

## 5. How the screens interact

### App flow examples

1. `DashboardScreen` opens the list of stations:
   - It calls `_repo.getAllStations()` and `_repo.getFavourites()`.
   - A station card opens `StationDetailScreen`.

2. `ListScreen` is used by the bottom bar and also by tapping a line card from `DashboardScreen`.
   - It receives an optional `initialLine` and uses it to pre-filter the list.
   - It allows search, favorites filtering, and advanced filters.

3. `StationDetailScreen` loads detailed station info and waiting times.
   - It can open `IncidentReportScreen` with the current station already selected.
   - After the incident form closes, `StationDetailScreen` refreshes to show the new incident.

4. `IncidentReportScreen` writes incident reports directly into local storage.
   - Those reports are displayed later by `StationDetailScreen` and can influence filter behavior in `ListScreen` and `DashboardScreen`.

### Data persistence and offline behavior

- When online, the app fetches station data from the remote API and caches it locally.
- When offline, the app falls back to the local SQLite database for stations and incidents.
- Favorites and incident reports are always stored locally.
- The local cache allows the app to keep working even without network access.

---

## 6. Key files to inspect first

If you want to understand how the app works, open these files in order:

1. `lib/main.dart` — app entry and providers
2. `lib/data/metro_repository.dart` — where data decisions happen
3. `lib/data/http_metro_datasource.dart` — remote API calls
4. `lib/data/sqflite_metro_datasource.dart` — local storage logic
5. `lib/screens/dashboard_screen.dart` — home screen UI and navigation
6. `lib/screens/list_screen.dart` — search and filters implementation
7. `lib/screens/station_detail_screen.dart` — detailed station view
8. `lib/screens/incident_report_screen.dart` — form handling and save logic

---

## 7. Recommended learning path

1. Read `main.dart` to see the services created for the app.
2. Read `MetroRepository` to understand how the app chooses between remote and local data.
3. Open `HttpMetroDataSource` and `SqfliteMetroDataSource` to compare remote vs local operations.
4. Explore `Station`, `IncidentReport`, `LineStatus`, and `WaitingTime` to see how raw data becomes app objects.
5. Open `DashboardScreen` and `ListScreen` to see the user flow and how screens consume repository data.
6. Finally, inspect `StationDetailScreen` and `IncidentReportScreen` to understand the incident reporting flow.

---

## 8. Notes for beginners

- The app uses a repository pattern: screens call `MetroRepository`, not the database or HTTP client directly.
- `Provider` is used only to create shared objects once in `main.dart`.
- The local SQLite database is the source of truth for cached data and user-generated data.
- The remote API is used mainly for station lists, station details, line status, and waiting times.
- `MyGenericDataSource` is a catch-all helper for operations that are not part of `MetroDataSource`.

If you want, I can also create a second document with a simplified diagram of the data flow and screen interactions.