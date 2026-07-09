# Project Agent Context: S3-Compatible Storage System

## Project Overview
Monorepo: Dart Backend (`/service`) + Flutter Web Console (`/console`).
Core: Custom **Winter** framework and S3-compliant XML/JSON API.

## Tech Stack
- **Backend:** Dart + Winter (internal framework located at `../../winter`).
- **Frontend (`/console`):** Flutter Web, admin console interface.
- **Core Protocol:** XML parsing/generation for S3 compatibility using the [xml](https://pub.dev/packages/xml) package, REST API, and standard S3 error handling.

## Repository Structure
- `/service`: The backend API handling S3 operations.
- `/console`: The web-based administration panel.
- `/../winter`: The underlying framework source code (for reference).

## Development Status & Guidelines Relaxations
- **No Security/Authentication:** Do NOT implement AWS SigV4. All incoming requests are validated by checking for the presence of `x-feather-access` and `x-feather-secret` headers.
- **S3 Specification Flexibility:** Focus on core CRUD. Ignore complex bucket policies, MD5 checksum validation, and advanced multipart edge cases for now.

## Guidelines for AI Agent

### 1. Architectural Principles
- **Winter Framework:** Adhere to Winter's design patterns. Use `ResponseEntity` for all responses.
- **Data Serialization:** 
    - **JSON:** Manually implement the `Serializable` interface (from `package:winter/winter.dart`) and its `toJson()` method. **Do not use build_runner or code generation.**
    - **XML:** Use `XmlBuilder` within the Controller layer to generate S3-compliant XML strings.

### 2. Error Handling & S3 Codes
- Exceptions must be caught at the Controller level and translated into `S3Exception` objects (or similar) that map to official AWS Error Codes (e.g., `NoSuchBucket`, `InvalidPart`, `EntityTooLarge`).
- The response body for errors must also respect the Content Negotiation rules.

### 3. API Content Negotiation (JSON vs XML)
- The Controller is responsible for inspecting `request.headers['accept']`.
- **Logic Pattern:**
    ```dart
    if (request.headers[HttpHeaders.acceptHeader]?.contains('application/json') == true) {
      return ResponseEntity.ok(body: model); // Winter auto-serializes Serializable to JSON
    } else {
      final xmlBody = _mapToS3Xml(model); // Helper method using XmlBuilder
      return ResponseEntity.ok(
        body: xmlBody,
        headers: {HttpHeaders.contentTypeHeader: 'application/xml'},
      );
    }
    ```

### 4. Backend Architecture & Decoupling
- **Layer Separation:** Services and Repositories must return typed Models (e.g., `BucketModel`, `ObjectModel`).
- **No Format Leaks:** Business logic layers must NEVER import `package:xml` or return raw JSON maps. All formatting happens in the **Controller**.

### 5. Verification & Commands
- Ensure that path-style routing (e.g., `/bucket-name/object-key`) is correctly handled in `S3Controller` using Winter's route parameters.

### 6. Key Architectural Rules (from Rules file)
1. **Performance:** Mandatory use of `Stream<List<int>>` for object data to ensure low memory footprint.
2. **Content Negotiation:** The Controller detects the `Accept` header to switch between JSON and S3-standard XML.
3. **Error Mapping:** All business errors must be caught in the Controller and converted to `S3Exception` (mapped to AWS Error Codes).

### 7. Development Guidelines
- **Auth:** Simplified header-based auth (`x-feather-access`, `x-feather-secret`).
- **Structure:**
  - Service Layer → Business logic + Models.
  - Controller Layer → Routing + Auth + Format Translation (XML/JSON).
  - Repository Layer → Data persistence (I/O).
- **No Shelf:** Use Winter abstractions (`RequestEntity`, `ResponseEntity`).

---

# IDE Rules: S3-Compatible Backend (Winter & Dart)

## Role & Persona
Expert systems developer in Dart/Cloud Storage. Focus: High-performance, S3-compatible engine using **Winter**.

## 1. Tech Stack & Environment
- **Core:** Winter (`../../winter`). Key classes: `ResponseEntity`, `RequestEntity`, `Route`, `ObjectMapper`.
- **No CodeGen:** STRICTLY NO `build_runner`. Implement `Serializable` (from `winter.dart`) and `toJson()` manually.
- **Project:** `/service` (backend) and `/console` (frontend) are strictly decoupled.

## 2. Security (Simplified)
- **Auth:** Validate only via `x-feather-access` and `x-feather-secret` headers.
- **No SigV4:** Do not implement AWS signature logic unless explicitly asked.
- **Middleware:** Use Winter's `AuthFilter` and `filterConfig` where necessary, but keep logic simple.

## 3. S3 Architecture & Content Negotiation
- **Path-style:** `/bucket-name/object-key`.
- **Content Negotiation (Controller level ONLY):**
  - `Accept: application/json` -> `ResponseEntity.ok(body: model)`.
  - Default/XML -> `XmlBuilder` -> `application/xml`.
- **Errors:** Use `S3Exception`. Map to standard AWS codes (e.g., `NoSuchBucket`). Return XML by default unless JSON is requested.

## 4. Performance & Data Handling
- **Streaming:** Always use `Stream<List<int>>` for `PutObject`/`GetObject`.
- **Memory:** NEVER use `readAsBytes()` or `Uint8List` for file payloads.
- **Typing:** Avoid `dynamic`. Use `Map<String, dynamic>` for raw data or strict Models.

## 5. Domain Decoupling (Strict)
- **Logic/Service:** Returns format-agnostic Models. NO XML/JSON imports here.
- **Controller:** The ONLY layer handling `package:xml`, `toJson`, or `Content-Type`.

## Prohibited Patterns
- Do NOT use `shelf` boilerplate directly; use `Winter` abstractions.
- Do NOT leak `Content-Type` detection into the Repository layer.
- Do NOT add external dependencies for tasks that Dart's core or Winter can handle (e.g., basic XML strings).

---

# Architectural Rules & Standards

## FOR CONSOLE (in `/console`):

### 1. Project Structure
Each feature must be self-contained within `lib/features/{feature_name}/`:

- **`data/rest/`**: Contains `{feature}_client.dart`.
  - Defines the API client (extending `BaseClient`).
  - Uses `options(access: auth.access, secret: auth.secret)` from `BaseClient` for authenticated requests.
  - Contains all DTOs (Request/Response classes) at the end of the file.
- **`data/repo/`**: Contains `{feature}_repo.dart`.
  - Handles the orchestration between Client and Domain Models.
  - Responsible for mapping DTOs to Models (via extensions).
  - Must wrap calls in `try-catch` using `ExceptionConverter.parse(exc)`.
- **`logic/cubit/`**: Contains the Cubit and its States (often in the same file for simplicity).
  - Manages business logic and UI state transitions.
  - Follows consistent naming: `{Feature}{StateName}State` (e.g., `BrowserLoadingSuccessState`).
- **`logic/model/`**: Contains domain models and form-specific models.
- **`view/`**: Contains UI components.
  - `{feature}_screen.dart`: Main entry point for the feature.
  - `form/`: Dialogs and widgets for data entry.

### 2. Layer Responsibilities

#### Data Layer (Client & DTOs)
- Use `snake_case` for JSON keys and `camelCase` for Dart properties.
- Requests must have a `toJson()` method.
- Responses must have a `fromJson()` factory.
- Organize DTOs with clear headers: `//---------- {NAME} RESPONSE ----------`.

#### Repository Layer
- Always inject the Client via constructor.
- Use extensions for mapping (e.g., `extension FeatureResponseMapping on FeatureResponse`).
- Throw standardized `GlobalException` using `ExceptionConverter`.

#### Logic Layer (Cubit)
- Follow a consistent State naming convention:
  - `InitialState`
  - `LoadingInProgressState`, `LoadingSuccessState`, `LoadingErrorState`
  - `ProcessInProgressState`, `ProcessingOKState`, `ProcessingErrorState`
- Prefix states with the feature name to avoid global namespace collisions (e.g. `BrowserLoadingSuccessState`).
- Use `AuthCubit` to retrieve credentials (`auth.access`, `auth.secret`).

#### View Layer (UI)
- **Navigation**: Use a static `Navigator` class inside the screen/dialog (e.g., `BrowserScreen.navigator`) to define `name`, `path`, and `builder`.
- **Global Accessor**: Use the `app` singleton for all shared services:
  - `app.di.find<T>()`: Dependency Injection.
  - `app.dateFormatter`: Date formatting.
  - `app.navigator`: Navigation.
- **Shared Pages**:
  - `LoadingPage()`: For loading states.
  - `ErrorPage(message: state.message, onRetry: () => ...)`: For error states.
  - `NoDataPage(title: '...')`: For empty states.
- **Components**:
  - Use `CustomAppBar.build(title: '...')` for screens.

### 3. Coding Style
- Use `context.read<T>()` or `app.di.find<T>()` to access cubits.
- Use `.gap()` (via extension) for spacing.
- Keep UI components small and modular.


## FOR SERVICE (in `/service`):

### 1. Feature Architecture
Follow a layered approach for every new functionality:
- **Model Layer (`lib/features/files/logic/model/`)**: 
  - Define typed classes (e.g., `BucketModel`).
  - Implement `Serializable` and `toJson()` for JSON responses.
- **Service Layer (`lib/features/files/logic/service/`)**:
  - Implement the core logic (e.g., `listBuckets()`).
  - Handle physical I/O and business validations (e.g., `isValidBucketName`).
  - **Restriction**: Never import `package:xml` or handle HTTP formats here. Return only Models or Streams.
- **Controller Layer (`lib/features/s3/rest/`)**:
  - Define routes and apply security filters (e.g., `hasRole('admin')`).
  - **Content Negotiation**: Inspect `Accept` header to decide between JSON (automatic via Winter) or XML.
  - **XML Mapping**: Implement private helper methods (e.g., `_mapToXml`) to generate S3-compliant XML strings.

### 2. Testing
- **New Features**: Every time a new feature is created, add unit tests.
- **Test Organization**:
  - `s3_controller_test.dart`: Contains the **Happy Path** (integration flow: Upload -> List -> Get -> Delete).
  - Specific files for each endpoint/logic (e.g., `put_object_test.dart`, `list_buckets_test.dart`).
- **Test Environment**:
  - **Storage**: Use a subfolder within `./uploads_test/` for each test file (e.g., `./uploads_test/put_test`). This folder is ignored by git.
  - **Ports**: Use different ports (e.g., 8081, 8082) for each test file to allow parallel execution.
  - **Cleanup**: Always delete the test storage directory in `setUpAll` and `tearDownAll`.
- **Validation Scope**:
  - Test authentication (missing headers → 401, wrong headers → 403).
  - Test validation (invalid bucket names, path traversal, forbidden characters → 400).
  - Test content negotiation (JSON vs XML).
  - Test edge cases (not found → 404, empty lists).
