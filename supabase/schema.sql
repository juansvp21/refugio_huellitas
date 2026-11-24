-- =====================================================================
-- Refugio Huellitas · Esquema de base de datos para Supabase (PostgreSQL)
-- Ejecutar completo, de una sola vez, en: Supabase > SQL Editor > New query
-- El script es idempotente: se puede volver a ejecutar sin errores.
-- =====================================================================

-- gen_random_uuid() viene de pgcrypto (ya activa en Supabase, por si acaso):
create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------
-- 1. TABLAS
-- ---------------------------------------------------------------------

-- Mascotas del refugio
create table if not exists public.mascotas (
  id                uuid primary key default gen_random_uuid(),
  created_at        timestamptz not null default now(),
  user_id           uuid not null default auth.uid() references auth.users (id) on delete cascade,
  nombre            text not null check (char_length(trim(nombre)) >= 2),
  edad              integer not null check (edad between 0 and 30),
  tipo              text not null check (tipo in ('perro', 'gato', 'ave', 'conejo', 'otro')),
  raza              text not null check (char_length(trim(raza)) >= 2),
  estado_vacunacion text not null default 'no_vacunado'
                    check (estado_vacunacion in ('vacunado', 'no_vacunado', 'parcial')),
  descripcion       text,
  fecha_registro    timestamptz not null default now(),
  estado_adopcion   text not null default 'disponible'
                    check (estado_adopcion in ('disponible', 'en_proceso', 'adoptada'))
);

