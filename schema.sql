-- Run this ONCE in Supabase: SQL Editor > New query > paste > Run.
-- 1) Put Jasmine's login email between the quotes on the next line first.
create function is_owner() returns boolean language sql stable as
$$ select coalesce(auth.jwt()->>'email','') = 'jasminereadsofficial@gmail.com' $$;

create table books (
  id uuid primary key default gen_random_uuid(),
  title text not null, author text, genre text,
  rating int check (rating between 1 and 5),
  review text, description text, cover_url text,
  created_at timestamptz default now()
);
create table reviews (
  id uuid primary key default gen_random_uuid(),
  book_id uuid references books(id) on delete cascade,
  name text not null check (char_length(name) <= 40),
  rating int check (rating between 1 and 5),
  body text not null check (char_length(body) <= 800),
  approved boolean not null default false,
  created_at timestamptz default now()
);
alter table books enable row level security;
alter table reviews enable row level security;

create policy "anyone reads books" on books for select using (true);
create policy "jasmine manages books" on books for all using (is_owner()) with check (is_owner());
create policy "anyone reads approved reviews" on reviews for select using (approved = true);
create policy "anyone submits pending reviews" on reviews for insert with check (approved = false);
create policy "jasmine manages reviews" on reviews for all using (is_owner()) with check (is_owner());

insert into storage.buckets (id, name, public) values ('covers', 'covers', true);
create policy "anyone views covers" on storage.objects for select using (bucket_id = 'covers');
create policy "jasmine uploads covers" on storage.objects for insert with check (bucket_id = 'covers' and is_owner());
create policy "jasmine deletes covers" on storage.objects for delete using (bucket_id = 'covers' and is_owner());
