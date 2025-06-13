// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {IDarkMatterTokens} from "./interfaces/IDarkMatterTokens.sol";

/// @custom:security-contact
/// "strapontin" on discord
/// https://x.com/0xStrapontin on X
contract DarkMatterTokens is IDarkMatterTokens, ERC20, Ownable {
    constructor() ERC20("DarkMatterTokens", "DMT") Ownable(msg.sender) {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
