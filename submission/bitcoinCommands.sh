#!/bin/bash

# Get the current block count
bitcoin-cli -regtest getblockcount

# Add more commands as needed
bitcoin-cli -regtest getblockhash 0
bitcoin-cli -regtest getbalance
