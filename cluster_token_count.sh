#!/usr/bin/env bash

source get_program_accounts.sh

# SLP1 RPC Node
#url=http://34.82.79.31:8899

# Dan's test Node
url=http://35.197.48.102:8899

if [[ -n $1 ]]; then
  url="$1"
fi

LAMPORTS_PER_SOL=1000000000 # 1 billion
TOTAL_ALLOWED_SOL=500000000 # 500 million

tokenCapitalizationSol=
tokenCapitalizationLamports=

stakeAccountBalanceTotalSol=
systemAccountBalanceTotalSol=
voteAccountBalanceTotalSol=
storageAccountBalanceTotalSol=
configAccountBalanceTotalSol=

stakeAccountBalanceTotalLamports=
systemAccountBalanceTotalLamports=
voteAccountBalanceTotalLamports=
storageAccountBalanceTotalLamports=
configAccountBalanceTotalLamports=

function get_cluster_version {
  clusterVersion="$(curl -s -X POST -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","id":1, "method":"getVersion"}' $url | jq '.result | ."solana-core" ')"
  echo Cluster software version: $clusterVersion
}

function get_token_capitalization {
  quiet="$1"

  totalSupplyLamports="$(curl -s -X POST -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","id":1, "method":"getTotalSupply"}' $url | cut -d , -f 2 | cut -d : -f 2)"
  totalSupplySol=$((totalSupplyLamports / LAMPORTS_PER_SOL))

  if [[ -z $quiet ]]; then
    printf "\n--- Token Capitalization ---\n"
    printf "Total token capitalization %s SOL\n" "$totalSupplySol"
    printf "Total token capitalization %s Lamports\n" "$totalSupplyLamports"
  fi

  tokenCapitalizationLamports="$totalSupplyLamports"
  tokenCapitalizationSol="$totalSupplySol"
}

function get_program_account_balance_totals {
  PROGRAM_NAME="$1"
  quiet="$2"

  accountBalancesLamports="$(cat "${PROGRAM_NAME}_account_data.json" | \
    jq '.result | .[] | .[1] | .lamports')"

  totalAccountBalancesLamports=0
  numberOfAccounts=0

  for account in ${accountBalancesLamports[@]}; do
    totalAccountBalancesLamports=$((totalAccountBalancesLamports + account))
    numberOfAccounts=$((numberOfAccounts + 1))
  done

  totalAccountBalancesSol=$((totalAccountBalancesLamports / LAMPORTS_PER_SOL))

  if [[ -z $quiet ]]; then
    printf "\n--- %s Account Balance Totals ---\n" "$PROGRAM_NAME"
    printf "Number of %s Program accounts: %'.f\n" "$PROGRAM_NAME" "$numberOfAccounts"
    printf "Total token balance in all %s accounts: %s SOL\n" "$PROGRAM_NAME" "$totalAccountBalancesSol"
    printf "Total token balance in all %s accounts: %s Lamports\n" "$PROGRAM_NAME" "$totalAccountBalancesLamports"
  fi

  case $PROGRAM_NAME in
    SYSTEM)
      systemAccountBalanceTotalSol=$totalAccountBalancesSol
      systemAccountBalanceTotalLamports=$totalAccountBalancesLamports
      ;;
    STAKE)
      stakeAccountBalanceTotalSol=$totalAccountBalancesSol
      stakeAccountBalanceTotalLamports=$totalAccountBalancesLamports
      ;;
    VOTE)
      voteAccountBalanceTotalSol=$totalAccountBalancesSol
      voteAccountBalanceTotalLamports=$totalAccountBalancesLamports
      ;;
    STORAGE)
      storageAccountBalanceTotalSol=$totalAccountBalancesSol
      storageAccountBalanceTotalLamports=$totalAccountBalancesLamports
      ;;
    CONFIG)
      configAccountBalanceTotalSol=$totalAccountBalancesSol
      configAccountBalanceTotalLamports=$totalAccountBalancesLamports
      ;;
    *)
      echo "Unknown program: $PROGRAM_NAME"
      exit 1
      ;;
  esac
}

function test_sum_account_balances_capitalization {
  printf "\n--- Testing Token Capitalization vs Account Balances ---\n"
  grandTotalAccountBalancesSol=$((systemAccountBalanceTotalSol + stakeAccountBalanceTotalSol + voteAccountBalanceTotalSol + storageAccountBalanceTotalSol + configAccountBalanceTotalSol))
  printf "Total SOL in Token Capitalization: %s\n" "$tokenCapitalizationSol"
  printf "Total SOL in all Account Balances: %s\n" "$grandTotalAccountBalancesSol"

  if [[ "$grandTotalAccountBalancesSol" !=  "$tokenCapitalizationSol" ]]; then
    printf "ERROR: Difference between Capitalization and Account Balance Sum is %'.f SOL\n\n" "$((tokenCapitalizationSol - grandTotalAccountBalancesSol))"
  fi

  grandTotalAccountBalancesLamports=$((systemAccountBalanceTotalLamports + stakeAccountBalanceTotalLamports + voteAccountBalanceTotalLamports + storageAccountBalanceTotalLamports + configAccountBalanceTotalLamports))
  printf "Total Lamports in Token Capitalization: %s\n" "$tokenCapitalizationLamports"
  printf "Total Lamports in all Account Balances: %s\n" "$grandTotalAccountBalancesLamports"

  if [[ "$grandTotalAccountBalancesLamports" !=  "$tokenCapitalizationLamports" ]]; then
    printf "ERROR: Difference between Capitalization and Account Balance Sum is %s Lamports\n\n" "$((tokenCapitalizationLamports - grandTotalAccountBalancesLamports))"
  fi

}

echo "--- Querying RPC URL: $url ---"
get_cluster_version

get_program_accounts STAKE $STAKE_PROGRAM_PUBKEY $url
get_program_accounts SYSTEM $SYSTEM_PROGRAM_PUBKEY $url
get_program_accounts VOTE $VOTE_PROGRAM_PUBKEY $url
get_program_accounts STORAGE $STORAGE_PROGRAM_PUBKEY $url
get_program_accounts CONFIG $CONFIG_PROGRAM_PUBKEY $url

create_account_data_csv STAKE
create_account_data_csv SYSTEM
create_account_data_csv VOTE
create_account_data_csv STORAGE
create_account_data_csv CONFIG

get_token_capitalization #quiet

get_program_account_balance_totals STAKE #quiet
get_program_account_balance_totals SYSTEM #quiet
get_program_account_balance_totals VOTE #quiet
get_program_account_balance_totals STORAGE #quiet
get_program_account_balance_totals CONFIG #quiet

test_sum_account_balances_capitalization
