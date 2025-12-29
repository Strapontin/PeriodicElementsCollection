// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IDarkMatterTokens} from "./interfaces/IDarkMatterTokens.sol";
import {PeriodicElementsCollection} from "./PeriodicElementsCollection.sol";

/// @custom:security-contact
/// "strapontin" on discord
/// https://x.com/0xStrapontin on X
contract DarkMatterTokens is IDarkMatterTokens, ERC20, Ownable {
    error DMT__DelayNotPassedYet();
    error DMT__NotEnoughEtherSent(uint256 minAmountToSend);

    event DMTMinted(address from, uint256 amount);
    event DMTBurned(address from, uint256 amount);

    PeriodicElementsCollection public immutable pec;

    constructor() ERC20("DarkMatterTokens", "DMT") Ownable(msg.sender) {
        pec = PeriodicElementsCollection(msg.sender);
    }

    /// @inheritdoc IDarkMatterTokens
    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
        emit DMTBurned(from, amount);
    }

    /// @inheritdoc IDarkMatterTokens
    function buy() external payable {
        uint256 amountToMint =
            msg.value * 1e18 / (1e18 + pec.totalUniversesCreated() * pec.DMT_PRICE_INCREASE_PER_UNIVERSE());

        if (amountToMint < pec.DMT_FEE_PER_TRANSFER()) {
            revert DMT__NotEnoughEtherSent(minAmountToSendToMint());
        }

        _mint(msg.sender, amountToMint);
        (bool success,) = payable(pec.prizePool()).call{value: msg.value}("");
        require(success, "PrizePool did not accept funds");
        emit DMTMinted(msg.sender, amountToMint);
    }

    /// @inheritdoc IDarkMatterTokens
    function minAmountToSendToMint() public view returns (uint256) {
        return pec.DMT_FEE_PER_TRANSFER() * (1e18 + pec.totalUniversesCreated() * pec.DMT_PRICE_INCREASE_PER_UNIVERSE())
            / 1e18;
    }
}
