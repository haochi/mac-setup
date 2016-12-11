#!/usr/bin/env bash
export PATH=$PATH:/usr/local/bin

app_id=$(jq --raw-output ".openexchangerates.app_id" ~/.bitbar)
exchange_rate=$(curl -s "https://openexchangerates.org/api/latest.json?app_id=$app_id&base=USD" | jq ".rates.ARS")
printf '%.*f\n' 2 "$exchange_rate"
