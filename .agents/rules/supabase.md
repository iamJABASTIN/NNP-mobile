---
trigger: always_on
---

# Antigravity — Supabase Production Rules

> These rules are enforced for every agent interaction that reads from, writes to, or configures Supabase. No exceptions.

---

## 1. Client Initialisation

### 1.1 One Client Per Context — Never Re-Initialise
```ts
// lib/supabase/client.ts  — Browser (CSR)
import { createBrowserClient } from '@supabase/ssr';
import type { Database } from '@/types/supabase';

export function createClient() {
  return createBrowserClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  );
}
```

```ts
// lib/supabase/server.ts  — Server Components / Route Handlers
import { createServerClient } from '@supabase/ssr';
import { cookies } from 'next/headers';
import type { Database } from '@/types/supabase';

export function createServerSupabaseClient() {
  const cookieStore = cookies();
  return createServerClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        get:    (name) => cookieStore.get(name)?.value,
        set:    (name, value, options) => cookieStore.set({ name, value, ...options }),
        remove: (name, options) => cookieStore.set({ name, value: '', ...options }),
      },
    }
  );
}
```

```ts
// lib/supabase/admin.ts  — Server-only privileged operations
import { createClient } from '@supabase/supabase-js';
import type { Database } from '@/types/supabase';

// NEVER expose this client to the browser — server modules only
export const supabaseAdmin = createClient<Database>(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!,
  { auth: { autoRefreshToken: false, persistSession: false } }
);
```

### 1.2 Environment Variable Rules
| Variable | Exposed to browser | Usage |
|----------|--------------------|-------|
| `NEXT_PUBLIC_SUPABASE_URL` | ✅ Yes | All clients |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | ✅ Yes | Browser / SSR anon |
| `SUPABASE_SERVICE_ROLE_KEY` | ❌ Never | Admin server only |

`SUPABASE_SERVICE_ROLE_KEY` must **never** appear in a file that is imported by client-side code.

---

## 2. Type Safety

### 2.1 Generated Types Are Mandatory
The `Database` type must always be generated from the live schema and committed alongside migrations:
```bash
npx supabase gen types typescript --project-id <id> --schema public > src/types/supabase.ts
```

Regenerate after every migration. No query may be written without the generated types available.

### 2.2 Always Pass the Database Generic
```ts
// ❌
const supabase = createBrowserClient(url, key);

// ✅
const supabase = createBrowserClient<Database>(url, key);
```

### 2.3 Type the Query Result
```ts
import type { Tables } from '@/types/supabase';

type Post = Tables<'posts'>;

const { data, error } = await supabase.from('posts').select('*');
// data is Post[] | null — fully typed
```

---

## 3. Query Rules

### 3.1 Always Select Only the Columns You Need
```ts
// ❌  Fetches every column — over-fetches, breaks column rename safety
supabase.from('users').select('*')

// ✅
supabase.from('users').select('id, display_name, avatar_url, created_at')
```

### 3.2 Always Handle Both `data` and `error`
```ts
// ❌ — ignores errors
const { data } = await supabase.from('posts').select('id, title');

// ✅
const { data, error } = await supabase.from('posts').select('id, title');
if (error) throw new Error(`posts fetch failed: ${error.message}`);
```

### 3.3 Paginate All List Queries
```ts
const PAGE_SIZE = 20;

const { data, error, count } = await supabase
  .from('posts')
  .select('id, title, created_at', { count: 'exact' })
  .order('created_at', { ascending: false })
  .range(page * PAGE_SIZE, (page + 1) * PAGE_SIZE - 1);
```

Never fetch an unbounded list — always use `.range()` or `.limit()`.

### 3.4 Use Typed RPC Calls for Complex Queries
Prefer database functions over multi-step client-side queries:
```ts
const { data, error } = await supabase.rpc('get_user_feed', {
  p_user_id: userId,
  p_limit:   20,
  p_offset:  0,
});
```

