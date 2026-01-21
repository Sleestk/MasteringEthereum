# Anvil Script Execution Guide

This guide covers how to execute the `Interact.s.sol` script on a local Anvil network to claim the merkle airdrop.

## Overview

The `ClaimAirdrop` script in `script/Interact.s.sol` allows a user to claim their airdrop tokens by:
- Splitting the EIP-712 signature into v, r, s components
- Calling the `claim()` function on the deployed MerkleAirdrop contract
- Providing the claimer's address, amount, merkle proof, and signature

## Prerequisites

1. Foundry installed (forge, cast, anvil)
2. MerkleAirdrop contract deployed on Anvil
3. Valid signature generated for the claim

## Step 1: Start Anvil Local Node

Start a local Ethereum node with Anvil:

```bash
anvil
```

Anvil will start with:
- Chain ID: `31337`
- RPC URL: `http://localhost:8545`
- 10 pre-funded accounts (each with 10,000 ETH)

**Important Anvil Accounts:**
- Account 0: `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266` (Claiming address)
  - Private Key: `0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80`
- Account 1: `0x70997970C51812dc3A010C7d01b50e0d17dc79C8` (Used for script execution)
  - Private Key: `0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d`

## Step 2: Execute the Claim Script

Run the script to claim the airdrop:

```bash
forge script script/Interact.s.sol:ClaimAirdrop \
  --rpc-url http://localhost:8545 \
  --private-key 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d \
  --broadcast
```

### Command Breakdown:
- `forge script` - Runs a Foundry script
- `script/Interact.s.sol:ClaimAirdrop` - Path and contract name
- `--rpc-url http://localhost:8545` - Anvil local node
- `--private-key 0x59c6...` - Private key of Account 1 (transaction sender)
- `--broadcast` - Actually sends transactions to the network

## Expected Output

```
Script ran successfully.

## Setting up 1 EVM.

==========================
Chain 31337

Estimated gas price: 1.565637113 gwei
Estimated total gas used for script: 123217
Estimated amount required: 0.000192913108152521 ETH

==========================

##### anvil-hardhat
✅  [Success] Hash: 0xaf8288cbd6f685b9a0286f77a8fd67e03110e42bf24d6eb3cec627af211f0e8d
Block: 4
Paid: 0.000061132033253088 ETH (89208 gas * 0.685275236 gwei)

✅ Sequence #1 on anvil-hardhat | Total Paid: 0.000061132033253088 ETH (89208 gas * avg 0.685275236 gwei)

==========================

ONCHAIN EXECUTION COMPLETE & SUCCESSFUL.
```

### Transaction Details:
- **Transaction Hash**: `0xaf8288cbd6f685b9a0286f77a8fd67e03110e42bf24d6eb3cec627af211f0e8d`
- **Block**: 4
- **Gas Used**: 89,208
- **Gas Price**: 0.685275236 gwei
- **Total Cost**: 0.000061132033253088 ETH

## Step 3: Verify the Claim

After claiming, verify that the tokens were transferred to the claiming address.

### Check Token Balance

```bash
cast call 0x5FbDB2315678afecb367f032d93F642f64180aa3 \
  "balanceOf(address)" \
  0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
```

**Result**: `0x0000000000000000000000000000000000000000000000015af1d78b58c40000`

### Convert to Decimal

```bash
cast --to-dec 0x0000000000000000000000000000000000000000000000015af1d78b58c40000
```

**Result**: `25000000000000000000` (25 tokens with 18 decimals = 25 * 10^18)

## Script Details

### Claim Parameters (from Interact.s.sol:8-14)

```solidity
address CLAIMING_ADDRESS = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
uint256 CLAIMING_AMOUNT = 25 * 1e18;
bytes32 PROOF_ONE = 0xd1445c931158119b00449ffcac3c947d028c0c359c34a6646d95962b3b55c6ad;
bytes32 PROOF_TWO = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
bytes32[] proof = [PROOF_ONE, PROOF_TWO];
bytes private SIGNATURE = hex"a86656230d4786eff6e6754e37d04a3820f870f7bb6bc40bd7af4839f78a25d110caa18e81af62064e54278ddb4b79362546d1a02c8a2e13dfd6116ac43a6b0b1b";
```

### Signature Splitting (Interact.s.sol:23-30)

The script splits the 65-byte signature into:
- `v` (1 byte) - Recovery identifier
- `r` (32 bytes) - First part of ECDSA signature
- `s` (32 bytes) - Second part of ECDSA signature

## Transaction Files

After execution, Foundry saves transaction data:
- **Broadcast file**: `/Users/ble/MasteringEthereum/merkle-airdrop/broadcast/Interact.s.sol/31337/run-latest.json`
- **Cache file**: `/Users/ble/MasteringEthereum/merkle-airdrop/cache/Interact.s.sol/31337/run-latest.json`

## Troubleshooting

### Common Issues

1. **"Connection refused"**
   - Ensure Anvil is running on `http://localhost:8545`
   - Check that no other process is using port 8545

2. **"Invalid signature"**
   - Verify the signature was generated correctly
   - Ensure the signature matches the claiming address and amount

3. **"Already claimed"**
   - The address has already claimed their tokens
   - Restart Anvil to reset the blockchain state

4. **Cast command errors**
   - Use `--to-dec` (not `-to-dec`) for cast commands
   - Ensure you're using the latest version of Foundry: `foundryup`

## Anvil Console Output

When the script executes, Anvil logs various RPC calls:
- `eth_getTransactionCount` - Get nonce for transaction sender
- `eth_sendRawTransaction` - Broadcast signed transaction
- `eth_getTransactionReceipt` - Retrieve transaction receipt
- `eth_call` - Static call to check balances

Example transaction log:
```
Transaction: 0xaf8288cbd6f685b9a0286f77a8fd67e03110e42bf24d6eb3cec627af211f0e8d
Gas used: 89208
Block Number: 4
Block Hash: 0x701109c97ed07e0ce1cbfb918c05f657a1def114550726ea4d8b7b2ac0eee959
Block Time: "Wed, 21 Jan 2026 16:30:17 +0000"
```

## Summary

This script demonstrates the complete flow of claiming a merkle airdrop:
1. Start local Anvil network
2. Execute the claim script with proper parameters
3. Verify the tokens were transferred successfully
4. Query balance to confirm receipt of 25 tokens
