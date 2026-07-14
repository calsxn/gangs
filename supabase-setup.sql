-- Gang Registry — Supabase setup
-- Run this whole file in Supabase: SQL Editor > New query > paste > Run

create extension if not exists pgcrypto;

create table gangs (
  id text primary key,
  name text not null,
  tag text not null,
  turf text,
  color text,
  motto text,
  founded text
);

create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique not null,
  login_email text not null,
  display_name text,
  gang_id text references gangs(id) on delete set null,
  is_admin boolean not null default false,
  created_at timestamptz default now()
);

create table roster (
  id uuid primary key default gen_random_uuid(),
  gang_id text references gangs(id) on delete cascade,
  name text not null,
  alias text,
  rank text,
  discord text,
  status text,
  joined date,
  notes text,
  created_at timestamptz default now()
);

alter table gangs enable row level security;
alter table profiles enable row level security;
alter table roster enable row level security;

-- Anyone can read the gang list; only admins can add/edit/delete gangs
create policy "gangs read" on gangs for select using (true);
create policy "gangs admin write" on gangs for all using (
  exists (select 1 from profiles where id = auth.uid() and is_admin = true)
) with check (
  exists (select 1 from profiles where id = auth.uid() and is_admin = true)
);

-- Anyone can read profiles (needed to show names and look up logins);
-- people can only create/edit their own profile, admins can edit any
create policy "profiles read" on profiles for select using (true);
create policy "profiles self insert" on profiles for insert with check (auth.uid() = id);
create policy "profiles self or admin update" on profiles for update using (
  auth.uid() = id or exists (select 1 from profiles p where p.id = auth.uid() and p.is_admin = true)
) with check (
  auth.uid() = id or exists (select 1 from profiles p where p.id = auth.uid() and p.is_admin = true)
);
create policy "profiles admin delete" on profiles for delete using (
  exists (select 1 from profiles p where p.id = auth.uid() and p.is_admin = true)
);

-- Only a gang's own members (or an admin) can read or edit its roster
create policy "roster own gang or admin" on roster for all using (
  exists (select 1 from profiles where id = auth.uid() and (is_admin = true or gang_id = roster.gang_id))
) with check (
  exists (select 1 from profiles where id = auth.uid() and (is_admin = true or gang_id = roster.gang_id))
);

insert into gangs (id, name, tag, turf, color, motto, founded) values
('ashcroft-kings','Ashcroft Kings','ASHK','Ashcroft Heights','#FFB020','Crowned by the block.','2019'),
('nightline-syndicate','Nightline Syndicate','NTLN','Harbor District','#4FD6C4','We move after dark.','2021'),
('red-talon-crew','Red Talon Crew','RTLN','East Ridge','#FF5C5C','One claw, one crew.','2017'),
('vantage-point-boys','Vantage Point Boys','VNTG','Vantage Hills','#4E8CFF','View from the top.','2020'),
('grey-wolves-mc','Grey Wolves MC','GRWL','Route 9 Corridor','#9AA3B2','Ride together, ride forever.','2015'),
('emerald-row','Emerald Row','EMRD','Emerald Row','#4CD97B','Green never fades.','2018'),
('black-iron-outfit','Black Iron Outfit','BKIR','Ironworks District','#D4A93C','Forged, not born.','2016'),
('violet-rain','Violet Rain','VLTR','Rainier Court','#B06CFF','Storm always comes.','2022'),
('sundown-cartel','Sundown Cartel','SNDN','Sundown Strip','#FF8A3D','Business at sundown.','2014'),
('the-wraiths','The Wraiths','WRTH','Old Town','#E7E9EE','Gone before you blink.','2023');
