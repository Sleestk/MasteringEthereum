// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";

contract ContractTest is Test {
    address constant TARGET = 0xa60Fa8391625163b1760f89DAc94bac2C448f897;

    function setUp() public {
        // Fork Polygon Amoy testnet
        vm.createSelectFork("https://rpc-amoy.polygon.technology/");
    }

    function test_FindValidTransaction() public {
        // Based on @CodingChallenge.md:
        // - Storage slot 19 contains the required msg.value
        // - Storage slot keccak256(chainID || msg.value) contains the required calldata

        // uint256 since cast to-dec returns a wei value
        // From cast storage 0xa60Fa8391625163b1760f89DAc94bac2C448f897 19 --rpc-url https://rpc-amoy.polygon.technology/
        uint256 requiredValue = 0x66de8ffda797e3de9c05e8fc57b3bf0ec28a930d40b0d285d93c06501cf6a090;
        // bytes32 since it uses calldata
        // From cast keccak $(cast abi-encode "f(uint256,uint256)" 80002 0x66de8ffda797e3de9c05e8fc57b3bf0ec28a930d40b0d285d93c06501cf6a090)
        // From cast storage 0xa60Fa8391625163b1760f89DAc94bac2C448f897 0x9a7c6623207a1c3a727a6bf353300be7fb9bda1c9e094cb9724c54a0fbda1b5e --rpc-url https://rpc-amoy.polygon.technology/
        bytes32 requiredData = 0xd135e49a5b56186fed6c69c6451f8bb83bb42e84b7a3fde2fa8fa4ee0a494636;

        console.log("Testing with:");
        console.log("value = %s", vm.toString(abi.encodePacked(requiredValue)));
        console.log("data = %s", vm.toString(abi.encodePacked(requiredData)));

        bytes memory answer = abi.encodePacked(requiredValue, requiredData);
        console.log("answer: %s", vm.toString(answer));

        // Fund the test contract
        vm.deal(address(this), requiredValue + 1 ether);

        // Call the target contract
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
