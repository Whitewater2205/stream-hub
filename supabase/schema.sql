-- Run once in the Supabase SQL Editor for the StreamHub project.
create table if not exists public.user_favorites (
  user_id uuid not null references auth.users (id) on delete cascade,
  provider_name text not null,
  created_at timestamptz not null default now(),
  primary key (user_id, provider_name),
  constraint user_favorites_provider_name_check check (
    provider_name in (
      'Netflix', 'Disney+', 'Prime Video', 'YouTube', 'Spotify',
      'WOW', 'RTL+', 'Joyn', 'Paramount+'
    )
  )
);

alter table public.user_favorites enable row level security;

-- The project is configured not to grant table access automatically. Grant
-- only the operations the app needs; row-level security below still limits
-- each operation to the signed-in user's own rows.
grant usage on schema public to authenticated;
grant select, insert, delete on public.user_favorites to authenticated;

create policy "Users can read their own favorites"
  on public.user_favorites for select to authenticated
  using ((select auth.uid()) = user_id);

create policy "Users can add their own favorites"
  on public.user_favorites for insert to authenticated
  with check ((select auth.uid()) = user_id);

create policy "Users can remove their own favorites"
  on public.user_favorites for delete to authenticated
  using ((select auth.uid()) = user_id);
