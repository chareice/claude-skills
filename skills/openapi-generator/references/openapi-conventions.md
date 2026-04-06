# OpenAPI & AsyncAPI Conventions

Conventions for generating API documentation, derived from production projects.

## OpenAPI (REST endpoints)

### Version & Format

- OpenAPI 3.0.3
- YAML format
- Split-file organization under `openapi/` directory

### Directory Structure

```
openapi/
├── openapi.yaml                    # Main entry point
├── components/
│   ├── parameters/                 # Reusable query/path parameters
│   │   └── {paramName}.yaml
│   └── schemas/
│       └── common/                 # Cross-domain shared schemas
│           └── {SchemaName}.yaml
└── domains/
    └── {domain-name}/              # One folder per API domain
        ├── paths/
        │   └── {endpoint}.yaml     # Path definitions
        └── schemas/
            └── {SchemaName}.yaml   # Domain-specific schemas
```

### Domain Organization

Group endpoints by URL path prefix into domains:

- `/api/users/*` -> `domains/users/`
- `/api/orders/*` -> `domains/orders/`
- `/api/auth/*` -> `domains/auth/`

If an endpoint has no clear domain prefix, group by business function.

### Entry File (openapi.yaml)

```yaml
openapi: 3.0.3
info:
  title: Project API
  description: API description
  version: 1.0.0

servers:
  - url: /api
    description: API Server

components:
  schemas:
    # Register all schemas with $ref
    User:
      $ref: "./domains/users/schemas/User.yaml"

  parameters:
    # Register reusable parameters
    pageSize:
      $ref: "./components/parameters/pageSize.yaml"

paths:
  /users:
    $ref: "./domains/users/paths/list.yaml"
  /users/{id}:
    $ref: "./domains/users/paths/detail.yaml"
```

### Path File Template

```yaml
get:
  summary: Short description of the endpoint
  description: |
    Detailed description. Include:
    - What the endpoint does
    - Important behavior notes
    - Pagination details if applicable
  tags: [DomainName]
  parameters:
    - name: paramName
      in: query
      required: true
      schema:
        type: string
      description: Parameter description
  responses:
    "200":
      description: Success
      content:
        application/json:
          schema:
            # Reference response schema
            $ref: "../schemas/ResponseType.yaml"
          examples:
            sample:
              value:
                # Concrete example
                id: 1
                name: "Example"
    "400":
      description: Bad request
    "401":
      description: Unauthorized
    "500":
      description: Internal server error
```

### Schema File Template

```yaml
type: object
description: Brief description
properties:
  id:
    type: integer
    format: int64
    description: Unique identifier
  name:
    type: string
    description: Display name
  email:
    type: string
    format: email
  status:
    type: string
    enum: [active, inactive, suspended]
  createdAt:
    type: string
    format: date-time
required: [id, name, email]
```

### Conventions

1. **$ref paths** - Always use relative paths from the referencing file
2. **Naming** - Schema files use PascalCase (`UserProfile.yaml`), path files use kebab-case (`user-list.yaml`)
3. **Description language** - Follow project language; default to Chinese for Chinese-speaking teams
4. **Examples** - Include at least one `examples` block per endpoint with realistic data
5. **Tags** - One tag per domain, matching the domain folder name in PascalCase
6. **Required fields** - Always specify `required` arrays on object schemas
7. **Nullable** - Use `nullable: true` for optional fields that can be null (maps from Rust `Option<T>`)

### Common Parameter Patterns

**Pagination (cursor-based):**
```yaml
- name: limit
  in: query
  schema:
    type: integer
    default: 20
    maximum: 100
- name: cursor
  in: query
  schema:
    type: string
  description: Opaque cursor for next page
```

**Pagination (offset-based):**
```yaml
- name: page
  in: query
  schema:
    type: integer
    default: 1
    minimum: 1
- name: pageSize
  in: query
  schema:
    type: integer
    default: 20
    maximum: 100
```

**Date range:**
```yaml
- name: startDate
  in: query
  schema:
    type: string
    format: date
- name: endDate
  in: query
  schema:
    type: string
    format: date
```

### Security Schemes

Only include if the project uses authentication. Common patterns:

```yaml
components:
  securitySchemes:
    BearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT
    ApiKeyAuth:
      type: apiKey
      in: header
      name: X-API-Key
```

## AsyncAPI (WebSocket endpoints)

### Version & Format

- AsyncAPI 3.0.0
- YAML format
- Placed alongside OpenAPI: `openapi/asyncapi.yaml`

### Entry File (asyncapi.yaml)

```yaml
asyncapi: 3.0.0
info:
  title: Project WebSocket API
  version: 1.0.0
  description: WebSocket API description

servers:
  production:
    host: example.com
    protocol: wss
    description: Production WebSocket server

channels:
  chat:
    address: /ws/chat
    description: Real-time chat channel
    messages:
      clientMessage:
        $ref: "#/components/messages/ClientMessage"
      serverMessage:
        $ref: "#/components/messages/ServerMessage"

operations:
  sendMessage:
    action: send
    channel:
      $ref: "#/channels/chat"
    messages:
      - $ref: "#/channels/chat/messages/clientMessage"
  receiveMessage:
    action: receive
    channel:
      $ref: "#/channels/chat"
    messages:
      - $ref: "#/channels/chat/messages/serverMessage"

components:
  messages:
    ClientMessage:
      payload:
        $ref: "./domains/chat/schemas/ClientMessage.yaml"
    ServerMessage:
      payload:
        $ref: "./domains/chat/schemas/ServerMessage.yaml"
```

### WebSocket Message Schema

For Rust tagged enums, use `oneOf` with discriminator:

```yaml
# domains/chat/schemas/ClientMessage.yaml
oneOf:
  - type: object
    properties:
      type:
        type: string
        enum: [subscribe]
      data:
        type: object
        properties:
          channel:
            type: string
        required: [channel]
    required: [type, data]
  - type: object
    properties:
      type:
        type: string
        enum: [send_message]
      data:
        type: object
        properties:
          channel:
            type: string
          text:
            type: string
        required: [channel, text]
    required: [type, data]
discriminator: type
```

### Mapping Serde Tags to AsyncAPI

Refer to `rust-framework-patterns.md` for serde tag representation mappings. The key is to match the JSON wire format, not the Rust source structure.

### When to Use AsyncAPI vs OpenAPI

| Pattern | Use |
|---------|-----|
| HTTP REST endpoint | OpenAPI |
| WebSocket upgrade endpoint (the HTTP GET) | OpenAPI (note: "Upgrades to WebSocket") |
| WebSocket message formats | AsyncAPI |
| Server-Sent Events | OpenAPI (with `text/event-stream` content type) |

## Bundling

### Redocly (for OpenAPI)

```bash
# Install
pnpm add -D @redocly/cli

# Bundle split files into single file
pnpm redocly bundle openapi/openapi.yaml -o public/openapi.yaml

# Lint
pnpm redocly lint openapi/openapi.yaml
```

### AsyncAPI CLI

```bash
# Install
pnpm add -D @asyncapi/cli

# Validate
pnpm asyncapi validate openapi/asyncapi.yaml

# Bundle
pnpm asyncapi bundle openapi/asyncapi.yaml -o public/asyncapi.yaml
```

## Validation Checklist

Before completing documentation generation:

1. All `$ref` paths resolve correctly
2. All registered schemas in entry file have corresponding files
3. All paths in entry file have corresponding files
4. Required fields are specified on all object schemas
5. Response examples match the defined schema structure
6. HTTP methods match the actual route definitions
7. Parameter names and types match the Rust handler signatures
8. WebSocket message schemas match the serde serialization format
