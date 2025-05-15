#!/bin/bash
set -e

echo "Deploying YieldAggregator to Aptos testnet..."

# Compile
aptos move compile

# Deploy
aptos move publish --profile testnet --assume-yes

# Get address
ADDR=$(aptos account list --profile testnet | grep -oP '"account"\s*:\s*"\K[^"]+' | head -1)
echo "Deployed at: $ADDR"

# Initialize vault
aptos move run \
  --function-id $ADDR::Vault::initialize \
  --profile testnet

echo "Deployment complete!"
echo "Explorer: https://explorer.aptoslabs.com/account/$ADDR?network=testnet"
