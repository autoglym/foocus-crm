-- Rollback for 20261103_crm_access_hardening.sql (Ronja, izeefglmytbszpsntcur).
-- Restores the exact policies and anon grants that existed before 2026-11-03,
-- INCLUDING the open public read/update on contracts. Only run this if the new
-- setup locks out legitimate use and you accept reopening that hole; prefer
-- adding the missing user to public.crm_users instead:
--
--   insert into public.crm_users (user_id, email, note)
--   select id, email, 'Autorisert av Glenn <dato>' from auth.users where email = '<e-post>';
--
-- Code rollback: revert commit 9bd2560 in this repo (Netlify deploys main).

begin;

-- 1. Policies as they were (captured in backup_20261103.policies)
do $$
declare t text;
begin
  foreach t in array array['clients','tasks','documents','contracts','financials','costs','income_entries']
  loop
    execute format('drop policy if exists crm_users_only on public.%I', t);
  end loop;
end $$;

create policy "Allow all for authenticated" on public.clients   for all to authenticated using (true) with check (true);
create policy "Allow all for authenticated" on public.tasks     for all to authenticated using (true) with check (true);
create policy "Allow all for authenticated" on public.documents for all to authenticated using (true) with check (true);
create policy financials_auth on public.financials        for all to authenticated using (true) with check (true);
create policy costs_auth      on public.costs             for all to authenticated using (true) with check (true);
create policy income_auth     on public.income_entries    for all to authenticated using (true) with check (true);
create policy contracts_auth  on public.contracts         for all to authenticated using (true) with check (true);
create policy "Allow all for authenticated users" on public.contracts for all to authenticated using (true) with check (true);
create policy "Allow public read of sent contracts" on public.contracts
  for select to public using (status = any (array['sent'::text, 'signed'::text]));
create policy "Allow public signing of sent contracts" on public.contracts
  for update to public using (status = 'sent'::text) with check (status = 'signed'::text);

-- 2. Table grants for anon as they were
do $$
declare t text;
begin
  foreach t in array array['clients','tasks','documents','contracts','financials','costs','income_entries']
  loop
    execute format('grant select, insert, update, delete, truncate, references, trigger on public.%I to anon', t);
  end loop;
end $$;

-- 3. New objects (dropping them invalidates all issued signing links)
drop function if exists public.sign_contract(uuid, text, text, text, text);
drop function if exists public.get_contract_for_signing(uuid, text);
drop function if exists public.issue_signing_token(uuid, integer);
drop table if exists public.contract_signing_tokens;
-- crm_users / is_crm_user are left in place; they are harmless once no policy uses them.

commit;

-- Data restore (only if data was damaged), per table, e.g.:
--   insert into public.contracts select * from backup_20261103.contracts on conflict (id) do nothing;