### 3.5 Foreign Table Joins — Explicit, Not Implicit
```ts
// ✅
const { data } = await supabase
  .from('posts')
  .select(`
    id,
    title,
    author:users ( id, display_name, avatar_url )
  `);
```

---

## 4. Mutations

### 4.1 Optimistic Updates with Rollback
Use TanStack Query mutations — never mutate server state without a rollback plan:
```ts
const mutation = useMutation({
  mutationFn: (newPost: InsertPost) =>
    supabase.from('posts').insert(newPost).throwOnError(),
  onMutate: async (newPost) => {
    await queryClient.cancelQueries({ queryKey: ['posts'] });
    const previous = queryClient.getQueryData(['posts']);
    queryClient.setQueryData(['posts'], (old: Post[]) => [newPost, ...old]);
    return { previous };
  },
  onError: (_err, _vars, context) => {
    queryClient.setQueryData(['posts'], context?.previous);
  },
  onSettled: () => queryClient.invalidateQueries({ queryKey: ['posts'] }),
});
```

### 4.2 Upsert Over Double-Write
```ts
// ❌  Two round-trips, race-condition-prone
await supabase.from('profiles').insert(data);
// … later …
await supabase.from('profiles').update(data).eq('id', userId);

// ✅
await supabase
  .from('profiles')
  .upsert(data, { onConflict: 'id' })
  .throwOnError();
```

### 4.3 Batch Inserts — Never Loop
```ts
// ❌
for (const item of items) {
  await supabase.from('tags').insert(item);
}

// ✅
await supabase.from('tags').insert(items).throwOnError();
```

---

## 5. Authentication

### 5.1 Session Validation Is Server-Side
Never trust the client-side session alone for protected operations:
```ts
// app/api/protected/route.ts
export async function GET() {
  const supabase = createServerSupabaseClient();
  const { data: { session } } = await supabase.auth.getSession();

  if (!session) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }
  // … proceed
}
```

### 5.2 Middleware Refreshes the Session
```ts
// middleware.ts
import { createServerClient } from '@supabase/ssr';
import { NextResponse, type NextRequest } from 'next/server';

export async function middleware(request: NextRequest) {
  const response = NextResponse.next({ request });
  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    { cookies: { /* … get/set/remove using request & response … */ } }
  );
  await supabase.auth.getUser(); // Refreshes expiring tokens
  return response;
}
```

### 5.3 Always Use `getUser()` for Server-Side Identity
```ts
// ❌  getSession() can be spoofed from the client
const { data: { session } } = await supabase.auth.getSession();
const userId = session?.user.id;

// ✅  getUser() validates the JWT against the Supabase server
const { data: { user }, error } = await supabase.auth.getUser();
if (error || !user) return unauthorized();
```

---

## 6. Row Level Security (RLS)

### 6.1 RLS Is Always Enabled — No Exceptions
Every table in the public schema must have RLS enabled:
```sql
ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;
```

Tables with RLS enabled but **no policies** are fully locked down (no reads or writes). Add explicit policies.

### 6.2 Policy Template
```sql
-- Read own rows
CREATE POLICY "Users can read their own posts"
  ON public.posts FOR SELECT
  USING (auth.uid() = user_id);

-- Insert as self
CREATE POLICY "Users can insert their own posts"
  ON public.posts FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Update own rows
CREATE POLICY "Users can update their own posts"
  ON public.posts FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Delete own rows
CREATE POLICY "Users can delete their own posts"
  ON public.posts FOR DELETE
  USING (auth.uid() = user_id);
```

### 6.3 Never Rely Solely on Application Logic for Access Control
Business logic checks in the service layer are a **second layer** — not a replacement for RLS policies.

### 6.4 Audit Sensitive Tables
Tables containing PII or financial data must have audit logging via a trigger:
```sql
CREATE TRIGGER audit_payments
  AFTER INSERT OR UPDATE OR DELETE ON public.payments
  FOR EACH ROW EXECUTE FUNCTION audit.log_changes();
```

