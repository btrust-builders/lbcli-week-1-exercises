#!/bin/bash

# ========================================================================
# HELPER FUNCTIONS (PROVIDED - you don't need to modify these)
# ========================================================================

# Helper function to format JSON output
format_json() {
  # This uses jq if available, otherwise falls back to a simple echo
  if command -v jq &> /dev/null; then
    echo "$1" | jq .
  else
    echo "$1"
  fi
}

# Helper function to mine some blocks and get coins (not part of the exercises)
mine_blocks() {
  local num_blocks=$1
  local address=$2
  echo "Generating $num_blocks blocks to $address..."
  result=$(bitcoin-cli -regtest generatetoaddress $num_blocks $address)
  echo "Mined blocks: $(echo $result | tr -d '[]"' | cut -c 1-10)... (truncated)"
  # Wait a moment for blocks to be processed
  sleep 1
}

# Helper function to show formatted wallet info
show_wallet_info() {
  local wallet=$1
  echo "=============== WALLET INFO for $wallet ==============="
  info=$(bitcoin-cli -regtest -rpcwallet=$wallet getwalletinfo)
  echo "Balance: $(echo $info | grep -o '"balance":[^,]*' | cut -d':' -f2) BTC"
  echo "TX Count: $(echo $info | grep -o '"txcount":[^,]*' | cut -d':' -f2)"
  echo "======================================================="
}

# Helper function to prepare the challenge scenario
setup_challenge() {
  echo "Setting up scenario: A Bitcoin treasure hunt..."
  echo "You've found a series of clues that lead to hidden bitcoin funds."
  echo "Each clue will require you to use Bitcoin Core commands to reveal the next step."
  echo "First, you'll need to create a wallet to track your discoveries."
  echo ""
}

# Helper function to check for command success
check_cmd() {
  if [ $? -ne 0 ]; then
    echo "ERROR: $1 command failed!"
    exit 1
  fi
}

# Helper function to safely ensure a wallet is available
ensure_wallet_available() {
  local wallet_name=$1
  local is_watch_only=$2

  # First check if the wallet is already in the list of loaded wallets
  if bitcoin-cli -regtest listwallets | grep -q "\"$wallet_name\""; then
    echo "Wallet '$wallet_name' is already loaded."
    return 0
  fi

  # Try to load the wallet
  if bitcoin-cli -regtest loadwallet "$wallet_name" 2>/dev/null; then
    echo "Loaded existing wallet '$wallet_name'."
    return 0
  fi

  # If loading failed, create the wallet
  echo "Creating new wallet '$wallet_name'..."
  if [ "$is_watch_only" = "true" ]; then
    bitcoin-cli -regtest createwallet "$wallet_name" true false "" false false
  else
    bitcoin-cli -regtest createwallet "$wallet_name"
  fi

  if [ $? -eq 0 ]; then
    echo "Successfully created wallet '$wallet_name'."
    return 0
  else
    echo "ERROR: Failed to create wallet '$wallet_name'!"
    return 1
  fi
}

# Helper function to send funds with explicit fee handling for regtest
send_with_fee() {
  local from_wallet=$1
  local to_address=$2
  local amount=$3
  local comment=$4
  
  echo "Sending $amount BTC from $from_wallet to $to_address..."
  
  # Use settxfee to set a reasonable fee for regtest
  bitcoin-cli -regtest -rpcwallet=$from_wallet settxfee 0.00001
  check_cmd "Setting transaction fee"
  
  # Send the transaction
  local txid=$(bitcoin-cli -regtest -rpcwallet=$from_wallet sendtoaddress "$to_address" "$amount" "$comment")
  check_cmd "Sending transaction"
  
  echo "Transaction sent! TXID: ${txid:0:16}... (truncated)"
  return 0
}

# Helper function to trim whitespace from strings
trim() {
  local var="$*"
  # Remove leading whitespace
  var="${var#"${var%%[![:space:]]*}"}"
  # Remove trailing whitespace
  var="${var%"${var##*[![:space:]]}"}"
  printf '%s' "$var"
}