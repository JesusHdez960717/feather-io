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