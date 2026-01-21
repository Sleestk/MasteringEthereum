# Coding Challenge: Finding Valid Transaction Parameters

## Challenge
Contract deployed to `0xa60Fa8391625163b1760f89DAc94bac2C448f897` on Polygon Amoy Testnet.
Find `tx.value` and `tx.data` that does not result in a revert.

## Solution Steps

### 1. Verify Foundry Installation
```bash
which forge
```
**Why:** Check if Foundry toolchain is installed and available in PATH before proceeding.

### 2. Initialize Foundry Project
```bash
forge init --force .
```
**Why:** Set up a new Foundry project structure with dependencies (forge-std) in the current directory. The `--force` flag allows initialization in a non-empty directory.

### 3. Fetch Contract Bytecode
```bash
cast code 0xa60Fa8391625163b1760f89DAc94bac2C448f897 --rpc-url https://rpc-amoy.polygon.technology/
```
**Why:** Retrieve the deployed contract's runtime bytecode from the blockchain to analyze its logic.

**Output:** `0x60205f8037346020525f51465f5260405f2054585460205114911416366020141615602157005b5f80fd`

### 4. Disassemble Bytecode
```bash
cast disassemble 0x60205f8037346020525f51465f5260405f2054585460205114911416366020141615602157005b5f80fd
```
**Why:** Convert the raw bytecode into human-readable EVM opcodes to understand the contract's execution logic.

**Disassembly Analysis:**
```
00000000: PUSH1 0x20          // Push 32 (0x20)
00000002: PUSH0               // Push 0
00000003: DUP1                // Duplicate 0
00000004: CALLDATACOPY        // Copy 32 bytes of calldata to memory[0]
00000005: CALLVALUE           // Get msg.value
00000006: PUSH1 0x20          // Push 32
00000008: MSTORE              // Store msg.value at memory[32]
00000009: PUSH0               // Push 0
0000000a: MLOAD               // Load calldata from memory[0]
0000000b: CHAINID             // Get chain ID
0000000c: PUSH0               // Push 0
0000000d: MSTORE              // Store chain ID at memory[0]
0000000e: PUSH1 0x40          // Push 64
00000010: PUSH0               // Push 0
00000011: KECCAK256           // Hash memory[0:64] = keccak256(chainID || msg.value)
00000012: SLOAD               // Load storage[hash]
00000013: PC                  // Program counter (19 = 0x13)
00000014: SLOAD               // Load storage[19]
00000015: PUSH1 0x20          // Push 32
00000017: MLOAD               // Load msg.value from memory[32]
00000018: EQ                  // Check if msg.value == storage[19]
00000019: SWAP2               // Swap stack items
0000001a: EQ                  // Check if calldata == storage[hash]
0000001b: AND                 // Both conditions must be true
0000001c: CALLDATASIZE        // Get calldata size
0000001d: PUSH1 0x20          // Push 32
0000001f: EQ                  // Check if calldatasize == 32
00000020: AND                 // All three conditions must be true
00000021: ISZERO              // Negate result
00000022: PUSH1 0x21          // Jump destination
00000024: JUMPI               // If any condition fails, jump to REVERT
00000025: STOP                // Success: end execution
00000026: JUMPDEST            // Revert path
00000027: PUSH0               // Push 0
00000028: DUP1                // Duplicate 0
00000029: REVERT              // Revert with no error message
```

**Contract Logic:**
The contract will NOT revert if:
1. `calldatasize == 32` (exactly 32 bytes)
2. `msg.value == storage[19]`
3. `calldata == storage[keccak256(chainID || msg.value)]`

### 5. Read Initial Storage Slots
```bash
cast storage 0xa60Fa8391625163b1760f89DAc94bac2C448f897 0 --rpc-url https://rpc-amoy.polygon.technology/
```
**Why:** Check storage slot 0 to see if it contains useful information.

**Output:** `0x290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e563`

```bash
cast storage 0xa60Fa8391625163b1760f89DAc94bac2C448f897 1 --rpc-url https://rpc-amoy.polygon.technology/
```
**Why:** Check storage slot 1 to see if it contains useful information.

**Output:** `0xb10e2d527612073b26eecdfd717e6a320cf44b4afac2b0732d9fcbe2b7fa0cf6`

### 6. Get Required msg.value from Storage Slot 19
```bash
cast storage 0xa60Fa8391625163b1760f89DAc94bac2C448f897 19 --rpc-url https://rpc-amoy.polygon.technology/
```
**Why:** The disassembly showed `PC` (0x13 = 19) followed by `SLOAD`, meaning we need the value stored at slot 19. This is the required `msg.value`.

**Output:** `0x66de8ffda797e3de9c05e8fc57b3bf0ec28a930d40b0d285d93c06501cf6a090`

### 7. Get Chain ID
```bash
cast chain-id --rpc-url https://rpc-amoy.polygon.technology/
```
**Why:** Need the chain ID (80002 for Polygon Amoy) to compute the storage slot hash `keccak256(chainID || msg.value)`.

