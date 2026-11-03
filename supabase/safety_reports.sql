-- Run in the LOST Supabase project's SQL Editor before releasing the updated app.
-- Reports are write-only to mobile users; moderators review them in the dashboard.
create table if not exists public.safety_reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references auth.users(id) on delete cascade,
  find_id uuid references public.finds(id) on delete set null,
  category text not null check (category in ('child_safety','abuse','spam','other')),
  details text not null check (char_length(trim(details)) between 10 and 2000),
  created_at timestamptz not null default now(),
  status text not null default 'new' check (status in ('new','reviewing','resolved'))
);
create index if not exists safety_reports_created_idx on public.safety_reports(created_at desc);
alter table public.safety_reports enable row level security;
revoke all on public.safety_reports from anon, authenticated;
grant insert on public.safety_reports to authenticated;
create policy "reporters can submit" on public.safety_reports
  for insert to authenticated
  with check (reporter_id = (select auth.uid()));
-- No SELECT/UPDATE/DELETE grants or policies for app users.
-- Authorized project administrators can review reports through Supabase dashboard.
