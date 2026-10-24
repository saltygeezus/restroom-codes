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

-- Seed data: real codes contributed by the app owner (ZIP 92029 area). Inserted once.
do $$
declare p bigint;
begin
  if not exists (select 1 from public.places) then
    insert into public.places(name,address,lat,lng,notes) values ('Aldi','1352 W Valley Pkwy, Escondido, CA 92029',33.1127791,-117.1039186,'') returning id into p;
    insert into public.codes(place_id,code) values (p,'1352#');
    insert into public.places(name,address,lat,lng,notes) values ('Jimbo''s Naturally','1633 S Centre City Pkwy, Escondido, CA 92025',33.1042504,-117.0775835,'') returning id into p;
    insert into public.codes(place_id,code) values (p,'7755');
    insert into public.places(name,address,lat,lng,notes) values ('Raising Cane''s','1280 W Valley Pkwy, Escondido, CA 92029',33.1148151,-117.1009867,'Code from user note ''SM''') returning id into p;
    insert into public.codes(place_id,code) values (p,'54321');
    insert into public.places(name,address,lat,lng,notes) values ('Wendy''s','1530 W Valley Pkwy, Escondido, CA 92029',33.1096071,-117.1046716,'') returning id into p;
    insert into public.codes(place_id,code) values (p,'5505');
    insert into public.places(name,address,lat,lng,notes) values ('Primos Mexican Food & Cantina','1348 W Valley Pkwy, Escondido, CA 92029',33.112299,-117.102936,'') returning id into p;
    insert into public.codes(place_id,code) values (p,'2805');
    insert into public.places(name,address,lat,lng,notes) values ('Ding Tea','1815 E Valley Pkwy Ste 2, Escondido, CA 92027',33.135699,-117.054732,'') returning id into p;
    insert into public.codes(place_id,code) values (p,'0198');
    insert into public.places(name,address,lat,lng,notes) values ('Epic Wings','1054 W Valley Pkwy, Escondido, CA 92025',33.1166662,-117.0968408,'') returning id into p;
    insert into public.codes(place_id,code) values (p,'1432#');
  end if;
end $$;