**Output:** `80002`

### 8. Convert msg.value to Decimal
```bash
cast to-dec 0x66de8ffda797e3de9c05e8fc57b3bf0ec28a930d40b0d285d93c06501cf6a090
```
**Why:** Convert the hex value to decimal for easier reading and to use in subsequent calculations.

**Output:** `46529144392117707452946260303848603952187628831689540306122340668716214558864` wei

### 9. Compute Storage Slot for Required Calldata
```bash
cast keccak $(cast abi-encode "f(uint256,uint256)" 80002 0x66de8ffda797e3de9c05e8fc57b3bf0ec28a930d40b0d285d93c06501cf6a090)
```
**Why:** Calculate `keccak256(chainID || msg.value)` to find which storage slot contains the required calldata. The contract hashes these two values together to determine where to look for the expected calldata.

**Output:** `0x9a7c6623207a1c3a727a6bf353300be7fb9bda1c9e094cb9724c54a0fbda1b5e`

### 10. Get Required Calldata from Computed Storage Slot
```bash
cast storage 0xa60Fa8391625163b1760f89DAc94bac2C448f897 0x9a7c6623207a1c3a727a6bf353300be7fb9bda1c9e094cb9724c54a0fbda1b5e --rpc-url https://rpc-amoy.polygon.technology/
```
**Why:** Read the storage slot at the computed hash to get the exact calldata the contract expects.

**Output:** `0xd135e49a5b56186fed6c69c6451f8bb83bb42e84b7a3fde2fa8fa4ee0a494636`

### 11. Create Foundry Test File
Created `test/ContractTest.t.sol`:
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";

contract ContractTest is Test {
    address constant TARGET = 0xa60Fa8391625163b1760f89DAc94bac2C448f897;

    function setUp() public {
        vm.createSelectFork("https://rpc-amoy.polygon.technology/");
    }

    function test_FindValidTransaction() public {
        uint256 requiredValue = 0x66de8ffda797e3de9c05e8fc57b3bf0ec28a930d40b0d285d93c06501cf6a090;
        bytes32 requiredData = 0xd135e49a5b56186fed6c69c6451f8bb83bb42e84b7a3fde2fa8fa4ee0a494636;

        console.log("Testing with:");
        console.log("value = %s", vm.toString(abi.encodePacked(requiredValue)));
        console.log("data = %s", vm.toString(abi.encodePacked(requiredData)));

        bytes memory answer = abi.encodePacked(requiredValue, requiredData);
        console.log("answer: %s", vm.toString(answer));

        vm.deal(address(this), requiredValue + 1 ether);

        (bool success, bytes memory returnData) = TARGET.call{value: requiredValue}(
            abi.encodePacked(requiredData)
        );

        if (!success) {
            console.log("Transaction reverted");
            console.logBytes(returnData);
            revert("Call failed");
        }

        console.log("SUCCESS! Transaction did not revert");
        assertTrue(success, "Call should succeed");
    }
}
```
**Why:** Create a test to verify our analysis is correct by forking the actual network state and attempting the transaction with the discovered parameters.

### 12. Run Foundry Test
```bash
forge test --mt test_FindValidTransaction -vvv
```
**Why:** Execute the test to confirm that the transaction parameters we found will not cause a revert. The `-vvv` flag provides verbose output including console logs.

**Output:**
```
[PASS] test_FindValidTransaction() (gas: 31090)
Logs:
  Testing with:
  value = 0x66de8ffda797e3de9c05e8fc57b3bf0ec28a930d40b0d285d93c06501cf6a090
  data = 0xd135e49a5b56186fed6c69c6451f8bb83bb42e84b7a3fde2fa8fa4ee0a494636
  answer: 0x66de8ffda797e3de9c05e8fc57b3bf0ec28a930d40b0d285d93c06501cf6a090d135e49a5b56186fed6c69c6451f8bb83bb42e84b7a3fde2fa8fa4ee0a494636
  SUCCESS! Transaction did not revert

Suite result: ok. 1 passed; 0 failed; 0 skipped; finished in 1.52s (761.23ms CPU time)
```

## Final Answer

**Valid transaction parameters that will NOT revert:**

- **tx.value:** `46529144392117707452946260303848603952187628831689540306122340668716214558864` wei
  - (Hex: `0x66de8ffda797e3de9c05e8fc57b3bf0ec28a930d40b0d285d93c06501cf6a090`)

- **tx.data:** `0xd135e49a5b56186fed6c69c6451f8bb83bb42e84b7a3fde2fa8fa4ee0a494636`

## Key Takeaways

1. The contract uses a storage-based verification system
2. It checks three conditions: exact calldata size (32 bytes), msg.value matches storage[19], and calldata matches storage[keccak256(chainID || msg.value)]
3. The values are network-specific due to the chainID being part of the hash calculation
4. Foundry's forking feature allows us to test against live network state without spending real funds
