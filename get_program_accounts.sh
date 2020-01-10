# | source | this file

STAKE_PROGRAM_PUBKEY=Stake11111111111111111111111111111111111111
SYSTEM_PROGRAM_PUBKEY=11111111111111111111111111111111
VOTE_PROGRAM_PUBKEY=Vote111111111111111111111111111111111111111
STORAGE_PROGRAM_PUBKEY=Storage111111111111111111111111111111111111
CONFIG_PROGRAM_PUBKEY=Config1111111111111111111111111111111111111

function get_program_accounts {
  PROGRAM_NAME="$1"
  PROGRAM_PUBKEY="$2"
  URL="$3"

  curl -s -X POST -H "Content-Type: application/json" -d \
    '{"jsonrpc":"2.0","id":1, "method":"getProgramAccounts", "params":["'$PROGRAM_PUBKEY'"]}' $URL | jq '.' \
    > "${PROGRAM_NAME}_account_data.json"
}

function write_account_data_csv {
  PROGRAM_NAME="$1"
  csvFileName="${PROGRAM_NAME}_account_data.csv"

  echo "Account Pubkey,Lamports" > $csvFileName

  cat "${PROGRAM_NAME}_account_data.json" | \
    jq -r '(.result | .[]) | [.[0], (.[1] | .lamports)] | @csv' \
    >> $csvFileName

  echo "Wrote ${PROGRAM_NAME} account data to $csvFileName"
}
