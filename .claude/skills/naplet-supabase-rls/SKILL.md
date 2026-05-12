---
name: naplet-supabase-rls
description: Use this skill ALWAYS before creating, modifying, or debugging any Supabase RLS policy in the Naplet project. RLS failures present as silent errors (sheets staying open without UI feedback, no error in console), making them especially dangerous in production. This skill defines the validation protocol, common pitfalls, the caregiver retroactive access issue, and the column verification step. Trigger this skill whenever working with Supabase RLS policies, repositories that interact with sensitive tables, or debugging silent data access failures.
---

# Naplet Supabase RLS Protocol

The Naplet learned the hard way that RLS failures are silent. A bad policy doesn't throw an error; it just returns empty results, and the UI shows a sheet that never closes. This skill prevents that.

## Critical Rule

**Always verify columns exist before writing RLS policies.** Run:

```sql
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'your_table_name';
```

If a policy references a column that doesn't exist, PostgreSQL doesn't always throw a clear error. It just returns empty results, which the app interprets as "no data".

## Standard RLS Patterns

### Pattern 1: User owns their data

```sql
CREATE POLICY "Users can view their own X"
ON public.your_table
FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own X"
ON public.your_table
FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own X"
ON public.your_table
FOR UPDATE
USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own X"
ON public.your_table
FOR DELETE
USING (auth.uid() = user_id);
```

### Pattern 2: Baby-scoped data (used in Naplet)

For tables like `sleep_records`, `feeding_records`, etc:

```sql
CREATE POLICY "Users can view records of their babies"
ON public.sleep_records
FOR SELECT
USING (
  baby_id IN (
    SELECT id FROM public.babies 
    WHERE user_id = auth.uid()
    OR id IN (
      SELECT baby_id FROM public.caregivers
      WHERE user_id = auth.uid() AND status = 'accepted'
    )
  )
);
```

### Pattern 3: Caregiver with retroactive protection (CRITICAL)

The current Naplet has a known issue: when a caregiver is accepted, they see **all** historical records, including those from before they were added. This is a potential privacy violation.

Fix: add `accepted_at` column to caregivers table, then filter:

```sql
ALTER TABLE public.caregivers 
ADD COLUMN IF NOT EXISTS accepted_at TIMESTAMPTZ;

CREATE POLICY "Caregivers see only records after their acceptance"
ON public.sleep_records
FOR SELECT
USING (
  baby_id IN (SELECT id FROM public.babies WHERE user_id = auth.uid())
  OR baby_id IN (
    SELECT c.baby_id 
    FROM public.caregivers c
    WHERE c.user_id = auth.uid() 
      AND c.status = 'accepted'
      AND public.sleep_records.created_at >= c.accepted_at
  )
);
```

Apply the same pattern to all baby-scoped tables.

## Validation Protocol

Before deploying any RLS change:

### 1. Verify columns exist

```sql
SELECT column_name FROM information_schema.columns WHERE table_name = 'TABLE_NAME';
```

### 2. List current policies

```sql
SELECT policyname, cmd, qual, with_check 
FROM pg_policies 
WHERE tablename = 'TABLE_NAME';
```

### 3. Test with two distinct user accounts

Create two test users in Supabase. Login as each in two simulator instances. Verify:

- User A sees only their data
- User B sees only their data
- A caregiver of user A sees A's data only after acceptance
- A non-caregiver sees nothing of A

### 4. Watch for silent failures

If after a policy change:

- A sheet stays open without feedback
- A list comes up empty unexpectedly
- A repository returns 0 results when it shouldn't

→ Suspect RLS first. Check the policy, check the columns, check the user JWT.

## Diagnostic Queries

When debugging suspected RLS issues, run as the affected user via `set_config`:

```sql
SELECT set_config('request.jwt.claims', '{"sub":"USER_UUID_HERE"}', false);

SELECT * FROM public.your_table WHERE baby_id = 'BABY_UUID';
```

If this returns empty when it shouldn't, the policy is the culprit.

## Common Mistakes

1. **Forgetting to enable RLS on the table.**
   ```sql
   ALTER TABLE public.your_table ENABLE ROW LEVEL SECURITY;
   ```

2. **Referencing `user_id` when the column is named `owner_id` or similar.** Always verify first.

3. **Using `auth.uid() = user_id` when the relationship is indirect** (through `babies` or `caregivers` join).

4. **Forgetting INSERT/UPDATE policies after creating SELECT.** All four (SELECT, INSERT, UPDATE, DELETE) need explicit policies.

5. **Mixing logic in a single policy when separate ones would be clearer.** Prefer multiple policies that combine via `OR` behavior.

6. **Forgetting that Realtime subscriptions also respect RLS.** A subscription that worked in dev might silently filter everything in production.

## Tables in Naplet (sensitive list)

These require careful RLS:

| Table | Pattern needed |
|---|---|
| `babies` | User owns |
| `profiles` | User owns |
| `caregivers` | User owns + invitee can read their own invite |
| `invites` | User owns + invitee can read by code |
| `sleep_records` | Baby-scoped + caregiver with retroactive guard |
| `night_wakings` | Same as sleep_records |
| `feeding_records` | Same as sleep_records |
| `diaper_records` | Same as sleep_records |
| `bath_records` | Same as sleep_records |
| `health_records` | Same as sleep_records |
| `medication_schedules` | Same as sleep_records |
| `medication_logs` | Same as sleep_records |
| `baby_vaccinations` | Same as sleep_records |
| `baby_documents` | Same as sleep_records |
| `document_files` | Same as sleep_records (via document_id) |
| `referral_codes` | User owns |
| `referrals` | User owns (as referrer) |
| `baby_milestones` | Same as sleep_records |
| `growth_records` | Same as sleep_records |

## Realtime + RLS

When enabling Realtime on a table:

1. Confirm the policy applies to the user's JWT
2. Test the subscription with two distinct users
3. Verify that user B does not receive events from user A's records
4. Verify caregivers receive events only from their accepted babies, and only post-acceptance

## When to Backup Before Changes

Always backup the policy state before changes by exporting from Supabase dashboard or via:

```sql
SELECT 
  schemaname, 
  tablename, 
  policyname, 
  permissive, 
  roles, 
  cmd, 
  qual, 
  with_check
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;
```

Save the output to a file before deploying changes.

## Final Reminder

RLS bugs in Naplet cost trust. A user seeing another family's baby data is unrecoverable. Spend 10 extra minutes verifying every policy.
