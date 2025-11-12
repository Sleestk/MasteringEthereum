// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract MerkleAirdrop is EIP712{
    using SafeERC20 for IERC20;
    // some list of addresses
    // allow someone in the list to claim tokens
    error MerkleAirdrop__InvalidProof();
    error MerkleAirdrop__AlreadyClaimed();
    error MerkleAirdrop__InvalidSignature();

    address[] claimers;
    bytes32 private immutable I_MERKLE_ROOT;
    IERC20 private immutable I_AIRDROP_TOKEN;
    mapping(address claimer => bool claimed) private sHasClaimed;

    bytes32 private constant MESSAGE_TYPEHASH = keccak256(bytes("Airdrop(address account, uint256 amount)"));
    
    struct AirdropClaim {
        address account;
        uint256 amount;
    }

    event Claim(address account, uint256 amount);

    constructor(bytes32 merkleRoot, IERC20 airdropToken) EIP712("MerkleAirdrop", "1") {
        I_MERKLE_ROOT = merkleRoot;
        I_AIRDROP_TOKEN = airdropToken;
    }

    function claim(address account, uint256 amount, bytes32[] calldata merkleProof, uint8 v, bytes32 r, bytes32 s) external {
        if (sHasClaimed[account]) {
            revert MerkleAirdrop__AlreadyClaimed();
        }
        // checl the signature
        // if signature is not valid, revert
        bytes32 digest = getMessage(account, amount);
        if (ECDSA.recover(digest, v, r, s) != account) {
            revert MerkleAirdrop__InvalidSignature();
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

    function getMessage(address account, uint256 amount) public view returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(MESSAGE_TYPEHASH, AirdropClaim({account: account, amount: amount}))));
    }

    function getMerkleRoot() external view returns (bytes32) {
        return I_MERKLE_ROOT;
    }

    function getAirdropToken() external view returns (IERC20) {
        return I_AIRDROP_TOKEN;
    }

    function _isValidSignature(address account, bytes32 digest, uint8 v, bytes32 r, bytes32 s) internal pure returns (bool) {
        (address actualSinger, , ) = ECDSA.tryRecover(digest, v, r, s);
        return actualSinger == account;
    }
}