-- Personas interesadas en adoptar
create table if not exists public.adoptantes (
  id              uuid primary key default gen_random_uuid(),
  created_at      timestamptz not null default now(),
  user_id         uuid not null default auth.uid() references auth.users (id) on delete cascade,
  nombre_completo text not null check (char_length(trim(nombre_completo)) >= 3),
  documento       text not null,
  telefono        text not null,
  correo          text not null check (correo ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$'),
  direccion       text not null,
  fecha_registro  timestamptz not null default now(),
  -- Un mismo usuario del refugio no puede registrar dos veces el mismo documento
  unique (user_id, documento)
);

-- Solicitudes de adopción (relaciona una mascota con un adoptante)
--
-- Decisión sobre ON DELETE: usamos RESTRICT en ambas FK.
-- Motivo: una solicitud es un registro histórico (quién pidió adoptar a quién,
-- cuándo y con qué resultado). Si se borrara en cascada al eliminar la mascota
-- o el adoptante, se perdería esa trazabilidad sin que el usuario lo note.
-- Con RESTRICT, PostgreSQL rechaza el borrado (error 23503) y la app le avisa al
-- usuario que primero debe eliminar las solicitudes asociadas.
create table if not exists public.solicitudes_adopcion (
  id              uuid primary key default gen_random_uuid(),
  created_at      timestamptz not null default now(),
  user_id         uuid not null default auth.uid() references auth.users (id) on delete cascade,
  mascota_id      uuid not null references public.mascotas (id) on delete restrict,
  adoptante_id    uuid not null references public.adoptantes (id) on delete restrict,
  fecha_solicitud timestamptz not null default now(),
  estado          text not null default 'pendiente'
                  check (estado in ('pendiente', 'aprobada', 'rechazada')),
  observaciones   text
);

-- Índices para las consultas más frecuentes (filtrar por usuario y por FK)
create index if not exists idx_mascotas_user        on public.mascotas (user_id);
create index if not exists idx_adoptantes_user      on public.adoptantes (user_id);
create index if not exists idx_solicitudes_user     on public.solicitudes_adopcion (user_id);
create index if not exists idx_solicitudes_mascota  on public.solicitudes_adopcion (mascota_id);
create index if not exists idx_solicitudes_adoptante on public.solicitudes_adopcion (adoptante_id);

-- ---------------------------------------------------------------------
-- 2. SEGURIDAD: ROW LEVEL SECURITY
-- ---------------------------------------------------------------------
-- Con RLS activo, una fila solo es visible/modificable si alguna política lo
-- permite. Todas las políticas son para el rol `authenticated` y exigen
-- user_id = auth.uid(): cada usuario del refugio solo ve sus propios registros.
-- El rol `anon` no tiene ninguna política, así que no puede leer ni escribir.

alter table public.mascotas             enable row level security;
alter table public.adoptantes           enable row level security;
alter table public.solicitudes_adopcion enable row level security;

-- Defensa extra: quitar al rol anon todos los privilegios sobre las tablas.
revoke all on public.mascotas, public.adoptantes, public.solicitudes_adopcion from anon;
grant select, insert, update, delete
  on public.mascotas, public.adoptantes, public.solicitudes_adopcion to authenticated;

-- ---- mascotas ----
drop policy if exists "mascotas_select_propias" on public.mascotas;
create policy "mascotas_select_propias" on public.mascotas
  for select to authenticated using (user_id = auth.uid());

drop policy if exists "mascotas_insert_propias" on public.mascotas;
create policy "mascotas_insert_propias" on public.mascotas
  for insert to authenticated with check (user_id = auth.uid());

drop policy if exists "mascotas_update_propias" on public.mascotas;
create policy "mascotas_update_propias" on public.mascotas
  for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "mascotas_delete_propias" on public.mascotas;
create policy "mascotas_delete_propias" on public.mascotas
  for delete to authenticated using (user_id = auth.uid());

-- ---- adoptantes ----
drop policy if exists "adoptantes_select_propios" on public.adoptantes;
create policy "adoptantes_select_propios" on public.adoptantes
  for select to authenticated using (user_id = auth.uid());

drop policy if exists "adoptantes_insert_propios" on public.adoptantes;
create policy "adoptantes_insert_propios" on public.adoptantes
  for insert to authenticated with check (user_id = auth.uid());

drop policy if exists "adoptantes_update_propios" on public.adoptantes;
create policy "adoptantes_update_propios" on public.adoptantes
  for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "adoptantes_delete_propios" on public.adoptantes;
create policy "adoptantes_delete_propios" on public.adoptantes
  for delete to authenticated using (user_id = auth.uid());

-- ---- solicitudes_adopcion ----
-- En insert/update además se verifica que la mascota y el adoptante también
-- pertenezcan al usuario (evita enlazar registros ajenos conociendo su uuid).
drop policy if exists "solicitudes_select_propias" on public.solicitudes_adopcion;
create policy "solicitudes_select_propias" on public.solicitudes_adopcion
  for select to authenticated using (user_id = auth.uid());

drop policy if exists "solicitudes_insert_propias" on public.solicitudes_adopcion;
create policy "solicitudes_insert_propias" on public.solicitudes_adopcion
  for insert to authenticated with check (
    user_id = auth.uid()
    and exists (select 1 from public.mascotas m   where m.id = mascota_id   and m.user_id = auth.uid())
    and exists (select 1 from public.adoptantes a where a.id = adoptante_id and a.user_id = auth.uid())
  );

drop policy if exists "solicitudes_update_propias" on public.solicitudes_adopcion;
create policy "solicitudes_update_propias" on public.solicitudes_adopcion
  for update to authenticated using (user_id = auth.uid()) with check (
    user_id = auth.uid()
    and exists (select 1 from public.mascotas m   where m.id = mascota_id   and m.user_id = auth.uid())
    and exists (select 1 from public.adoptantes a where a.id = adoptante_id and a.user_id = auth.uid())
  );

drop policy if exists "solicitudes_delete_propias" on public.solicitudes_adopcion;
create policy "solicitudes_delete_propias" on public.solicitudes_adopcion
  for delete to authenticated using (user_id = auth.uid());

-- ---------------------------------------------------------------------
-- 3. TRIGGERS: sincronizar el estado de la mascota con sus solicitudes
-- ---------------------------------------------------------------------
-- Reglas:
--   a) No se puede crear una solicitud para una mascota 'adoptada' (BEFORE INSERT).
--   b) Solicitud nueva 'pendiente'          -> mascota 'en_proceso'.
--   c) Solicitud pasa a 'aprobada'          -> mascota 'adoptada'.
--   d) Solicitud pasa a 'rechazada' o se elimina, y la mascota ya no tiene
--      otras solicitudes 'pendiente'        -> mascota 'disponible'
--      (salvo que la mascota ya esté 'adoptada': ese estado no se revierte).
-- Las funciones corren con los permisos del usuario (security invoker), así
-- que el UPDATE sobre mascotas también pasa por RLS.

-- a) Bloqueo de solicitudes para mascotas adoptadas
create or replace function public.trg_bloquear_solicitud_mascota_adoptada()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if exists (select 1 from public.mascotas
              where id = new.mascota_id and estado_adopcion = 'adoptada') then
    -- La app muestra este mensaje tal cual (código P0001).
    raise exception 'Esta mascota ya fue adoptada; no se pueden crear nuevas solicitudes.'
      using errcode = 'P0001';
  end if;
  return new;
