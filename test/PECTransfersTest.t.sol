// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {PeriodicElementsCollection} from "src/PeriodicElementsCollection.sol";
import {DarkMatterTokens} from "src/DarkMatterTokens.sol";
import {ElementsData} from "src/ElementsData.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {PECDeployer} from "script/PECDeployer.s.sol";
import {PECTestContract} from "test/contracts/PECTestContract.sol";

import {Test, console2} from "forge-std/Test.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {FundSubscription} from "script/VRFInteractions.s.sol";
import {PECBaseTest} from "test/PECBaseTest.t.sol";
import {IERC1155Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

contract PECTransfersTest is PECBaseTest {
    function test_dmtIsNotBuyableBefore14Days() public {
        vm.expectRevert(DarkMatterTokens.DMT__DelayNotPassedYet.selector);
        dmt.buy{value: 1 ether}();

        vm.warp(block.timestamp + 14 days);

        vm.expectRevert(DarkMatterTokens.DMT__DelayNotPassedYet.selector);
        dmt.buy{value: 1 ether}();

        vm.warp(block.timestamp + 1);

        dmt.buy{value: 1 ether}();
    }

    function test_needDmtOnlyWhenTransferingToPlayer() public dmtMintable {
        pec.forceMint(alice, 1, 2);
        pec.setUserLevel(alice, 1);

        // Alice needs DMT because she is a player
        vm.startPrank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(IERC20Errors.ERC20InsufficientBalance.selector, alice, 0, DMT_FEE_PER_TRANSFER)
        );
        pec.safeTransferFrom(alice, address(bob), 1, 1, hex"01");

        dmt.buy{value: DMT_FEE_PER_TRANSFER}();
        pec.safeTransferFrom(alice, address(bob), 1, 1, hex"02"); // alice Hydrogen - 1

        // Alice now needs to buy 2x DMT for the transfer to work
        dmt.buy{value: DMT_FEE_PER_TRANSFER}();
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InsufficientBalance.selector, alice, DMT_FEE_PER_TRANSFER, DMT_FEE_PER_TRANSFER * 2
            )
        );
        pec.safeTransferFrom(alice, address(bob), 1, 1, hex"03");
        dmt.buy{value: DMT_FEE_PER_TRANSFER}();
        vm.stopPrank();

        vm.prank(bob);
        pec.mintFreePacks();

        // If Bob becomes a player, he also needs to approve Alice
        vm.prank(alice);
        vm.expectRevert(PeriodicElementsCollection.PEC__UnauthorizedTransfer.selector);
        pec.safeTransferFrom(alice, address(bob), 1, 1, hex"04");

        vm.prank(bob);
        pec.setAuthorizedAddressForTransfer(alice, true);

        // Bob now needs DMT
        vm.startPrank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(IERC20Errors.ERC20InsufficientBalance.selector, bob, 0, DMT_FEE_PER_TRANSFER)
        );
        pec.safeTransferFrom(alice, address(bob), 1, 1, hex"05");

        dmt.buy{value: DMT_FEE_PER_TRANSFER}();
        dmt.transfer(bob, DMT_FEE_PER_TRANSFER);
        pec.safeTransferFrom(alice, address(bob), 1, 1, hex"06"); // alice Hydrogen - 1

        assertEq(dmt.balanceOf(alice), 0);
        assertEq(dmt.balanceOf(bob), 0);
        assertEq(pec.balanceOf(alice, 1), 0); // 2 send to bob
        assertEq(pec.balanceOf(bob, 1), 37); // 35 free + 2 from Alice
    }

    function test_addAuthorizeTransfer() public dmtMintable {
        // We need to have both users as players, with DMT bought
        buyDmt(alice, DMT_FEE_PER_TRANSFER * 100);
        buyDmt(bob, DMT_FEE_PER_TRANSFER * 100);

        // A transfer without authorization should fail
        vm.prank(alice);
        vm.expectRevert(PeriodicElementsCollection.PEC__UnauthorizedTransfer.selector);
        pec.safeTransferFrom(alice, address(bob), 1, 1, "");

        // Authorizing 2 tokens for transfer, transfering 1, send authorizing 3 more
        vm.prank(bob);
        pec.addAuthorizeTransfer(alice, 1, 2);

        vm.prank(alice);
        pec.safeTransferFrom(alice, address(bob), 1, 1, "");

        vm.prank(bob);
        pec.addAuthorizeTransfer(alice, 1, 3);

        // Alice can now transfer 4 tokens to Bob
        vm.startPrank(alice);
        pec.safeTransferFrom(alice, address(bob), 1, 4, "");

        // She can't transfer more
        vm.expectRevert(PeriodicElementsCollection.PEC__UnauthorizedTransfer.selector);
        pec.safeTransferFrom(alice, address(bob), 1, 1, "");
    }

    function test_setAuthorizedAddressForTransfer() public dmtMintable {
        buyDmt(alice, type(uint128).max);
        buyDmt(bob, type(uint128).max);

        // A transfer without authorization should fail
        vm.prank(alice);
        vm.expectRevert(PeriodicElementsCollection.PEC__UnauthorizedTransfer.selector);
        pec.safeTransferFrom(alice, address(bob), 1, 1, hex"01");

        // Authorizing a user should allow them to transfer any and many elements
        vm.prank(bob);
        pec.setAuthorizedAddressForTransfer(alice, true);

        vm.startPrank(alice);
        pec.safeTransferFrom(alice, address(bob), 1, 10, hex"02");
        pec.safeTransferFrom(alice, address(bob), 2, 10, hex"03");
        vm.stopPrank();

        // `addAuthorizeTransfer` should not decrease if the address is authorized
        vm.prank(bob);
        pec.addAuthorizeTransfer(alice, 1, 5);

        vm.prank(alice);
        pec.safeTransferFrom(alice, address(bob), 1, 5, hex"04");
        assertEq(pec.authorizedTransfer(bob, alice, 1), 5);

        // If `authorizedAddressForTransfer` is removed, `authorizedTransfer` decrease
        vm.prank(bob);
        pec.setAuthorizedAddressForTransfer(alice, false);

        vm.prank(alice);
        pec.safeTransferFrom(alice, address(bob), 1, 5, hex"05");
        assertEq(pec.authorizedTransfer(bob, alice, 1), 0);

        vm.prank(alice);
        vm.expectRevert(PeriodicElementsCollection.PEC__UnauthorizedTransfer.selector);
        pec.safeTransferFrom(alice, address(bob), 1, 1, hex"06");
    }

    function test_dmtFeesInProgress() public dmtMintable {
        uint256 dmtStart = 1e18;

        pec.forceMint(alice, 1, 10);
        buyDmt(alice, dmtStart);
        pec.forceMint(bob, 1, 10);
        buyDmt(bob, dmtStart);

        uint256[] memory ids = new uint256[](1);
        uint256[] memory values = new uint256[](1);
        ids[0] = 1;
        values[0] = 1;

        // Sends 6 tokens in 6 transactions
        vm.startPrank(alice);
        pec.safeBatchTransferFrom(alice, address(address(0x01)), ids, values, "");
        pec.safeBatchTransferFrom(alice, address(address(0x01)), ids, values, "");
        pec.safeBatchTransferFrom(alice, address(address(0x01)), ids, values, "");
        pec.safeBatchTransferFrom(alice, address(address(0x01)), ids, values, "");
        pec.safeBatchTransferFrom(alice, address(address(0x01)), ids, values, "");
        pec.safeBatchTransferFrom(alice, address(address(0x01)), ids, values, "");
        vm.stopPrank();

        // Sends 6 tokens in 2 transactions
        vm.startPrank(bob);
        values[0] = 2;
        pec.safeBatchTransferFrom(bob, address(address(0x01)), ids, values, "");
        values[0] = 4;
        pec.safeBatchTransferFrom(bob, address(address(0x01)), ids, values, "");
        vm.stopPrank();

        uint256 timesSpendAlice = dmtStart - dmt.balanceOf(alice);
        uint256 timesSpendBob = dmtStart - dmt.balanceOf(bob);
        assertEq(timesSpendAlice, timesSpendBob);
    }

    function test_dmtFeesWhenBatched(uint32 end, uint256 split) public dmtMintable {
        vm.assume(end > 0);
        uint256 start = 1;

        split = split % end;

        pec.forceMint(alice, 1, end);
        pec.forceMint(alice, 2, end);

        uint256 n = end - start + 1;
        uint256 coefficientSum2 = n * (start + end) / 2;

        // Buys exactly the amount of DMT that should be needed
        buyDmt(alice, DMT_FEE_PER_TRANSFER * coefficientSum2);

        uint256[] memory ids = new uint256[](2);
        uint256[] memory values = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;
        values[0] = split;
        values[1] = end - split;

        vm.startPrank(alice);
        pec.safeBatchTransferFrom(alice, address(bob), ids, values, "");

        assertEq(dmt.balanceOf(alice), 0);
        assertEq(dmt.balanceOf(bob), 0);
    }

    function test_buyDmtRevertsWhenNotEnoughEtherSent(uint256 value) public dmtMintable {
        value = bound(value, 0, DMT_FEE_PER_TRANSFER - 1);

        vm.expectRevert(DarkMatterTokens.DMT__NotEnoughEtherSent.selector);
        dmt.buy{value: value}();
    }
}
