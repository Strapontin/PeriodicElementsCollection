// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IPrizePool} from "./interfaces/IPrizePool.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {WithdrawalPool} from "./WithdrawalPool.sol";

// In this contract, "owner" is PEC
contract PrizePool is IPrizePool, ERC20, Ownable {
    error PP__NotFeeReceiver();
    error PP__NotProposedFeeReceiver();

    event NewFeeReceiverProposed(address);
    event NewFeeReceiverAccepted(address);

    WithdrawalPool public withdrawalPool;

    address public feeReceiver;
    address public proposedFeeReceiver;

    constructor(address _feeReceiver) ERC20("PEC Prize Pool", "PPP") Ownable(msg.sender) {
        feeReceiver = _feeReceiver;

        withdrawalPool = new WithdrawalPool();
    }

    /// @inheritdoc IPrizePool
    function proposeNewFeeReceiver(address newFeeReceiver) external {
        if (msg.sender != feeReceiver) {
            revert PP__NotFeeReceiver();
        }

        proposedFeeReceiver = newFeeReceiver;

        emit NewFeeReceiverProposed(newFeeReceiver);
    }

    /// @inheritdoc IPrizePool
    function acceptFeeReceiver() external {
        if (msg.sender != proposedFeeReceiver) {
            revert PP__NotProposedFeeReceiver();
        }

        feeReceiver = proposedFeeReceiver;
        proposedFeeReceiver = address(0);

        emit NewFeeReceiverAccepted(msg.sender);
    }

    /// @inheritdoc IPrizePool
    function playerBoughtPacks(address player) external payable onlyOwner {
        // When players pay a pack, PEC will call this function to store the ether in the pool, and mint shares for the player
        // After the fee deduction, shares are minted to the player, at a ratio of 1:1
        // This may dilute the existing shares, because buying DMT increase ether without giving shares, but is a design choice

        uint256 fee = msg.value / 100; // 1% fee
        uint256 shares = msg.value - fee;

        _mint(player, shares);

        (bool success,) = feeReceiver.call{value: fee}("");
        (success);
    }

    /// @inheritdoc IPrizePool
    function playerBoughtPacksFromDmt(address player, uint256 dmtBurned) external onlyOwner { // TODO Test
        uint256 fee = dmtBurned / 100; // 1% fee
        uint256 shares = dmtBurned - fee;

        _mint(player, shares); 
    }

    /// @inheritdoc IPrizePool
    function playerWon(address player) external onlyOwner returns (uint256 prize) {
        uint256 shares = balanceOf(player);

        if (shares == 0) {
            // Player has no shares. Either they send their shares to someone else (why), or they won the game without buying any packs (respect)
            return 0;
        }

        prize = rewardsPerShare(shares);

        _burn(player, shares);

        withdrawalPool.newWinnings{value: prize}(player);
    }

    // Called when DMT is bought
    receive() external payable {
        uint256 fee = msg.value / 100; // 1% fee
        (bool success,) = feeReceiver.call{value: fee}("");
        (success);
    }

    /* View functions */

    /// @inheritdoc IPrizePool
    function estimatedRewardsPerPlayer(address player) external view returns (uint256) {
        return rewardsPerShare(balanceOf(player));
    }

    /// @inheritdoc IPrizePool
    function rewardsPerShare(uint256 shares) public view returns (uint256) {
        return address(this).balance * shares / totalSupply();
    }
}