end;
$$;

drop trigger if exists bloquear_solicitud_mascota_adoptada on public.solicitudes_adopcion;
create trigger bloquear_solicitud_mascota_adoptada
  before insert on public.solicitudes_adopcion
  for each row execute function public.trg_bloquear_solicitud_mascota_adoptada();

-- Regla d) como función reutilizable: libera la mascota si ya no quedan
-- solicitudes pendientes y no está adoptada.
create or replace function public.liberar_mascota_si_corresponde(p_mascota_id uuid)
returns void
language plpgsql
set search_path = public
as $$
begin
  if not exists (select 1 from public.solicitudes_adopcion
                  where mascota_id = p_mascota_id and estado = 'pendiente') then
    update public.mascotas
       set estado_adopcion = 'disponible'
     where id = p_mascota_id
       and estado_adopcion <> 'adoptada';
  end if;
end;
$$;

-- b), c) y d)
create or replace function public.trg_solicitud_actualiza_mascota()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if tg_op = 'DELETE' then
    perform public.liberar_mascota_si_corresponde(old.mascota_id);
    return null;
  end if;

  if new.estado = 'aprobada' then
    update public.mascotas set estado_adopcion = 'adoptada'
     where id = new.mascota_id;
  elsif new.estado = 'pendiente' then
    update public.mascotas set estado_adopcion = 'en_proceso'
     where id = new.mascota_id and estado_adopcion <> 'adoptada';
  else -- 'rechazada'
    perform public.liberar_mascota_si_corresponde(new.mascota_id);
  end if;

  -- Si en un UPDATE se cambió la mascota, la anterior puede quedar libre.
  if tg_op = 'UPDATE' and old.mascota_id <> new.mascota_id then
    perform public.liberar_mascota_si_corresponde(old.mascota_id);
  end if;

  return null; -- trigger AFTER: el valor de retorno se ignora
end;
$$;

drop trigger if exists solicitud_actualiza_mascota on public.solicitudes_adopcion;
create trigger solicitud_actualiza_mascota
  after insert or update or delete on public.solicitudes_adopcion
  for each row execute function public.trg_solicitud_actualiza_mascota();

-- ---------------------------------------------------------------------
-- 4. REALTIME (opcional, para que el listado se actualice solo)
-- ---------------------------------------------------------------------
-- Agrega la tabla mascotas a la publicación de Realtime. Equivale a activar
-- "Realtime" para la tabla en Database > Publications > supabase_realtime.
-- Va dentro de un bloque DO con un IF para que el script se pueda ejecutar
-- varias veces (si la tabla ya está en la publicación, el ALTER fallaría).
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
     where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'mascotas'
  ) then
    alter publication supabase_realtime add table mascotas;
  end if;
end;
$$;

-- ---------------------------------------------------------------------
-- 5. DATOS DE EJEMPLO (opcional)
-- ---------------------------------------------------------------------
-- En el SQL Editor no hay sesión, así que auth.uid() es null. Para insertar
-- datos de prueba desde aquí, reemplaza 'UUID-DE-TU-USUARIO' por el id de tu
-- usuario (Authentication > Users) y quita los comentarios.
--
-- insert into public.mascotas (user_id, nombre, edad, tipo, raza, estado_vacunacion, descripcion)
-- values
--   ('UUID-DE-TU-USUARIO', 'Luna',  2, 'perro', 'Labrador', 'vacunado', 'Muy juguetona y cariñosa'),
--   ('UUID-DE-TU-USUARIO', 'Michi', 1, 'gato',  'Criollo',  'parcial',  'Tranquila, le gusta dormir al sol'),
--   ('UUID-DE-TU-USUARIO', 'Pipo',  3, 'ave',   'Canario',  'no_vacunado', null);
--
-- insert into public.adoptantes (user_id, nombre_completo, documento, telefono, correo, direccion)
-- values
--   ('UUID-DE-TU-USUARIO', 'Ana Gómez', '1012345678', '3001234567', 'ana@example.com', 'Calle 10 # 5-20');
--
-- insert into public.solicitudes_adopcion (user_id, mascota_id, adoptante_id, observaciones)
-- select 'UUID-DE-TU-USUARIO', m.id, a.id, 'Tiene patio grande'
--   from public.mascotas m, public.adoptantes a
--  where m.nombre = 'Luna' and a.documento = '1012345678';
