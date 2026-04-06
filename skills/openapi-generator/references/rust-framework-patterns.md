# Rust Web Framework Patterns

Reference for identifying API routes, request/response types, and WebSocket handlers in Rust web frameworks.

## Framework Detection

Read `Cargo.toml` to identify the framework:

| Framework | Dependency key | Notes |
|-----------|---------------|-------|
| Axum | `axum` | Most common, built on Tower/Hyper |
| Actix-web | `actix-web` | Mature, high performance |
| Rocket | `rocket` | Macro-heavy, developer-friendly |
| Poem | `poem` / `poem-openapi` | Has built-in OpenAPI support |

## Axum

### Route definitions

```rust
// Router-level
let app = Router::new()
    .route("/users", get(list_users).post(create_user))
    .route("/users/:id", get(get_user).put(update_user).delete(delete_user))
    .nest("/api/v1", api_routes());

// With state
Router::new()
    .route("/items", get(list_items))
    .with_state(app_state);
```

**Scan patterns:**
- `Router::new()` chains with `.route(path, method(handler))`
- `.nest(prefix, router)` for nested route groups
- `.merge(router)` for combining routers
- Method extractors: `get()`, `post()`, `put()`, `patch()`, `delete()`

### Handler signatures

```rust
async fn list_users(
    State(db): State<DbPool>,
    Query(params): Query<ListParams>,    // <- query parameters type
) -> Result<Json<Vec<User>>, AppError> { // <- response type
    // ...
}

async fn create_user(
    State(db): State<DbPool>,
    Json(payload): Json<CreateUserRequest>,  // <- request body type
) -> Result<(StatusCode, Json<User>), AppError> {
    // ...
}

async fn get_user(
    Path(id): Path<u64>,                 // <- path parameter
    State(db): State<DbPool>,
) -> Result<Json<User>, AppError> {
    // ...
}
```

**Extract types from:**
- `Query<T>` -> query parameters schema
- `Json<T>` -> request body schema (for POST/PUT/PATCH)
- `Path<T>` -> path parameters (single value or tuple/struct)
- Return type `Json<T>` or `Result<Json<T>, E>` -> response schema
- `State<T>` -> skip (internal state, not API schema)
- `Extension<T>` -> skip (internal)
- `HeaderMap` / `TypedHeader<T>` -> header parameters

### WebSocket handlers

```rust
use axum::extract::ws::{WebSocket, WebSocketUpgrade, Message};

async fn ws_handler(
    ws: WebSocketUpgrade,
    State(state): State<AppState>,
) -> impl IntoResponse {
    ws.on_upgrade(|socket| handle_socket(socket, state))
}

async fn handle_socket(mut socket: WebSocket, state: AppState) {
    while let Some(Ok(msg)) = socket.recv().await {
        match msg {
            Message::Text(text) => {
                let incoming: ClientMessage = serde_json::from_str(&text).unwrap();
                // ...
                let response = ServerMessage::Update { data };
                socket.send(Message::Text(serde_json::to_string(&response).unwrap())).await;
            }
            Message::Binary(data) => { /* ... */ }
            Message::Close(_) => break,
            _ => {}
        }
    }
}
```

**Identify WebSocket by:**
- `WebSocketUpgrade` extractor in handler signature
- `ws.on_upgrade()` call
- Message types used with `serde_json::from_str` / `serde_json::to_string`

## Actix-web

### Route definitions

```rust
// Macro style (preferred)
#[get("/users")]
async fn list_users(db: web::Data<DbPool>) -> impl Responder { }

#[post("/users")]
async fn create_user(body: web::Json<CreateUser>) -> impl Responder { }

#[get("/users/{id}")]
async fn get_user(path: web::Path<u64>) -> impl Responder { }

// Builder style
App::new()
    .service(
        web::resource("/users")
            .route(web::get().to(list_users))
            .route(web::post().to(create_user))
    )
    .service(
        web::scope("/api")
            .service(users_routes)
    );
```

**Scan patterns:**
- `#[get("/path")]`, `#[post("/path")]`, etc. attribute macros
- `web::resource("/path").route(web::get().to(handler))`
- `web::scope("/prefix")` for route groups

### Handler signatures

```rust
async fn list_users(
    db: web::Data<DbPool>,
    query: web::Query<ListParams>,        // <- query params
) -> Result<web::Json<Vec<User>>, Error> { }

async fn create_user(
    body: web::Json<CreateUserRequest>,   // <- request body
) -> Result<web::Json<User>, Error> { }

async fn get_user(
    path: web::Path<(u64,)>,             // <- path params
) -> Result<web::Json<User>, Error> { }
```

**Extract types from:**
- `web::Query<T>` -> query parameters
- `web::Json<T>` -> request/response body
- `web::Path<T>` -> path parameters
- `web::Data<T>` -> skip (app state)

### WebSocket handlers

```rust
use actix_web_actors::ws;

struct MyWs;

impl StreamHandler<Result<ws::Message, ws::ProtocolError>> for MyWs {
    fn handle(&mut self, msg: Result<ws::Message, ws::ProtocolError>, ctx: &mut Self::Context) {
        match msg {
            Ok(ws::Message::Text(text)) => {
                let msg: ClientMessage = serde_json::from_str(&text).unwrap();
                // ...
            }
            // ...
        }
    }
}
```

