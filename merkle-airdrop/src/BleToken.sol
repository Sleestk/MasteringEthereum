// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BleToken is ERC20, Ownable {
    constructor() ERC20("BleToken", "BLE") Ownable(msg.sender){}

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}