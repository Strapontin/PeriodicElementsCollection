// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./WithdrawalPool.sol";

// In this contract, "owner" is PEC
contract PrizePool is ERC20, Ownable {
    error PP__NotFeeReceiver();
    error PP__NotProposedFeeReceiver();

    WithdrawalPool public withdrawalPool;

    address public feeReceiver;
    address public proposedFeeReceiver;

    constructor(address _feeReceiver) ERC20("PEC Prize Pool", "PPP") Ownable(msg.sender) {
        feeReceiver = _feeReceiver;

        withdrawalPool = new WithdrawalPool();
    }

    function proposeNewFeeReceiver(address newFeeReceiver) external {
        if (msg.sender != feeReceiver) {
            revert PP__NotFeeReceiver();
        }

        proposedFeeReceiver = newFeeReceiver;
    }

    function acceptFeeReceiver() external {
        if (msg.sender != proposedFeeReceiver) {
            revert PP__NotProposedFeeReceiver();
        }

        feeReceiver = proposedFeeReceiver;
        proposedFeeReceiver = address(0);
    }

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

    function estimatedRewardsPerPlayer(address player) external view returns (uint256) {
        return rewardsPerShare(balanceOf(player));
    }

    function rewardsPerShare(uint256 shares) public view returns (uint256) {
        return address(this).balance * shares / totalSupply();
    }
}
