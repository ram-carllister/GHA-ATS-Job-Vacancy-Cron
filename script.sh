#!/bin/bash
mkdir -p ~/.ssh
echo "$WPE_SSHG_KEY_PRIVATE" > ~/.ssh/id_rsa
chmod 600 ~/.ssh/id_rsa
ssh-keyscan -H ${WPE_ENV}.ssh.wpengine.net >> ~/.ssh/known_hosts

ssh -i ~/.ssh/id_rsa ${WPE_ENV}@${WPE_ENV}.ssh.wpengine.net <<EOF
cd ~/sites/${WPE_ENV}/

echo "--- \$(date) ---" >> cron-run.log
echo "GitHub Run: https://github.com/LiamSeck/WooCommerce-GHA-Triggers/actions/runs/$GHA_RUN_ID" >> cron-run.log

# Temporary test: remove once confirmed working
wp core version >> cron-run.log 2>> cron-run-error.log
wp cron event list >> cron-run.log 2>> cron-run-error.log

wp cron event run --due-now >> cron-run.log 2>> cron-run-error.log
EOF