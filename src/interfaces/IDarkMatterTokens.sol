// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IDarkMatterTokens {
    /// @notice Burns Dark Matter Tokens when NFT are exchanged
    /// @param from Address to burn tokens from
    /// @param amount Amount of tokens to burn
    function burn(address from, uint256 amount) external;

    /// @notice Purchases Dark Matter Tokens with ETH
    /// @dev Payable function, ETH sent determines tokens received
    function buy() external payable;

    /// @notice Returns the minimum ETH required to mint DMT
    /// @return Minimum amount in wei needed to mint DMT token
    function minAmountToSendToMint() external returns (uint256);
}
