# github-actions

GitHub Actions that trigger WP-Cron on the Inizio WP Engine installs over SSH. WP-Cron is not left to run on page loads; this repo runs due events on a schedule instead.

## How it works

`.github/workflows/cron-scheduler.yml` runs every 15 minutes (and on manual `workflow_dispatch`). It uses a matrix to run once per GitHub Environment (`dev`, `stg`). The WP Engine install name for each lives in that environment's `WPE_ENV` secret, so it isn't stored in the repo.

Each matrix job gets `WPE_ENV` from its environment's secret and runs `script.sh`, which:

1. Writes the SSH private key from `WPE_SSHG_KEY_PRIVATE` to `~/.ssh/id_rsa` and adds the WP Engine host to `known_hosts`.
2. SSHes to `${WPE_ENV}@${WPE_ENV}.ssh.wpengine.net` and `cd`s into `~/sites/${WPE_ENV}/`.
3. Logs the WP version and, for every site in the network (excluding archived, spam and deleted), lists the cron events and runs the due ones with `wp cron event run --due-now`. PHP warnings, notices and deprecations are suppressed via `--exec`.
4. Trims the logs so they stay bounded.

Jobs run in parallel with `fail-fast: false`, so one environment failing doesn't stop the other. Concurrency is grouped per environment (`wp-cron-<env>`), so a slow run won't overlap with the next one for the same install.

## Logs

Logs are written on the server in `~/sites/<env>/_wpeprivate/`:

- `cron-run.log`: run headers (timestamp, link to the GitHub run), WP version, cron event lists and run output. Trimmed to the last 5000 lines.
- `cron-run-error.log`: stderr, plus a `FAILED: <url>` line for any site where `wp cron event run` exited non-zero. Trimmed to the last 2 MB.

## Setup

- **Environments:** create GitHub Environments `dev` and `stg`. Each needs two secrets: `WPE_ENV` (the WP Engine install name) and `WPE_SSHG_KEY_PRIVATE` (the private key of an SSH key registered with WP Engine for that install).
- **Default branch:** GitHub only fires `schedule:` triggers from the default branch (`main`), so changes only take effect once merged there. Scheduled runs can't be selected per branch.

## Changing things

- **Add or rename an environment:** add an environment with its own secrets and add its name to the `target` list in the matrix in `cron-scheduler.yml`.
- **Change the frequency:** edit the `cron:` expression. Note that GitHub may delay scheduled runs under load, and 5 minutes is the shortest interval.
- **Run manually:** Actions tab → select the workflow → Run workflow.

## Notes

- `script.sh` runs the remote commands inside an unquoted heredoc. Variables meant for the server (`\$url`, `\$LOG`, ...) must stay escaped; unescaped ones (`$GHA_REPO`, `$WPE_ENV`) are expanded on the GitHub runner.
- `wp core version` and the per-site `wp cron event list` calls are diagnostic output and can be removed once the setup is confirmed working.
