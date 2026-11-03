# Sikkerhet

**Sist oppdatert: 3. november 2026.**

## Status i CRM-basen (Ronja, `izeefglmytbszpsntcur`)

Rettet og testet 3. november 2026 (`supabase/20261103_crm_access_hardening.sql`):

- `anon` har ingen tabellrettigheter lenger. Den offentlige nøkkelen i
  `files/index.html` gir bare tilgang til innlogging og signeringsfunksjonene.
- Alle sju CRM-tabeller har én policy, `crm_users_only`. Innlogget er ikke nok:
  brukeren må stå i `public.crm_users` (eksplisitt liste over bruker-ID-er).
  Per i dag står bare `glenn@foocus.ai` der.
- Kontrakter kan ikke listes eller leses offentlig. Signeringslenken bærer et
  token for én kontrakt (`issue_signing_token`, 30 dagers utløp, ny lenke
  tilbakekaller gamle). Siden leser og signerer gjennom
  `get_contract_for_signing` og `sign_contract`, som bare skriver
  signaturfeltene.
- Sikkerhetskopi tatt før endringen: schema `backup_20261103` (ikke eksponert).
- Tilbakeføring: `supabase/20261103_crm_access_hardening_rollback.sql`.

### Gjenstår (krever dashboard-tilgang)

1. **Slå av åpen registrering:** Supabase → Ronja → Authentication →
   Sign In / Providers → «Allow new users to sign up» av. Den er på i dag.
   Nye brukere får ingen data uten å stå i `crm_users`, men registreringen
   bør likevel stenges.
2. Slå på «Leaked password protection» (Supabase-rådgiveren anbefaler det).
3. Legge til andre som skal bruke CRM-et:

   ```sql
   insert into public.crm_users (user_id, email, note)
   select id, email, 'Autorisert av Glenn <dato>' from auth.users where email = '<e-post>';
   ```

4. Edge-funksjonen `notify-contract-signed` kan kalles uten innlogging og
   setter input rett inn i e-posten. Bør kreve en hemmelighet og escape input.

## FounderOS-basen (`sjlgcszidjasgljmkfen`) — pauset

Ifølge den forrige versjonen av dette dokumentet har `investors` og
`investor_activities` en `anon`-policy med full tilgang. Det er **ikke
verifisert** fordi prosjektet er pauset. Hvis prosjektet vekkes, må dette
lukkes før noe annet, og investorsiden i CRM-et (`sbFounder`) må flyttes.

FounderOS-prosjektet har også en hemmelighet `CRM_SERVICE_KEY` (service_role
for Ronja) som edge-funksjonen `sales` bruker. Den gir full tilgang til
CRM-basen og må roteres når FounderOS legges ned.
