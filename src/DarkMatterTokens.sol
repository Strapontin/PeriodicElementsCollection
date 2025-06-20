// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {IDarkMatterTokens} from "./interfaces/IDarkMatterTokens.sol";
import {PeriodicElementsCollection} from "./PeriodicElementsCollection.sol";

/// @custom:security-contact
/// "strapontin" on discord
/// https://x.com/0xStrapontin on X
contract DarkMatterTokens is IDarkMatterTokens, ERC20, Ownable {
    error DMT__DelayNotPassedYet();
    error DMT__NotEnoughEtherSent();

    uint256 public immutable delay;
    PeriodicElementsCollection public immutable pec;

    // Buying DMT is only possible after 14 days
    modifier delayHasPassed() {
        if (block.timestamp <= delay) revert DMT__DelayNotPassedYet();
        _;
    }

    constructor(PeriodicElementsCollection _pec) ERC20("DarkMatterTokens", "DMT") Ownable(msg.sender) {
        delay = block.timestamp + 14 days;
        pec = _pec;
    }

    function burn(address from, uint256 amount) public onlyOwner {
        _burn(from, amount);
    }

    function buy() public payable delayHasPassed {
        if (msg.value < pec.DMT_FEE_PER_TRANSFER()) {
            revert DMT__NotEnoughEtherSent();
        }

        // DMT_price = (1 / 1 + pricePerUniverseCreated) ether
        uint256 amountToMint =
            msg.value * 1e18 / (1e18 + pec.totalUniversesCreated() * pec.DMT_PRICE_INCREASE_PER_UNIVERSE());

        _mint(msg.sender, amountToMint);
    }
}
