---
name: openapi-generator
description: Generate and sync OpenAPI (REST) and AsyncAPI (WebSocket) documentation for projects. This skill should be used when the user asks to generate API docs, create OpenAPI specs, update/sync existing API documentation, or write asyncapi specs. Currently supports Rust web frameworks (Axum, Actix-web, Rocket, Poem). Triggers on keywords like "openapi", "swagger", "api docs", "API documentation", "asyncapi".
---

# OpenAPI / AsyncAPI Generator

Generate split-file OpenAPI 3.0.3 specs for REST endpoints and AsyncAPI 3.0.0 specs for WebSocket message formats by scanning project source code.

## Mode Detection

Determine the mode based on user request and project state:

- **Generate mode**: No `openapi/` directory exists in the project, or user explicitly asks to create/generate docs
- **Sync mode**: An `openapi/` directory already exists, and user asks to update/sync/refresh docs

## Generate Mode

### Step 1: Identify Framework

Read `Cargo.toml` to detect the web framework. Refer to `references/rust-framework-patterns.md` for the dependency-to-framework mapping.

If `poem-openapi` is detected, warn the user that Poem has built-in OpenAPI generation and ask whether to proceed with manual spec creation.

### Step 2: Scan Routes

Locate route definitions based on framework patterns documented in `references/rust-framework-patterns.md`.

For each route, extract:
- HTTP method (GET, POST, PUT, DELETE, PATCH)
- URL path (including path parameters like `/:id` or `/<id>`)
- Handler function name and location

Build a route inventory as a working list before proceeding.

### Step 3: Scan Types

For each handler function found in Step 2, trace the request and response types:

1. Read the handler function signature
2. Identify extractor types (`Query<T>`, `Json<T>`, `Path<T>`, etc.)
3. Follow each `T` to its struct/enum definition
4. Read the struct fields, noting `serde` attributes (`rename`, `skip_serializing_if`, `default`, `flatten`, `tag`)
5. Map Rust types to OpenAPI types using the mapping table in `references/rust-framework-patterns.md`

Skip internal types (`State<T>`, `Extension<T>`, middleware extractors).

### Step 4: Detect Response Pattern

Check whether the project uses a unified response wrapper:

1. Search for generic response structs like `ApiResponse<T>`, `Response<T>`, `AppResult<T>`
2. If found, extract it as a common schema in `components/schemas/common/`
3. If not found, document each endpoint's response type individually

### Step 5: Detect WebSocket Endpoints

Search for WebSocket-related patterns:

- Axum: `WebSocketUpgrade` extractor, `ws.on_upgrade()`
- Actix-web: `actix_web_actors::ws`, `StreamHandler<ws::Message>`
- Rocket: `ws::WebSocket` type

For each WebSocket endpoint:
1. Find the message types used with `serde_json::from_str` / `serde_json::to_string`
2. Trace to the enum/struct definitions
3. Note the serde tag representation (internally tagged, adjacently tagged, untagged, externally tagged)

### Step 6: Create Directory Structure

Copy the template from this skill's `assets/openapi-template/` to the project's `openapi/` directory, then customize:

1. Update `openapi.yaml` with project title and description (read from `Cargo.toml` `[package]` section)
2. Create domain folders based on route path prefixes
3. If the project has a unified error response, update `components/schemas/common/ErrorResponse.yaml` to match

### Step 7: Generate Schema Files

For each unique request/response type:

1. Create a YAML file in `openapi/domains/{domain}/schemas/{TypeName}.yaml`
2. Map struct fields to OpenAPI properties
3. Set `required` array based on which fields are not `Option<T>`
4. Handle nested types by creating separate schema files and using `$ref`
5. For enums, use `enum` for simple variants or `oneOf` for complex variants

### Step 8: Generate Path Files

For each route:

1. Create a YAML file in `openapi/domains/{domain}/paths/{endpoint-name}.yaml`
2. Include: summary, description, tags, parameters, request body (if POST/PUT/PATCH), responses
3. Reference schema files via `$ref`
4. Add at least one response example with realistic data
5. Follow conventions in `references/openapi-conventions.md`

### Step 9: Generate AsyncAPI (if WebSocket found)

If WebSocket endpoints were found in Step 5:

1. Create `openapi/asyncapi.yaml` with channel and operation definitions
2. Create message schema files in `openapi/domains/{domain}/schemas/` (shared with OpenAPI schemas)
3. Map serde-tagged enums to `oneOf` with `discriminator` as documented in `references/rust-framework-patterns.md`
4. Define both `send` (client-to-server) and `receive` (server-to-client) operations

### Step 10: Register in Entry Files

Update `openapi/openapi.yaml`:
- Add all schema `$ref` entries under `components.schemas`
- Add all path `$ref` entries under `paths`
- Add security schemes if authentication is detected

If `asyncapi.yaml` was created, register all message schemas in its `components` section.

### Step 11: Validate

1. Verify all `$ref` paths resolve to existing files
2. Check that every route found in Step 2 has a corresponding path file
3. Confirm response examples match schema structure
4. If Redocly is available in the project (`@redocly/cli` in dependencies), run `pnpm redocly lint openapi/openapi.yaml`

## Sync Mode

### Step 1: Load Existing Spec

Read the existing `openapi/openapi.yaml` to build a list of currently documented endpoints and schemas.

### Step 2: Scan Current Code

Follow Generate Mode Steps 1-5 to build the current route and type inventory from source code.

### Step 3: Diff

Compare documented vs actual endpoints:

| Status | Condition |
|--------|-----------|
| **New** | Route exists in code but not in spec |
| **Removed** | Route exists in spec but not in code |
| **Modified** | Route exists in both but types differ (new/removed fields, type changes) |
| **Unchanged** | Route and types match |

### Step 4: Report

Present the diff to the user in a clear table format before making changes. Include:
- New endpoints to add
- Removed endpoints to delete
- Modified endpoints with specific field-level changes
- Unchanged endpoints (count only)

### Step 5: Apply

After user confirmation:
- For **new** endpoints: follow Generate Mode Steps 7-10
- For **removed** endpoints: delete the path and orphaned schema files, remove entries from `openapi.yaml`
- For **modified** endpoints: update the affected schema and path files in place

## References

- `references/rust-framework-patterns.md` — Framework detection, route scanning patterns, type mapping, WebSocket identification, serde tag handling
- `references/openapi-conventions.md` — Directory structure, file templates, naming conventions, AsyncAPI format, bundling tools, validation checklist

## Assets

- `assets/openapi-template/` — Minimal starter template for `openapi/` directory initialization
