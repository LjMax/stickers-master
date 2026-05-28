# Hosting the Privacy Policy (GitHub Pages)

The Play Store listing needs a **public URL** for the privacy policy. The policy file
already exists in the repo at `docs/privacy-policy.html`. GitHub Pages can serve it for
free, straight from that `docs/` folder.

## Prerequisite

GitHub Pages on a **private** repo requires a paid GitHub plan. The `stickers-master`
repo is being made public anyway, so make sure it's **public before** (or as part of)
turning on Pages. If you'd rather keep it private, tell me and I'll suggest an
alternative host (e.g. Netlify Drop, or a separate public repo for just the policy).

## Steps

1. Push the latest `main` (the `docs/privacy-policy.html` file must be committed and
   on `github.com/LjMax/stickers-master`).

2. On GitHub, open the repo → **Settings** (top tab) → **Pages** (left sidebar).

3. Under **Build and deployment → Source**, choose **Deploy from a branch**.

4. Set **Branch** to `main` and the folder to **`/docs`**. Click **Save**.

5. Wait about 1–2 minutes. GitHub builds the site and the Pages section shows a green
   "Your site is live at …" banner.

6. Your policy will be at:

   ```
   https://ljmax.github.io/stickers-master/privacy-policy.html
   ```

   (GitHub Pages URLs are lowercase — `ljmax`, not `LjMax`.)

7. Open that URL in a browser to confirm it loads, the EN/SR language toggle works, and
   the contact email shows correctly.

## Where the URL goes

- **Play Console → App content → Privacy policy** — paste the URL here.
- **Play Console → Store listing** — there's also an optional privacy-policy spot in
  some sections; use the same URL.

## Keeping it current

The policy is plain HTML in the repo, so any future edit is just a commit to `main` —
GitHub Pages redeploys automatically within a minute. No separate publish step.

## Note

If you later add a custom domain, you can point it at the same Pages site, but the
`github.io` URL is perfectly acceptable for the Play Store and many published apps use
exactly this setup.
