# StreamHub account setup (free to start)

The app uses Supabase Auth for StreamHub email/password accounts and Postgres
with row-level security for favorites. It never stores the user's Netflix,
Disney+, Prime Video, Spotify, or other provider credentials.

## Create the free backend

1. Create a free project at [supabase.com](https://supabase.com/). Choose a
region appropriate for your users and keep the project private.
2. In **Project Settings → API**, copy the **Project URL** and the **publishable
   key** (or legacy `anon` key). Never use or share the `service_role` key in the
   app.
3. In **SQL Editor**, run [`supabase/schema.sql`](supabase/schema.sql) once.
   This creates the favorites table and policies that restrict each account to
   its own rows.
4. In **Authentication → Providers → Email**, enable email/password signup.
   Keep email confirmation enabled for real users. The built-in email sender is
   intended for development: it only sends to addresses that belong to the
   Supabase organization and is limited to 2 emails per hour. Configure a
   trusted SMTP provider before inviting the general public.

## Let the public create accounts

Email/password signup is already implemented in the app. Supabase's built-in
sender cannot deliver confirmation messages to the general public, so public
signup is not complete until custom SMTP is configured. Keep **Confirm email**
enabled; do not work around the email limit by allowing unverified accounts.

For a small prototype, a Gmail account can be used as the sender:

1. Turn on Google **2-Step Verification** and create a dedicated **App Password**
   for StreamHub. Google only offers app passwords when 2-Step Verification is
   active. Never use your normal Gmail password here.
2. In Supabase, open **Authentication → Settings → SMTP Settings**, enable custom
   SMTP, and enter:

   | Setting | Value |
   | --- | --- |
   | Sender email | Your complete Gmail address |
   | Sender name | Stream Hub |
   | Host | `smtp.gmail.com` |
   | Port | `587` (TLS/STARTTLS) |
   | Username | Your complete Gmail address |
   | Password | The Google App Password |

3. Save and send a confirmation email to an address outside the Supabase
   organization as a check. Enter the app password directly in Supabase's
   dashboard; never put it in StreamHub, GitHub, or chat.

Gmail is a convenient starting point, not a high-volume transactional mail
service. For a public launch, use a dedicated email provider and a verified
sending domain, then configure that provider's SMTP credentials in Supabase.

## Configure GitHub release builds

The public release workflow is already configured with this project's URL and
publishable key so the Windows and Android/TV downloads can connect to the same
StreamHub account backend. Supabase publishable keys are intended for shipped
client apps; the database is protected by the row-level security policies
created above. Never put the SMTP password, database password, or `service_role`
key in the workflow, app, or public repository.

## Run the Windows app with the project

From PowerShell, substitute the URL and publishable key from the project:

```powershell
$env:PUB_CACHE = 'D:\PubCache'
$env:TEMP = 'D:\Temp'
$env:TMP = 'D:\Temp'
& 'D:\CodexTools\flutter\bin\flutter.bat' build windows --release `
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co `
  --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

Copy the release output from `build\windows\x64\runner\Release` to
`D:\Apps\Stream Hub` to install it. Without the two build values, the app
intentionally stays on the account screen and explains that online accounts
are not connected yet; it does not create fake local-only accounts.

The publishable/anon key is designed to be present in a client app. Database
security depends on the included row-level security policies. Keep the
`service_role` key, database password, and SMTP credentials out of the app and
repository.

The free tier is suitable for a small prototype, subject to Supabase's current
quotas and inactivity pause policy. Check the current plan before opening the
service broadly to users.