---

## 7. Storage

### 7.1 Buckets and Policies
```ts
// ✅ Upload to user-scoped path — enforced by bucket policy
const filePath = `${userId}/${crypto.randomUUID()}.${ext}`;
const { error } = await supabase.storage
  .from('avatars')
  .upload(filePath, file, { cacheControl: '3600', upsert: false });
```

Storage bucket policies must mirror RLS — users may only read/write within their own folder:
```sql
CREATE POLICY "User folder access"
  ON storage.objects FOR ALL
  USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);
```

### 7.2 Generate Signed URLs for Private Assets
```ts
// ❌  Public URL for a private bucket
supabase.storage.from('private-docs').getPublicUrl(path);

// ✅
const { data } = await supabase.storage
  .from('private-docs')
  .createSignedUrl(path, 3600); // 1 hour TTL
```

---

## 8. Realtime

### 8.1 Always Unsubscribe on Unmount
```ts
useEffect(() => {
  const channel = supabase
    .channel('posts')
    .on('postgres_changes', { event: '*', schema: 'public', table: 'posts' }, handleChange)
    .subscribe();

  return () => { supabase.removeChannel(channel); };
}, []);
```

### 8.2 Filter at the Subscription Level
```ts
// ❌ Subscribe to entire table, filter in JS
.on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'messages' }, ...)

// ✅ Push only what this user needs
.on('postgres_changes', {
  event:  'INSERT',
  schema: 'public',
  table:  'messages',
  filter: `room_id=eq.${roomId}`,
}, handleInsert)
```

---

## 9. Migrations

### 9.1 Every Schema Change Is a Migration File
Never modify the database schema outside of migration files:
```
supabase/migrations/
  20240101000000_create_posts.sql
  20240102000000_add_post_status.sql
```

### 9.2 Migrations Must Be Idempotent
```sql
-- ✅
CREATE TABLE IF NOT EXISTS public.posts ( … );
ALTER TABLE public.posts ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'draft';
```

### 9.3 Never Drop Columns in the Same Migration That Removes Their Usage
1. Deploy code that stops reading the column.  
2. Deploy a migration that removes the column.  
Always two separate deployments to prevent downtime.

---

## 10. Service Layer Pattern

All Supabase calls live in `services/` — never in components or hooks directly:

```ts
// services/posts.service.ts
import { createClient } from '@/lib/supabase/client';
import type { Tables, InsertTables } from '@/types/supabase';

export type Post = Tables<'posts'>;

export async function fetchPosts(page: number): Promise<Post[]> {
  const supabase = createClient();
  const { data, error } = await supabase
    .from('posts')
    .select('id, title, excerpt, created_at, author:users(id, display_name)')
    .order('created_at', { ascending: false })
    .range(page * 20, page * 20 + 19);

  if (error) throw new Error(error.message);
  return data ?? [];
}
```

```ts
// hooks/usePosts.ts  — consumes the service, never calls Supabase directly
import { useQuery } from '@tanstack/react-query';
import { fetchPosts } from '@/services/posts.service';

export function usePosts(page: number) {
  return useQuery({
    queryKey: ['posts', page],
    queryFn:  () => fetchPosts(page),
    staleTime: 60_000,
  });
}
```

---

## 11. Security Checklist

Before any Supabase-related code is merged:

- [ ] RLS is enabled on every new table
- [ ] Policies exist for every operation (SELECT / INSERT / UPDATE / DELETE)
- [ ] `SUPABASE_SERVICE_ROLE_KEY` is only imported in server-only files
- [ ] `getUser()` used instead of `getSession()` for identity on the server
- [ ] No unbounded queries — all lists use `.range()` or `.limit()`
- [ ] Storage bucket policies restrict users to their own paths
- [ ] Realtime subscriptions filter at the DB level
- [ ] Migration files are idempotent
- [ ] Generated types are rege