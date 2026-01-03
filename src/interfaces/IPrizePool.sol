// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IPrizePool {
    /// @notice Proposes a new fee receiver address
    /// @dev Requires two-step process for security
    /// @param newFeeReceiver Address of the proposed new fee receiver
    function proposeNewFeeReceiver(address newFeeReceiver) external;

    /// @notice Accepts the fee receiver role
    /// @dev Must be called by the proposed fee receiver
    function acceptFeeReceiver() external;

    /// @notice Records a player's pack purchase and distributes funds
    /// @dev Payable function called when player buys packs
    /// @param player Address of the player buying packs
    function playerBoughtPacks(address player) external payable;
    
    /// @notice Records a player's pack purchase and distributes funds
    /// @dev Packs paid in DMT
    /// @param player Address of the player buying packs
    function playerBoughtPacksFromDmt(address player, uint256 dmtBurned) external;

    /// @notice Processes a player's win and calculates prize
    /// @param player Address of the winning player
    /// @return prize Amount of ETH won
    function playerWon(address player) external returns (uint256 prize);

    /// @notice Estimates rewards for a specific player
    /// @param player Address of the player
    /// @return Estimated reward amount in wei
    function estimatedRewardsPerPlayer(address player) external returns (uint256);

    /// @notice Calculates rewards for a given number of shares
    /// @param shares Number of shares to calculate rewards for
    /// @return Reward amount in wei
    function rewardsPerShare(uint256 shares) external returns (uint256);
}
