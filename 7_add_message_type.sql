alter table public.chat_messages 
add column type text default 'text';

-- Create storage bucket for images if not exists
insert into storage.buckets (id, name, public)
values ('chat_images', 'chat_images', true)
on conflict (id) do nothing;

-- Policy to allow authenticated uploads
create policy "Allow authenticated uploads"
on storage.objects for insert
to authenticated
with check (bucket_id = 'chat_images');

create policy "Allow public read"
on storage.objects for select
using (bucket_id = 'chat_images');
