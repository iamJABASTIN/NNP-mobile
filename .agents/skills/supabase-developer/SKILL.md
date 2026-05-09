---
name: developing-with-supabase
description: Acts as an expert Supabase engineer to design scalable schemas, enforce RLS security, and implement high-performance backends using Postgres, Auth, Storage, Edge Functions, and Realtime.
---

# Supabase Engineering

## When to use this skill
- When designing or modifying database schemas (Postgres).
- When implementing Row Level Security (RLS) policies.
- When integrating Supabase Auth, Storage, or Realtime.
- When writing or deploying Edge Functions.
- When optimizing SQL queries or database performance.
- When managing database migrations.
- **When you need to interact with a Supabase project via MCP (migrations, logs, docs).**

## Supabase MCP Tools
Leverage the `supabase-mcp-server` tools to interact with the project:
- **`search_docs`**: ALWAYS use this to find the latest documentation on Supabase features, especially for Edge Functions, Auth, and Realtime.
- **`list_tables` / `list_migrations`**: Use these to understand the current database state before making changes.
- **`get_project` / `get_publishable_keys`**: Retrieve project configuration and keys.
- **`apply_migration`**: The PRIMARY method for applying schema changes. Do not just `execute_sql` for DDL; use migrations.
- **`execute_sql`**: Use for ad-hoc queries, data inspection, or checking system state (e.g., `pg_indexes`).
- **`get_logs`**: Essential for debugging Auth issues, Database errors, or Edge Function execution failures.
- **`deploy_edge_function` / `get_edge_function`**: Manage Edge Functions directly.

## Workflow
1.  **Discovery**:
    - Use `search_docs` if you are unsure about a specific feature implementation.
    - Use `list_tables` and `get_project` to orient yourself in the existing project structure.
2.  **Analyze Requirements**: Understand the data model, security needs, and performance constraints.
3.  **Schema Design**: Create normalized, scalable schemas.
    - Draft your SQL.
    - **Action**: Use `apply_migration` to apply changes. avoiding direct `execute_sql` for schema definitions to ensure reproducibility.
4.  **Security First**: Define RLS policies immediately.
    - **Action**: Verify active policies by querying `pg_policies` via `execute_sql`.
5.  **Implementation**: Write clean, reusable code for Auth, Storage, and Edge Functions.
    - **Action**: Deploy functions using `deploy_edge_function`.
6.  **Debugging & Optimization**:
    - **Action**: Check `get_logs` if things aren't working as expected.
    - **Action**: Use `execute_sql` with `EXPLAIN ANALYZE` to check query performance.

## Instructions

### 1. Schema Design & Postgres
- **Normalization**: Aim for 3NF. Use Foreign Keys to enforce integrity.
- **JSONB**: Use `JSONB` for flexible, unstructured data, but efficient querying requires GIN indexes.
- **Extensions**: Leverage Postgres extensions (e.g., `pg_trgm` for search, `postgis` for geo).
- **Naming**: Use `snake_case` for all database objects.
- **Tool Tip**: Use `list_tables` to see existing relations and `execute_sql` to inspect constraints if unsure.

### 2. Row Level Security (RLS)
- **Enable RLS**: `ALTER TABLE table_name ENABLE ROW LEVEL SECURITY;`
- **Policies**: Create specific policies for `SELECT`, `INSERT`, `UPDATE`, `DELETE`.
- **Auth**: Use `auth.uid()` to restrict access to user data.
- **Example**:
  ```sql
  CREATE POLICY "Users can view their own data" ON user_data
  FOR SELECT USING (auth.uid() = user_id);
  ```
- **Tool Tip**: After applying policies, you can verify they exist by querying `pg_policies`.

### 3. Edge Functions
- **Use Cases**: Webhooks, payment processing, complex business logic, or third-party API integrations.
- **Security**: Always verify the JWT. Use `serve` from `std/http` or Supabase frameworks.
- **Environment**: Store secrets in Supabase Dashboard (or `.env` locally), verify access via `Deno.env.get()`.
- **Deployment**: Use `deploy_edge_function` to push changes. Use `get_logs` (service: `edge-function`) to debug.

### 4. Supabase Auth
- **Triggers**: Use database triggers to handle user creation (e.g., creating a `public.profiles` row when a user signs up).
- **Validation**: Validate user input on both client and server.
- **Debugging**: Use `get_logs` (service: `auth`) to troubleshoot login/signup failures.

### 5. Performance
- **Indexing**: B-tree for equality/range, GIN for JSONB/Arrays.
- **Explain Analyze**: Use `EXPLAIN ANALYZE` to debug slow queries via `execute_sql`.
- **Connection**: Use connection pooling (PgBouncer/Supavisor) for serverless connections.

### 6. Migrations
- **Version Control**: Store all SQL changes in migration files.
- **Execution**: Use `apply_migration` tool to apply these changes to the remote database safely.
- **Idempotency**: Ensure migrations can be run multiple times without failure (e.g., `IF NOT EXISTS`).

## Best Practices Checklist
- [ ] RLS enabled on all tables?
- [ ] Indexes added for frequently queried columns?
- [ ] Foreign keys enforced?
- [ ] Secrets managed securely?
- [ ] SQL functions used for complex transactional logic?
- [ ] **Did you check `get_logs` for any silent errors?**
- [ ] **Did you use `apply_migration` instead of raw SQL for schema changes?**
