# Sikkerhet — åpen tilgang som må lukkes

**Status: kjent hull. Ikke fikset. Krever ett steg bare du kan gjøre.**

## Problemet

Alle tabeller i begge Supabase-prosjektene har i dag en policy av typen:

```sql
FOR ALL TO anon USING (true) WITH CHECK (true)
```

`anon`-nøkkelen ligger i klartekst i `files/index.html`, som er offentlig på
foocuscrm.netlify.app. Det betyr at **hvem som helst som åpner kildekoden kan
lese og skrive** alt av kunder, kontrakter, kostnader, inntekter og investorer.

Policyene ble lagt på 8. juni 2026 for å få appen til å vise data i det hele
tatt, etter en lang feilsøking av Supabase-SDK-ens auth-lås. De var ment å være
midlertidige.

Berørte tabeller:

| Prosjekt | Tabeller |
|---|---|
| `izeefglmytbszpsntcur` (Ronja / CRM) | clients, tasks, documents, contracts, costs, income_entries, financials |
| `sjlgcszidjasgljmkfen` (FounderOS) | investors, investor_activities |

De øvrige FounderOS-tabellene (`messages`, `email_scope`, `meetings`, `people`)
har RLS på og **ingen** policy — de er låst. Desktop-appen når dem via
service-nøkkel fra Tauri, som er trygt fordi den kjører lokalt.

## Fiksen

Bytt `TO anon` med `TO authenticated` på alle tabellene. Da kreves en gyldig
innlogget bruker, ikke bare den offentlige nøkkelen.

For CRM-basen er dette rett fram — `glenn@foocus.ai` finnes allerede der.

For FounderOS-basen er det et hinder: **JWT-er er per prosjekt.** En token
utstedt av CRM-prosjektet er ikke gyldig i FounderOS-prosjektet — de har
forskjellige signeringsnøkler. Så CRM-appen får aldri `authenticated`-rolle
mot FounderOS uten å logge inn der også.

### Stegene

1. **Du:** opprett bruker `glenn@foocus.ai` i FounderOS-prosjektet
   → Supabase Dashboard → prosjekt FounderOS → Authentication → Add user.
   Bruk samme passord som CRM-en, ellers må appen be om to.
   *Dette kan ikke jeg gjøre — det krever passordet ditt, og jeg skal ikke ha det.*

2. **Kode:** la `handleLogin` logge inn mot begge prosjektene med samme
   legitimasjon, slik at `sb` og `sbFounder` begge har gyldig sesjon.

3. **SQL, begge prosjekter:** bytt policyene.

   ```sql
   -- eksempel, gjenta per tabell
   DROP POLICY IF EXISTS "investors_crm_anon" ON investors;
   CREATE POLICY "investors_auth" ON investors
     FOR ALL TO authenticated USING (true) WITH CHECK (true);
   ```

4. **Verifiser:** kall tabellen med bare anon-nøkkelen og bekreft at den
   returnerer tomt eller 401.

   ```bash
   curl -s "https://<ref>.supabase.co/rest/v1/investors?select=id" \
        -H "apikey: <anon-key>"
   ```

## Rekkefølge

Gjør CRM-basen først — den er enklest og dekker mest data. FounderOS-basen kan
vente til steg 1 er gjort.

Ikke gjør dette rett før du er utilgjengelig. Hvis auth-oppsettet svikter,
låser du deg selv ute av din egen CRM.
