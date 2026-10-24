-- CodeLoo schema for Supabase. Run in SQL Editor (Dashboard > SQL Editor > New query).
-- Anonymous users may SELECT and INSERT only. No UPDATE/DELETE policies => denied by RLS.

create table if not exists public.places (
  id bigint generated always as identity primary key,
  name text not null check (char_length(name) between 1 and 120),
  address text default '' check (char_length(address) <= 200),
  lat double precision not null check (lat between -90 and 90),
  lng double precision not null check (lng between -180 and 180),
  notes text default '' check (char_length(notes) <= 300),
  created_at timestamptz not null default now()
);

create table if not exists public.codes (
  id bigint generated always as identity primary key,
  place_id bigint not null references public.places(id) on delete cascade,
  code text not null check (char_length(code) between 1 and 40),
  created_at timestamptz not null default now()
);

create table if not exists public.votes (
  id bigint generated always as identity primary key,
  code_id bigint not null references public.codes(id) on delete cascade,
  up boolean not null,
  created_at timestamptz not null default now()
);

create index if not exists codes_place_idx on public.codes(place_id);
create index if not exists votes_code_idx on public.votes(code_id);

alter table public.places enable row level security;
alter table public.codes  enable row level security;
alter table public.votes  enable row level security;

drop policy if exists "anon read places" on public.places;
drop policy if exists "anon insert places" on public.places;
drop policy if exists "anon read codes" on public.codes;
drop policy if exists "anon insert codes" on public.codes;
drop policy if exists "anon read votes" on public.votes;
drop policy if exists "anon insert votes" on public.votes;
create policy "anon read places"   on public.places for select to anon, authenticated using (true);
create policy "anon insert places" on public.places for insert to anon, authenticated with check (true);
create policy "anon read codes"    on public.codes  for select to anon, authenticated using (true);
create policy "anon insert codes"  on public.codes  for insert to anon, authenticated with check (true);
create policy "anon read votes"    on public.votes  for select to anon, authenticated using (true);
create policy "anon insert votes"  on public.votes  for insert to anon, authenticated with check (true);

-- Explicit grants (only select/insert for anon; no update/delete).
revoke all on public.places, public.codes, public.votes from anon;
grant select, insert on public.places, public.codes, public.votes to anon, authenticated;

-- Vote counts per code (security_invoker so RLS of the caller applies).
create or replace view public.code_stats with (security_invoker = true) as
select c.id as code_id, c.place_id, c.code, c.created_at,
       count(v.*) filter (where v.up)     as up,
       count(v.*) filter (where not v.up) as down,
       max(v.created_at) filter (where v.up) as last_up
from public.codes c left join public.votes v on v.code_id = c.id
group by c.id;
grant select on public.code_stats to anon, authenticated;

-- EXAMPLE seed data: fake codes, not real. Safe to delete.
do $$
declare p bigint; c bigint;
begin
  if not exists (select 1 from public.places where name like 'EXAMPLE%') then
    insert into public.places(name,address,lat,lng,notes) values ('EXAMPLE – Coffee Shop (demo)','Market St, San Francisco',37.7897,-122.4011,'Demo entry, not a real code.') returning id into p;
    insert into public.codes(place_id,code) values (p,'1234 (EXAMPLE)') returning id into c;
    insert into public.votes(code_id,up) values (c,true),(c,true),(c,false);
    insert into public.places(name,address,lat,lng,notes) values ('EXAMPLE – Grocery Store (demo)','Mission St, San Francisco',37.7599,-122.4148,'Demo entry. Ask cashier.') returning id into p;
    insert into public.codes(place_id,code) values (p,'#5678 (EXAMPLE)') returning id into c;
    insert into public.votes(code_id,up) values (c,true);
    insert into public.places(name,address,lat,lng,notes) values ('EXAMPLE – Bookstore (demo)','Valencia St, San Francisco',37.7648,-122.4216,'Demo entry, not real.') returning id into p;
    insert into public.codes(place_id,code) values (p,'0000* (EXAMPLE)');
  end if;
end $$;
