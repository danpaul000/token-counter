#!/usr/bin/env bash

# SLP1 RPC Node
url=http://34.82.79.31:8899

if [[ -n $1 ]]; then
  url="$1"
fi

community_address_file=community_addresses.txt
foundation_address_file=foundation_addresses.txt

if [[ -f $community_address_file ]]; then
  echo $community_address_file already exists
  exit 1
fi

if [[ -f $foundation_address_file ]]; then
  echo $foundation_address_file already exists
  exit 1
fi

# Community pool
shrill_charity="BzuqQFnu7oNUeok9ZoJezpqu2vZJU7XR1PxVLkk6wwUD"
legal_gate="FwMbkDZUb78aiMWhZY4BEroAcqmnrXZV77nwrg71C57d"
cluttered_complaint="4h1rt2ic4AXwG7p3Qqhw57EMDD4c3tLYb5J3QstGA2p5"
one_thanks="3b7akieYUyCgz3Cwt5sTSErMWjg8NEygD6mbGjhGkduB"

# Foundation pool
lyrical_supermarket="GRZwoJGisLTszcxtWpeREJ98EGg8pZewhbtcrikoU7b3"
frequent_description="J51tinoLdmEdUR27LUVymrb2LB3xQo1aSHSgmbSGdj58"

pubkey_list="$(cat STAKE_account_pubkeys)"

for key in ${pubkey_list[@]}; do
  staker="$(solana show-stake-account $key | grep staker | cut -f3 -d " ")"

  case $staker in
    $shrill_charity)
      echo "shrill charity $key" >> "$community_address_file"
      ;;
    $legal_gate)
      echo "legal gate $key" >> "$community_address_file"
      ;;
    $cluttered_complaint)
      echo "cluttered complaint $key" >> "$community_address_file"
      ;;
    $one_thanks)
      echo "one thanks $key" >> "$community_address_file"
      ;;
    $lyrical_supermarket)
      echo "lyrical_supermarket $key" >> "$foundation_address_file"
      ;;
    $frequent_description)
      echo "frequent_description $key" >> "$foundation_address_file"
      ;;
    esac

done