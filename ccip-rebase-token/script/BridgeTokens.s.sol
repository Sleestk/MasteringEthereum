//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {IRouterClient} from "@chainlink-ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink-ccip/interfaces/Client.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BridgeToken is Script {
    function run(
        address receiverAddress,
        uint64 destinationChainSelector,
        address tokenToSendAddress,
        uint256 amountToSend,
        address linkTokenAddress,
        address routerAddress
    ) public {
    //     struct EVM2AnyMessage {
    //     bytes receiver; // abi.encode(receiver address) for dest EVM chains.
    //     bytes data; // Data payload.
    //     EVMTokenAmount[] tokenAmounts; // Token transfers.
    //     address feeToken; // Address of feeToken. address(0) means you will send msg.value.
    //     bytes extraArgs; // Populate this with _argsToBytes(EVMExtraArgsV2).
    // }
        Client.EVMTokenAmount[] memory tokenAmounts = new Client.EVMTokenAmount[](1);
        tokenAmounts[0] = Client.EVMTokenAmount({
            token: tokenToSendAddress,
            amount: amountToSend
        });
        vm.startBroadcast();
        Clinet.EVM2AnyMessage message = Client.EVM2AnyMessage({
            receiver: abi.encode(receiverAddress),
            data: "",
            tokenAmounts: tokenAmounts,
            feeToken: linkTokenAddress,
            extraArgs: Clinet._argsToBytes(Client.EVMExtraArgsV2({gasLimit: 0}));
        });
        uint256 ccipFee = IRouterClient(routerAddress).getFee(destinationChainSelector, message);
        IERC20(linkTokenAddress).approve(routerAddress, ccipFee);
        IERC20(linkTokenAddress).approve(routerAddress, amountToSend);
        IRouterClient(routerAddress).ccipSend(destinationChainSelector, message);
        vm.stopBroadcast();
    }
}