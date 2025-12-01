// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IDarkMatterTokens {
    function burn(address from, uint256 amount) external;
    function buy() external payable;
    function minAmountToSendToMint() external returns (uint256);
}
