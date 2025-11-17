// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// This contract acts as a buffer for players to withdraw their winnings
contract WithdrawalPool {
    error WP__NoWinnings();
    error WP__EthNotSend();

    mapping(address => uint256) public winnings;

    function newWinnings(address winner) external payable {
        winnings[winner] += msg.value;
    }

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
