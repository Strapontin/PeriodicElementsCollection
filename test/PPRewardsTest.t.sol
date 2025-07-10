// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {PeriodicElementsCollection} from "src/PeriodicElementsCollection.sol";
import {PrizePool} from "src/PrizePool.sol";
import {WithdrawalPool} from "src/WithdrawalPool.sol";
import {DarkMatterTokens} from "src/DarkMatterTokens.sol";
import {ElementsData} from "src/ElementsData.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {PECDeployer} from "script/PECDeployer.s.sol";
import {PECTestContract, RevertOnReceive} from "test/contracts/PECTestContract.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {Test, console2} from "forge-std/Test.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {FundSubscription} from "script/VRFInteractions.s.sol";
import {PECBaseTest} from "test/PECBaseTest.t.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract PPRewardsTest is PECBaseTest {
    // only fee receiver can propose a new fee receiver
    function test_onlyFeeReceiverCanProposeNewFeeReceiver() public {
        vm.prank(alice);
        vm.expectRevert(PrizePool.PP__NotFeeReceiver.selector);
        prizePool.proposeNewFeeReceiver(alice);

        vm.prank(feeReceiver);
        prizePool.proposeNewFeeReceiver(alice);

        vm.prank(bob);
        vm.expectRevert(PrizePool.PP__NotProposedFeeReceiver.selector);
        prizePool.acceptFeeReceiver();

        vm.prank(alice);
        prizePool.acceptFeeReceiver();
        assertEq(prizePool.feeReceiver(), alice);
    }

    // only owner can call functions like playerBoughtPacks and playerWon
    function test_onlyOwnerCanCallPlayerFunctions() public {
        vm.startPrank(alice);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, alice));
        prizePool.playerBoughtPacks(alice);

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, alice));
        prizePool.playerWon(alice);
        vm.stopPrank();

        // Owner can call these functions
        vm.startPrank(address(pec));
        prizePool.playerBoughtPacks(alice);
        prizePool.playerWon(alice);
    }

    // fee receiver correctly receives its fee
    function test_feeReceiverReceivesFees() public {
        vm.deal(address(pec), 100 ether);

        assertEq(feeReceiver.balance, 0);
        assertEq(prizePool.totalSupply(), 0);

        // playerBoughtPacks
        vm.prank(address(pec));
        prizePool.playerBoughtPacks{value: 100 ether}(alice);

        assertEq(address(prizePool).balance, 99 ether);
        assertEq(feeReceiver.balance, 1 ether);
        assertEq(prizePool.totalSupply(), 99 ether);
        assertEq(prizePool.balanceOf(alice), 99 ether);

        // Direct funding
        (bool success,) = address(prizePool).call{value: 100 ether}("");
        require(success, "Not Success?");

        assertEq(address(prizePool).balance, 198 ether);
        assertEq(feeReceiver.balance, 2 ether);
        assertEq(prizePool.totalSupply(), 99 ether);
        assertEq(prizePool.balanceOf(alice), 99 ether);
    }

    // When a player buys packs, he earns shares to a 1:1 ratio, regardless of other shares/funds in the pool
    function test_playerEarnsSharesWhenBuyingPacks(uint256 packsToBuy) public {
        packsToBuy = bound(packsToBuy, 1, NUM_MAX_PACKS_MINTED_AT_ONCE);
        uint256 amountPaidMinusFees = PACK_PRICE * packsToBuy - PACK_PRICE * packsToBuy / 100;

        vm.prank(alice);
        pec.mintPack{value: PACK_PRICE * packsToBuy}();

        assertEq(prizePool.balanceOf(alice), amountPaidMinusFees);
    }

    function test_payingBetweenTwoPackPriceDoesNotGrantMoreShares() public {
        // Alice sends the price of 1.5 pack
        vm.prank(alice);
        pec.mintPack{value: PACK_PRICE + PACK_PRICE / 2}();

        // She must get the shares of 1 pack
        assertEq(prizePool.balanceOf(alice), PACK_PRICE - PACK_PRICE / 100);
    }

    // When a player wins, after bigbang, they can withdraw their earnings from WithdrawalPool
    function test_bigbangAllowsPlayerToWithdrawEarnings() public {
        uint256 initialBalance = alice.balance;

        pec.mintAll(alice);

        vm.startPrank(alice);
        pec.mintPack{value: PACK_PRICE}();

        uint256 estimatedRewards = prizePool.estimatedRewardsPerPlayer(alice);
        uint256 estimatedRewardsFromShares = prizePool.rewardsPerShare(prizePool.balanceOf(alice));
        pec.bigBang(alice);

        uint256 balanceBefore = alice.balance;

        withdrawalPool.withdrawWinnings();

        assertEq(alice.balance, initialBalance - PACK_PRICE / 100); // 1% fee deducted
        assertEq(alice.balance, balanceBefore + estimatedRewards);
        assertEq(estimatedRewardsFromShares, estimatedRewards);
    }

    // A contract preventing direct transfer cannot prevent bigbang
    function test_preventDirectTransferDoesNotPreventBigBang() public {
        address revertOnReceive = address(new RevertOnReceive());
        vm.deal(revertOnReceive, PACK_PRICE);

        pec.mintAll(revertOnReceive);

        vm.startPrank(revertOnReceive);
        pec.mintPack{value: PACK_PRICE}();

        pec.bigBang(revertOnReceive);

        vm.expectRevert(WithdrawalPool.WP__EthNotSend.selector);
        withdrawalPool.withdrawWinnings();
    }

    function test_userWithNoRewardsCantClaimRewards() public {
        vm.prank(alice);
        vm.expectRevert(WithdrawalPool.WP__NoWinnings.selector);
        withdrawalPool.withdrawWinnings();
    }

    function test_multipleUsersRewardsWorkflow(uint256 aliceBoughtPacks, uint256 bobBoughtPacks, uint256 directFunding)
        public
    {
        aliceBoughtPacks = bound(aliceBoughtPacks, 0, NUM_MAX_PACKS_MINTED_AT_ONCE);
        bobBoughtPacks = bound(bobBoughtPacks, 0, NUM_MAX_PACKS_MINTED_AT_ONCE);
        directFunding = bound(directFunding, 0, address(this).balance);

        uint256 aliceValueToPay = PACK_PRICE * aliceBoughtPacks;
        uint256 bobValueToPay = PACK_PRICE * bobBoughtPacks;

        pec.mintAll(alice);
        pec.mintAll(bob);

        // We have 2 players. They will buy a random amount of packs
        if (aliceBoughtPacks > 0) {
            vm.prank(alice);
            pec.mintPack{value: aliceValueToPay}();
        }
        if (bobBoughtPacks > 0) {
            vm.prank(bob);
            pec.mintPack{value: bobValueToPay}();
        }

        // Check: Each user receives the correct number of shares in the PrizePool
        uint256 aliceExpectedShares = aliceValueToPay - aliceValueToPay / 100;
        uint256 bobExpectedShares = bobValueToPay - bobValueToPay / 100;
        assertEq(prizePool.balanceOf(alice), aliceExpectedShares, "Alice should have expected shares");
        assertEq(prizePool.balanceOf(bob), bobExpectedShares, "Bob should have expected shares");

        // Directly fund the PrizePool (simulate external funding, e.g., DMT bought)
        uint256 aliceEstimatedRewards = prizePool.estimatedRewardsPerPlayer(alice);
        uint256 bobEstimatedRewards = prizePool.estimatedRewardsPerPlayer(bob);

        (bool success,) = address(prizePool).call{value: directFunding}("");
        require(success, "Direct funding failed");

        // Check: Estimated rewards for each user (use estimatedRewardsPerPlayer and rewardsPerShare)
        uint256 aliceEstimatedRewardsAfterFunding = prizePool.estimatedRewardsPerPlayer(alice);
        uint256 bobEstimatedRewardsAfterFunding = prizePool.estimatedRewardsPerPlayer(bob);

        assert(
            aliceBoughtPacks > 0
                ? aliceEstimatedRewardsAfterFunding >= aliceEstimatedRewards
                : aliceEstimatedRewardsAfterFunding == 0
        );
        assert(
            bobBoughtPacks > 0
                ? bobEstimatedRewardsAfterFunding >= bobEstimatedRewards
                : bobEstimatedRewardsAfterFunding == 0
        );

        // Simulate some users winning (bigBang))
        aliceEstimatedRewards = prizePool.estimatedRewardsPerPlayer(alice);
        bobEstimatedRewards = prizePool.estimatedRewardsPerPlayer(bob);

        pec.bigBang(alice);

        assertApproxEqAbs(
            address(prizePool).balance,
            bobEstimatedRewards,
            1,
            "PrizePool should have Bob's winnings after Alice's bigBang"
        );

        pec.bigBang(bob);

        assertEq(address(prizePool).balance, 0, "PrizePool should be empty after both users have won");

        // Check: WithdrawalPool has the correct pending rewards for each user
        assertEq(withdrawalPool.winnings(alice), aliceEstimatedRewards, "Alice should have correct winnings");
        assertApproxEqAbs(withdrawalPool.winnings(bob), bobEstimatedRewards, 1, "Bob should have correct winnings");

        // Each user attempts to withdraw winnings:
        //     - Winning users should succeed and receive correct amount
        //     - Non-winning users should revert with WP__NoWinnings
        uint256 aliceBalanceBefore = alice.balance;
        uint256 bobBalanceBefore = bob.balance;

        if (aliceBoughtPacks > 0) {
            vm.prank(alice);
            withdrawalPool.withdrawWinnings();
        }

        if (bobBoughtPacks > 0) {
            vm.prank(bob);
            withdrawalPool.withdrawWinnings();
        }

        assertEq(alice.balance, aliceBalanceBefore + aliceEstimatedRewards, "Alice should have received her winnings");
        assertApproxEqAbs(
            bob.balance, bobBalanceBefore + bobEstimatedRewards, 1, "Bob should have received his winnings"
        );
    }
}
