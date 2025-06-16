// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {IDarkMatterTokens} from "./interfaces/IDarkMatterTokens.sol";

/// @custom:security-contact
/// "strapontin" on discord
/// https://x.com/0xStrapontin on X
contract DarkMatterTokens is IDarkMatterTokens, ERC20, Ownable {
    error DMT__DelayNotPassedYet();

    uint256 public immutable delay;

    // Buying DMT is only possible after 14 days
    modifier delayHasPassed() {
        if (block.timestamp <= delay) revert DMT__DelayNotPassedYet();
        _;
    }

    constructor() ERC20("DarkMatterTokens", "DMT") Ownable(msg.sender) {
        delay = block.timestamp + 14 days;
    }

    function burn(address from, uint256 amount) public onlyOwner {
        _burn(from, amount);
    }

    function buy() public payable delayHasPassed {
        _mint(msg.sender, msg.value);
    }
}
