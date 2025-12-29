// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IWithdrawalPool {
    /// @notice Records new winnings for a player
    /// @dev Payable function to deposit prize money
    /// @param winner Address of the winning player
    function newWinnings(address winner) external payable;

    /// @notice Withdraws accumulated winnings to caller
    /// @dev Transfers all pending winnings to msg.sender
    function withdrawWinnings() external;
}