## Rocket

### Route definitions

```rust
#[get("/users?<page>&<limit>")]
async fn list_users(page: Option<u32>, limit: Option<u32>) -> Json<Vec<User>> { }

#[post("/users", data = "<body>")]
async fn create_user(body: Json<CreateUser>) -> Result<Json<User>, Status> { }

#[get("/users/<id>")]
async fn get_user(id: u64) -> Option<Json<User>> { }

// Mount
rocket::build()
    .mount("/api", routes![list_users, create_user, get_user])
```

**Scan patterns:**
- `#[get("/path")]`, `#[post("/path", data = "<param>")]` attribute macros
- `.mount(prefix, routes![...])` for route mounting
- Query params directly in function signature with `?<param>` in path

## Poem

### Route definitions

```rust
let app = Route::new()
    .at("/users", get(list_users).post(create_user))
    .at("/users/:id", get(get_user))
    .nest("/api", api_routes);
```

### With poem-openapi (already has OpenAPI support)

```rust
#[derive(ApiRequest)]
struct CreateUserRequest {
    #[oai(name = "body", in = "body")]
    body: Json<CreateUser>,
}

#[derive(ApiResponse)]
enum CreateUserResponse {
    #[oai(status = 201)]
    Created(Json<User>),
    #[oai(status = 400)]
    BadRequest(Json<ErrorResponse>),
}
```

If the project uses `poem-openapi`, it likely already generates OpenAPI specs. Check if auto-generation is configured before creating manual specs.

## Common Type Patterns

### Serde-derived structs (all frameworks)

```rust
#[derive(Debug, Serialize, Deserialize)]
struct User {
    id: u64,
    name: String,
    email: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    avatar_url: Option<String>,
    created_at: DateTime<Utc>,
}
```

### Rust type to OpenAPI type mapping

| Rust type | OpenAPI type | OpenAPI format |
|-----------|-------------|----------------|
| `String` | `string` | - |
| `i32` | `integer` | `int32` |
| `i64` | `integer` | `int64` |
| `u32` | `integer` | `int32` (minimum: 0) |
| `u64` | `integer` | `int64` (minimum: 0) |
| `f32` | `number` | `float` |
| `f64` | `number` | `double` |
| `bool` | `boolean` | - |
| `Vec<T>` | `array` (items: T) | - |
| `Option<T>` | T with `nullable: true` | - |
| `HashMap<String, T>` | `object` (additionalProperties: T) | - |
| `DateTime<Utc>` / `NaiveDateTime` | `string` | `date-time` |
| `NaiveDate` | `string` | `date` |
| `Uuid` | `string` | `uuid` |
| `Decimal` | `string` | `decimal` |

### Tagged enums (for WebSocket messages and API variants)

```rust
#[derive(Serialize, Deserialize)]
#[serde(tag = "type", content = "data")]  // adjacently tagged
enum ClientMessage {
    Subscribe { channel: String },
    Unsubscribe { channel: String },
    SendMessage { channel: String, text: String },
}
```

Maps to OpenAPI/AsyncAPI `oneOf` with `discriminator`:

```yaml
oneOf:
  - $ref: "#/components/schemas/SubscribeMessage"
  - $ref: "#/components/schemas/UnsubscribeMessage"
  - $ref: "#/components/schemas/SendMessageMessage"
discriminator:
  propertyName: type
  mapping:
    Subscribe: "#/components/schemas/SubscribeMessage"
    Unsubscribe: "#/components/schemas/UnsubscribeMessage"
    SendMessage: "#/components/schemas/SendMessageMessage"
```

### Serde tag representations

| Serde attribute | OpenAPI representation |
|----------------|----------------------|
| `#[serde(tag = "type")]` (internally tagged) | `oneOf` + `discriminator` on `type` field |
| `#[serde(tag = "type", content = "data")]` (adjacently tagged) | `oneOf` with wrapper objects containing `type` + `data` |
| `#[serde(untagged)]` | `oneOf` without discriminator |
| No tag attribute (externally tagged, default) | `oneOf` with single-key wrapper objects |

### Error response patterns

```rust
// Unified error type
#[derive(Serialize)]
struct AppError {
    code: String,
    message: String,
}

// Or enum-based
#[derive(Serialize)]
#[serde(tag = "error")]
enum ApiError {
    NotFound { message: String },
    Validation { message: String, fields: Vec<String> },
    Internal { message: String },
}
```

### Response wrapper patterns

```rust
// Generic wrapper
#[derive(Serialize)]
struct ApiResponse<T: Serialize> {
    success: bool,
    data: Option<T>,
    error: Option<String>,
}

// Or separate success/error
#[derive(Serialize)]
#[serde(untagged)]
enum Response<T: Serialize> {
    Success { data: T },
    Error { error: AppError },
}
```

When a project uses a wrapper pattern, extract it as a common schema component and reference it across all endpoints.
