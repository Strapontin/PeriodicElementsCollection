// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

/// @custom:security-contact
/// "strapontin" on discord
/// https://x.com/0xStrapontin on X
contract DarkMatterTokens is ERC20, ERC20Burnable, Ownable, ERC20Permit {
    constructor() ERC20("DarkMatterTokens", "DMT") Ownable(msg.sender) ERC20Permit("DarkMatterTokens") {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
