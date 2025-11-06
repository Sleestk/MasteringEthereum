// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MerkleAirdrop {
    using SafeERC20 for IERC20;
    // some list of addresses
    // allow someone in the list to claim tokens
    error MerkleAirdrop__InvalidProof();
    error MerkleAirdrop__AlreadyClaimed();

    address[] claimers;
    bytes32 private immutable I_MERKLE_ROOT;
    IERC20 private immutable I_AIRDROP_TOKEN;
    mapping(address claimer => bool claimed) private sHasClaimed;

    event Claim(address account, uint256 amount);

    constructor(bytes32 merkleRoot, IERC20 airdropToken) {
        I_MERKLE_ROOT = merkleRoot;
        I_AIRDROP_TOKEN = airdropToken;
    }

    function claim(address account, uint256 amount, bytes32[] calldata merkleProof) external {
        if (sHasClaimed[account]) {
            revert MerkleAirdrop__AlreadyClaimed();
        }
        // calculate using the account and the amount, the hash -> leaf node
        // Gas optimization: this is cheaper than hashing the input data twice
        bytes32 innerHash;
        assembly {
            // Get free memory pointer
            let ptr := mload(0x40)
            // Store account and amount in memory
            mstore(ptr, account)
            mstore(add(ptr, 32), amount)
            // Compute inner hash from 64 bytes of memory
            innerHash := keccak256(ptr, 64)
        }
        bytes32 leaf;
        assembly {
            // Get free memory pointer
            let ptr := mload(0x40)
            // Store innerHash in memory
            mstore(ptr, innerHash)
            // Compute final leaf hash from 32 bytes of memory
            leaf := keccak256(ptr, 32)
        }
        if (!MerkleProof.verify(merkleProof, I_MERKLE_ROOT, leaf)) {
            revert MerkleAirdrop__InvalidProof();
        }
        sHasClaimed[account] = true;
        emit Claim(account, amount);
        I_AIRDROP_TOKEN.safeTransfer(account, amount);
    }
}