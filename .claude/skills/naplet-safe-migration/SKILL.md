---
name: naplet-safe-migration
description: Use this skill ALWAYS before modifying any file in the Naplet project. The app is in production with real users. This skill defines the mandatory safety protocol for any change, including branch management, atomic commits, build verification, smoke testing, and rollback procedures. Trigger this skill whenever about to edit AppConfig.swift, Info.plist, project.pbxproj, any file in Features/Paywall/, any Repository, any RLS policy, or any other sensitive file.
---

# Naplet Safe Migration Protocol

The Naplet app is live on the App Store with ~46 active users. Every change must follow this protocol. Skipping any step risks breaking production.

## Core Rules

1. **Never commit directly to `main`.** Always work in a feature branch named `sprint-{N}/{feature-slug}`.
2. **Atomic commits.** One logical change per commit. Mixed commits make rollback impossible.
3. **Build must pass.** A successful `xcodebuild ... clean build` is required before closing any block.
4. **Smoke test required.** Open the app on simulator, log in, create a sleep record, close. If any of those fails, revert.
5. **Sensitive files require double verification.** Show file before editing, get explicit confirmation, then edit, then verify.

## Sensitive Files (extra caution)

| File | Why sensitive | Required action |
|---|---|---|
| `AppConfig.swift` | Contains API keys, env switches, feature flags | Show full file, get confirmation before each line change |
| `Info.plist` | Permissions, URL schemes, capabilities | Show before edit, verify with build |
| `Naplet.xcodeproj/project.pbxproj` | Project structure, build settings | Use targeted `sed` only; full edits forbidden |
| `Features/Paywall/**` | Revenue logic | Test purchase flow after any change |
| `Data/Repositories/**` | Data access, RLS-sensitive | Test with two distinct user accounts |
| Supabase RLS policies | Data security | Verify via `information_schema.columns` first |
| Edge Functions | Server-side logic | Test in staging before prod deploy |

## Branch Workflow

```bash
# Start
git checkout main
git pull origin main
git checkout -b sprint-1/openai-proxy

# Work
# ... make changes ...
git add file1.swift file2.swift
git commit -m "feat(scope): clear message"

# More changes
git add otherfile.swift
git commit -m "refactor(scope): clear message"

# Push for review
git push origin sprint-1/openai-proxy

# After TestFlight validation
git checkout main
git merge sprint-1/openai-proxy
git push origin main
```

## Commit Message Convention

Use conventional commits:

- `feat(scope):` new feature
- `fix(scope):` bug fix
- `refactor(scope):` refactor without behavior change
- `chore(scope):` tooling, configs
- `docs(scope):` documentation only
- `security(scope):` security-related change

Examples:
- `feat(onboarding): add paywall after final onboarding step`
- `fix(chat): handle empty response from OpenAI proxy`
- `security(config): remove hardcoded OpenAI key, use Edge Function`

## Smoke Test Checklist

After every block, execute on iPhone 15 Pro simulator:

1. Cold start the app
2. If logged in, log out
3. Sign in with Apple (sandbox account)
4. Complete onboarding if first launch
5. Open dashboard, verify baby info is loaded
6. Create a sleep record (start, then end)
7. Open Chat IA, send one message, verify response
8. Open History, verify the sleep record appears
9. Close app, reopen, verify data persists

If any step fails, **revert the last commit** with `git revert HEAD` and investigate before continuing.

## Build Number Increment

When submitting to TestFlight, increment build number via targeted `sed`:

```bash
# Find current
grep -o 'CURRENT_PROJECT_VERSION = [0-9]*' Naplet.xcodeproj/project.pbxproj | head -1

# Increment (replace OLD and NEW)
sed -i '' 's/CURRENT_PROJECT_VERSION = OLD;/CURRENT_PROJECT_VERSION = NEW;/g' Naplet.xcodeproj/project.pbxproj
```

Never edit `project.pbxproj` manually beyond this. The XML is fragile.

## Rollback Procedure

If something breaks in production:

1. **Don't panic.** Branch isolation makes recovery easy.
2. Identify the offending commit: `git log --oneline -20`
3. Revert: `git revert <commit-hash>`
4. Test build
5. If a TestFlight build is already out: submit a hotfix build with fix
6. If on App Store and severe: use App Store Connect emergency removal

## Configuration Changes (RevenueCat, OpenAI, Supabase)

Never change credentials, project IDs, or environment switches without:

1. Documenting the previous value in a private note
2. Testing the new value in sandbox first
3. Having a clear rollback path

## Database Changes (Supabase)

Before any schema change or RLS policy:

1. Take a backup snapshot from the Supabase dashboard
2. Test in a separate staging project if available
3. For RLS, **always** verify columns exist:

```sql
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'your_table';
```

4. Test the policy with at least two distinct user accounts
5. Watch for silent failures: if a sheet stays open without UI feedback, suspect RLS

## File Touching Order (when multiple)

When a feature touches many files, edit in this order:

1. Models (Data/Models)
2. Repositories (Data/Repositories)
3. Services (Data/Services)
4. ViewModels (Features/*/ViewModels)
5. Views (Features/*/Views)
6. Localization (Resources/*.lproj)

This minimizes broken intermediate states.

## When in Doubt

Stop and ask Edy. Better to pause and confirm than to push a broken state to production.
