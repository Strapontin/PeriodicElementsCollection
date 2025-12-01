// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IPrizePool {
    function proposeNewFeeReceiver(address newFeeReceiver) external;
    function acceptFeeReceiver() external;
    function playerBoughtPacks(address player) external payable;
    function playerWon(address player) external returns (uint256 prize);
    function estimatedRewardsPerPlayer(address player) external returns (uint256);
    function rewardsPerShare(uint256 shares) external returns (uint256);
}
