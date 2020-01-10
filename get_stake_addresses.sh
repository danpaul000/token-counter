#!/usr/bin/env bash

#set -x

source get_program_accounts.sh

# SLP1 RPC Node
#url=http://34.82.79.31:8899

# Dan's test Node
url=http://34.82.15.82:8899

usage() {
  exitcode=0
  if [[ -n "$1" ]]; then
    exitcode=1
    echo "Error: $*"
  fi
  cat <<EOF
usage: $0 [options]
 options:
   --url [url]        - RPC URL for a running Solana cluster (default: $url)
   --pubkey [pubkey]  - Base58 pubkey that is an authorized staker for at least one stake account on the cluster.  Required.
EOF
  exit $exitcode
}

while [[ -n $1 ]]; do
  if [[ ${1:0:2} = -- ]]; then
    if [[ $1 = --url ]]; then
      url="$2"
      shift 2
    elif [[ $1 = --pubkey ]]; then
      filter_pubkey="$2"
      shift 2
    else
      usage "Unknown option: $1"
    fi
  else
    usage "Unknown option: $1"
  fi
done

[[ -n $filter_pubkey ]] || usage

stake_account_json_file=STAKE_account_data.json
stake_account_csv_file=STAKE_account_data.csv
if [[ ! -f $stake_account_json_file ]]; then
  echo "$stake_account_json_file does not exist.  Querying cluster for data"
  get_program_accounts STAKE $STAKE_PROGRAM_PUBKEY $url
  write_account_data_csv STAKE
fi

rm "$stake_account_csv_file"
cat "$stake_account_json_file" | jq -r '(.result | .[]) | [.[0], (.[1] | .lamports)] | @csv' >> $stake_account_csv_file

num_stake_accounts=0
stake_account_balance_total=0

echo "Searching cluster stake accounts for authorized staker: $filter_pubkey"
date
while IFS=, read -r account_pubkey lamports ; do
  account_pubkey=$(echo $account_pubkey | tr -d '"')
  staker="$(solana show-stake-account $account_pubkey | grep staker | cut -f3 -d " ")"
  if [[ "$staker" == "$filter_pubkey" ]] ; then
    stake_account_balance_total=$((stake_account_balance_total + $lamports))
    num_stake_accounts=$((num_stake_accounts + 1))

    printf "Stake account address: %s, Balance: %'.d lamports\n" $account_pubkey $lamports
  fi
done < "$stake_account_csv_file"

date

echo "Totals"
printf "Number of stake accounts: %'.d\n" $num_stake_accounts
printf "Total balance across all accounts: %'.d lamports\n" $stake_account_balance_total
