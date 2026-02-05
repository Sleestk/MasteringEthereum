## 🌳 Merkle Trees & Cryptographic Proofs

This repository includes a **Merkle Airdrop** implementation (`/merkle-airdrop`) that demonstrates advanced data structures and cryptographic techniques used in Ethereum. Understanding these concepts is critical for building efficient, secure, and scalable blockchain applications.

### What is a Merkle Tree?

A **Merkle Tree** (also called a hash tree) is a data structure that enables efficient and secure verification of large datasets. It's a binary tree where:

- **Leaf nodes** contain hashes of data (e.g., `hash(address, amount)`)
- **Internal nodes** contain hashes of their child nodes
- **Root node** (Merkle Root) represents the entire dataset with a single hash

#### Tree Structure Example

```
                    Root Hash
                   /          \
            Hash(A,B)          Hash(C,D)
            /      \           /      \
        Hash(A)  Hash(B)   Hash(C)  Hash(D)
          |        |         |        |
        Data A   Data B   Data C   Data D
```

#### DSA Properties

**Time Complexity:**
- Construction: `O(n)` where n = number of leaves
- Proof generation: `O(log n)` - only need sibling nodes along path to root
- Proof verification: `O(log n)` - hash upward from leaf to root

**Space Complexity:**
- Tree storage: `O(n)` for all nodes
- Proof storage: `O(log n)` - only sibling hashes needed
- On-chain storage: `O(1)` - only root hash stored!

**Why Use Merkle Trees in Ethereum?**

1. **Gas Efficiency**: Store only the root hash (32 bytes) on-chain instead of entire dataset
2. **Scalability**: Verify membership with logarithmic proof size
3. **Immutability**: Any change to data changes the root hash
4. **Privacy**: Reveal only necessary data for verification

### Merkle Proof Verification

A **Merkle Proof** is a cryptographic proof that a specific piece of data belongs to a Merkle Tree without revealing the entire tree.

#### How Merkle Proofs Work

Given a leaf node, a Merkle Proof consists of:
1. The leaf data (e.g., address and amount)
2. Sibling hashes along the path from leaf to root
3. The Merkle Root (stored on-chain)

**Verification Algorithm:**

```solidity
// Start with the leaf hash
bytes32 computedHash = keccak256(abi.encodePacked(data));

// Hash with siblings up to the root
for (uint256 i = 0; i < proof.length; i++) {
    bytes32 proofElement = proof[i];

    if (computedHash <= proofElement) {
        // Hash(current, sibling)
        computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
    } else {
        // Hash(sibling, current)
        computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
    }
}

// Verify computed root matches stored root
return computedHash == merkleRoot;
```

**Example from `/merkle-airdrop`:**

To claim 25 tokens for address `0xf39F...`, you need:
- **Leaf**: `hash(hash(address, amount))` (double hash prevents preimage attacks)
- **Proof**: `[0xd144...c6ad, 0xe5eb...6576]` (sibling hashes)
- **Root**: Stored in `MerkleAirdrop` contract

The contract verifies without knowing all eligible addresses - it only checks:
```solidity
MerkleProof.verify(merkleProof, I_MERKLE_ROOT, leaf)
```

### Zero-Knowledge Properties

While the Merkle Airdrop isn't a full zero-knowledge proof (ZKP) system, it demonstrates **knowledge hiding** properties:

#### Selective Disclosure

**Traditional Approach:**
- Store all eligible addresses on-chain: `[addr1, addr2, ..., addrN]`
- Cost: `32 bytes × N addresses` (extremely expensive!)
- Privacy: Everyone can see all eligible addresses

**Merkle Approach:**
- Store only root hash: `32 bytes` total
- Cost: Fixed `O(1)` regardless of N
- Privacy: Eligible addresses remain private until claimed

#### Information Hiding

The Merkle Root reveals:
- ✅ A commitment to a dataset (the root hash)
- ❌ Nothing about the data itself (addresses, amounts, tree size)

**Users prove they're in the set without revealing:**
- Who else is eligible
- How many people are eligible
- Total distribution amounts

#### Comparison to Full Zero-Knowledge Proofs

| Property | Merkle Proof | ZK-SNARK/STARK |
|----------|--------------|----------------|
| Proof Size | `O(log n)` | `O(1)` |
| Verification | `O(log n)` hashes | `O(1)` operations |
| Privacy | Partial (hides other members) | Full (hides all) |
| Setup | None required | Trusted setup (SNARK) |
| Use Case | Membership proofs | Complex computations |

**True ZKP Enhancement:**
A full zero-knowledge implementation would allow users to prove eligibility without revealing their address even during claiming. Technologies like **zk-SNARKs** (used in Tornado Cash) could enable this.

### Implementation Details

**See the `/merkle-airdrop` folder for:**

1. **MerkleAirdrop.sol** - Smart contract using OpenZeppelin's `MerkleProof` library
2. **MakeMerkle.s.sol** - Script to generate Merkle Tree from input data
3. **Double Hashing Prevention** - `hash(hash(data))` prevents preimage attacks
4. **EIP-712 Signatures** - Users sign their claim to prevent front-running
5. **Gas Optimization** - Assembly code for efficient hashing

**Key Security Features:**

```solidity
// Prevent double claiming
mapping(address => bool) private sHasClaimed;

// Verify signature (prevents front-running)
if (ECDSA.recover(digest, v, r, s) != account) {
    revert MerkleAirdrop__InvalidSignature();
}

// Verify Merkle proof (ensures eligibility)
if (!MerkleProof.verify(merkleProof, I_MERKLE_ROOT, leaf)) {
    revert MerkleAirdrop__InvalidProof();
}
```

### Real-World Applications

**Merkle Trees in Ethereum:**
- **State Trie**: Ethereum stores account states in a Merkle Patricia Trie
- **Transaction Receipts**: Each block contains a Merkle root of receipts
- **Airdrops**: Efficient token distribution (Uniswap, ENS used this)
- **Layer 2**: Rollups use Merkle trees for state commitments

**Gas Savings Example:**

For distributing tokens to 1000 users:
- ❌ Store all addresses on-chain: ~32,000 bytes × gas costs = prohibitively expensive
- ✅ Store Merkle root: 32 bytes (>99.9% gas reduction!)

### Learn More

📂 **Merkle Airdrop Project**: `/merkle-airdrop/`
- Read the [Anvil Script Guide](merkle-airdrop/anvilScript.md) for hands-on testing
- Examine the [MerkleAirdrop contract](merkle-airdrop/src/MerkleAirdrop.sol)
- Study the [proof generation script](merkle-airdrop/script/MakeMerkle.s.sol)

## 📚 Reference Docs

- 🔗 [Foundry Book](https://book.getfoundry.sh/)
- 📘 [Mastering Ethereum](https://github.com/ethereumbook/ethereumbook)
- 🌳 [Merkle Trees Explained (Ethereum.org)](https://ethereum.org/en/developers/docs/data-structures-and-encoding/patricia-merkle-trie/)
- 🔐 [OpenZeppelin MerkleProof](https://docs.openzeppelin.com/contracts/4.x/api/utils#MerkleProof)