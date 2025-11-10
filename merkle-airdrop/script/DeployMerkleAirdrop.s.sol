// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";
import {BleToken} from "../src/BleToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DeployMerkleAirdrop is Script {
    bytes32 stateMerkle = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
    uint256 stateAmountToTransfer = 4 * 25 * 1e18;


    function deployMerkleAirdrop() public returns (MerkleAirdrop, BleToken) {        
        vm.startBroadcast();
        BleToken token = new BleToken();
        MerkleAirdrop airdrop = new MerkleAirdrop(stateMerkle, IERC20(address(token)));
        token.mint(token.owner(), stateAmountToTransfer);
        token.transfer(address(airdrop), stateAmountToTransfer);
        vm.stopBroadcast();
        return (airdrop, token);
    }
    function run() external returns (MerkleAirdrop, BleToken) {
        return deployMerkleAirdrop();
    }
}
