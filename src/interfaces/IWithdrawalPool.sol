// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IWithdrawalPool {
    function newWinnings(address winner) external payable;
    function withdrawWinnings() external;
}
