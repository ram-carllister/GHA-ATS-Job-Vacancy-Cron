#!/bin/bash
mkdir -p ~/.ssh
echo "$WPE_SSHG_KEY_PRIVATE" > ~/.ssh/id_rsa
chmod 600 ~/.ssh/id_rsa
ssh-keyscan -H ${WPE_ENV}.ssh.wpengine.net >> ~/.ssh/known_hosts

ssh -i ~/.ssh/id_rsa ${WPE_ENV}@${WPE_ENV}.ssh.wpengine.net <<EOF
cd ~/sites/${WPE_ENV}/
mkdir -p _wpeprivate
LOG=_wpeprivate/cron-run.log
ERR=_wpeprivate/cron-run-error.log

echo "--- \$(date) ---" >> \$LOG
echo "GitHub Run: https://github.com/$GHA_REPO/actions/runs/$GHA_RUN_ID" >> \$LOG

# Pre details
# wp core version >> \$LOG 2>> \$ERR

for url in \$(wp site list --field=url --archived=0 --spam=0 --deleted=0); do
  echo "Site: \$url" >> \$LOG
  # wp cron event list --url="\$url" >> \$LOG 2>> \$ERR
  wp cron event run --due-now --url="\$url" --exec='ini_set("display_errors", "0"); error_reporting(E_ALL & ~E_WARNING & ~E_NOTICE & ~E_DEPRECATED);' >> \$LOG 2>> \$ERR \
    || echo "FAILED: \$url" >> \$ERR
done

# Keep logs bounded
tail -n 15000 \$LOG > \$LOG.tmp && mv \$LOG.tmp \$LOG
tail -c 2M  \$ERR > \$ERR.tmp && mv \$ERR.tmp \$ERR
EOF
