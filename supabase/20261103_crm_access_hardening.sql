-- Applied to Supabase project Ronja (izeefglmytbszpsntcur) on 2026-11-03 as
-- migrations `backup_snapshot_20261103` and `crm_access_hardening_20261103`.
-- Kept here so the database change lives next to the code that depends on it.
-- Rollback: 20261103_crm_access_hardening_rollback.sql

-- 0. Backup taken first (schema backup_20261103: copies of all 7 CRM tables and
--    the previous pg_policies rows; no grants for anon/authenticated).

-- 1. Explicit allowlist of CRM users (by auth user id, not by e-mail domain)
create table if not exists public.crm_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  added_at timestamptz not null default now(),
  note text
);
alter table public.crm_users enable row level security;
revoke all on public.crm_users from anon, authenticated;

insert into public.crm_users (user_id, email, note)
select id, email, 'Daglig leder, autorisert 2026-11-03' from auth.users where email = 'glenn@foocus.ai'
on conflict (user_id) do nothing;

create or replace function public.is_crm_user()
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.crm_users where user_id = auth.uid());
$$;
revoke all on function public.is_crm_user() from public, anon;
grant execute on function public.is_crm_user() to authenticated;

-- 2. Replace every CRM policy with allowlist-only access; drop public contract policies
do $$
declare r record;
begin
  for r in select tablename, policyname from pg_policies
           where schemaname = 'public'
             and tablename in ('clients','tasks','documents','contracts','financials','costs','income_entries')
  loop
    execute format('drop policy %I on public.%I', r.policyname, r.tablename);
  end loop;
end $$;

do $$
declare t text;
begin
  foreach t in array array['clients','tasks','documents','contracts','financials','costs','income_entries']
  loop
    execute format('create policy crm_users_only on public.%I for all to authenticated using (public.is_crm_user()) with check (public.is_crm_user())', t);
    execute format('revoke all on public.%I from anon', t);
  end loop;
end $$;

-- 3. Single-contract signing tokens (only the SHA-256 hash is stored)
create table if not exists public.contract_signing_tokens (
  token_hash text primary key,
  contract_id uuid not null references public.contracts(id) on delete cascade,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  expires_at timestamptz not null,
  used_at timestamptz,
  revoked_at timestamptz
);
create index if not exists contract_signing_tokens_contract_idx on public.contract_signing_tokens(contract_id);
alter table public.contract_signing_tokens enable row level security;
revoke all on public.contract_signing_tokens from anon, authenticated;

create or replace function public.issue_signing_token(p_contract_id uuid, p_valid_days integer default 30)
returns text language plpgsql volatile security definer set search_path = '' as $$
declare v_token text; v_status text;
begin
  if not public.is_crm_user() then raise exception 'not authorized' using errcode = '42501'; end if;
  if p_valid_days is null or p_valid_days < 1 or p_valid_days > 90 then raise exception 'valid days must be 1-90'; end if;
  select status into v_status from public.contracts where id = p_contract_id;
  if v_status is null then raise exception 'contract not found'; end if;
  if v_status not in ('sent','signed') then raise exception 'contract must be sent before a signing link is issued'; end if;
  update public.contract_signing_tokens set revoked_at = now()
   where contract_id = p_contract_id and revoked_at is null;
  v_token := translate(encode(extensions.gen_random_bytes(32), 'base64'), '+/=', '-_');
  insert into public.contract_signing_tokens (token_hash, contract_id, created_by, expires_at)
  values (encode(extensions.digest(v_token, 'sha256'), 'hex'), p_contract_id, auth.uid(), now() + make_interval(days => p_valid_days));
  return v_token;
end $$;
revoke all on function public.issue_signing_token(uuid, integer) from public, anon;
grant execute on function public.issue_signing_token(uuid, integer) to authenticated;

create or replace function public.get_contract_for_signing(p_contract_id uuid, p_token text)
returns jsonb language plpgsql stable security definer set search_path = '' as $$
declare v jsonb;
begin
  if p_contract_id is null or p_token is null or length(p_token) < 32 then return null; end if;
  select jsonb_build_object('id', c.id, 'status', c.status, 'template_type', c.template_type,
                            'contract_data', c.contract_data, 'pdf_data', c.pdf_data,
                            'signed_pdf_data', c.signed_pdf_data, 'created_at', c.created_at)
    into v
    from public.contracts c
    join public.contract_signing_tokens t on t.contract_id = c.id
   where c.id = p_contract_id
     and t.token_hash = encode(extensions.digest(p_token, 'sha256'), 'hex')
     and t.revoked_at is null and t.expires_at > now()
     and c.status in ('sent','signed');
  return v;
end $$;
revoke all on function public.get_contract_for_signing(uuid, text) from public;
grant execute on function public.get_contract_for_signing(uuid, text) to anon, authenticated;

create or replace function public.sign_contract(p_contract_id uuid, p_token text, p_signed_by text,
                                                p_signed_title text default '', p_signed_pdf_data text default null)
returns jsonb language plpgsql volatile security definer set search_path = '' as $$
declare v_hash text; v_tok record; v_data jsonb;
begin
  if p_contract_id is null or p_token is null or length(p_token) < 32 then raise exception 'invalid signing link' using errcode = '42501'; end if;
  if p_signed_by is null or length(btrim(p_signed_by)) = 0 or length(p_signed_by) > 200 then raise exception 'name is required (max 200 characters)'; end if;
  if length(coalesce(p_signed_title, '')) > 200 then raise exception 'title too long'; end if;
  if p_signed_pdf_data is not null and (p_signed_pdf_data not like 'data:application/pdf%' or length(p_signed_pdf_data) > 20000000) then
    raise exception 'invalid signed PDF';
  end if;
  v_hash := encode(extensions.digest(p_token, 'sha256'), 'hex');
  select * into v_tok from public.contract_signing_tokens
   where token_hash = v_hash and contract_id = p_contract_id and revoked_at is null and expires_at > now()
   for update;
  if not found then raise exception 'invalid or expired signing link' using errcode = '42501'; end if;

  update public.contracts
     set status = 'signed',
         contract_data = contract_data || jsonb_build_object(
             'signed_by', btrim(p_signed_by), 'signed_title', btrim(coalesce(p_signed_title, '')),
             'signed_at', now(), 'signed_ip', 'browser')
           || case when p_signed_pdf_data is not null then jsonb_build_object('has_signed_pdf', true) else '{}'::jsonb end,
         signed_pdf_data = coalesce(p_signed_pdf_data, signed_pdf_data),
         updated_at = now()
   where id = p_contract_id and status = 'sent'
  returning contract_data into v_data;
  if not found then raise exception 'contract is not awaiting signature'; end if;

  update public.contract_signing_tokens set used_at = now() where token_hash = v_hash;
  return jsonb_build_object('id', p_contract_id, 'status', 'signed', 'contract_data', v_data);
end $$;
revoke all on function public.sign_contract(uuid, text, text, text, text) from public;
grant execute on function public.sign_contract(uuid, text, text, text, text) to anon, authenticated;
