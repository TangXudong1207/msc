-- 1. System Config Table (for dynamic thresholds, etc.)
create table public.system_config (
  key text primary key,
  value text not null,
  description text,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Insert default threshold
insert into public.system_config (key, value, description)
values ('meaning_card_threshold', '0.4', 'Threshold score (0.0-1.0) for generating meaning cards')
on conflict (key) do nothing;

-- 2. API Usage Logs (to track cost)
create table public.api_usage_logs (
  id uuid default gen_random_uuid() primary key,
  provider text not null, -- 'deepseek' or 'vertex'
  tokens_input int default 0,
  tokens_output int default 0,
  model_name text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 3. RLS Policies
alter table public.system_config enable row level security;
alter table public.api_usage_logs enable row level security;

-- Allow everyone to read config (needed for app to know threshold)
create policy "Allow public read config"
on public.system_config for select
using (true);

-- Allow authenticated users (admins) to update config
-- For simplicity in this MVP, we allow any authenticated user to update if they are on the admin screen
-- In production, you'd check for a specific user ID or role
create policy "Allow auth update config"
on public.system_config for update
to authenticated
using (true);

-- Allow insert into usage logs (server/client will insert)
create policy "Allow insert usage logs"
on public.api_usage_logs for insert
to authenticated
with check (true);

create policy "Allow read usage logs"
on public.api_usage_logs for select
to authenticated
using (true);
