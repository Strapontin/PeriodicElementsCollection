// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IWithdrawalPool} from "./interfaces/IWithdrawalPool.sol";

// This contract acts as a buffer for players to withdraw their winnings
contract WithdrawalPool is IWithdrawalPool {
    error WP__NoWinnings();
    error WP__EthNotSend();

    mapping(address => uint256) public winnings;

    /// @inheritdoc IWithdrawalPool
    function newWinnings(address winner) external payable {
        winnings[winner] += msg.value;
    }

    /// @inheritdoc IWithdrawalPool
    function withdrawWinnings() external {
        uint256 amount = winnings[msg.sender];
        if (amount == 0) {
            revert WP__NoWinnings();
        }

        winnings[msg.sender] = 0;

        (bool success,) = msg.sender.call{value: amount}("");
        if (!success) {
            revert WP__EthNotSend();
        }
    }
}
