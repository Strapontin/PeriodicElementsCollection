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
import {PECBaseTest} from "../PECBaseTest.t.sol";
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
        vm.startPrank(alice);
        pec.mintFreePacks();

        // Alice needs DMT because she is a player
        vm.expectRevert(
            abi.encodeWithSelector(IERC20Errors.ERC20InsufficientBalance.selector, alice, 0, DMT_FEE_PER_TRANSFER)
        );
        pec.safeTransferFrom(alice, address(bob), 1, 1, "");

        dmt.buy{value: DMT_FEE_PER_TRANSFER}();
        pec.safeTransferFrom(alice, address(bob), 1, 1, "");

        // Alice now needs to buy 2x DMT for the transfer to work
        dmt.buy{value: DMT_FEE_PER_TRANSFER}();
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InsufficientBalance.selector, alice, DMT_FEE_PER_TRANSFER, DMT_FEE_PER_TRANSFER * 2
            )
        );
        pec.safeTransferFrom(alice, address(bob), 1, 1, "");
        dmt.buy{value: DMT_FEE_PER_TRANSFER}();
        vm.stopPrank();

        vm.prank(bob);
        pec.mintFreePacks();

        // If Bob becomes a player, he also needs to approve Alice
        vm.prank(alice);
        vm.expectRevert(PeriodicElementsCollection.PEC__UnauthorizedTransfer.selector);
        pec.safeTransferFrom(alice, address(bob), 1, 1, "");

        vm.prank(bob);
        pec.setAuthorizedAddressForTransfer(alice, true);

        // Bob now needs DMT
        vm.startPrank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(IERC20Errors.ERC20InsufficientBalance.selector, bob, 0, DMT_FEE_PER_TRANSFER)
        );
        pec.safeTransferFrom(alice, address(bob), 1, 1, "");

        dmt.buy{value: DMT_FEE_PER_TRANSFER}();
        dmt.transfer(bob, DMT_FEE_PER_TRANSFER);
        pec.safeTransferFrom(alice, address(bob), 1, 1, "");

        assertEq(dmt.balanceOf(alice), 0);
        assertEq(dmt.balanceOf(bob), 0);
        assertEq(pec.balanceOf(alice, 1), 33); // 35 free - 2 send to bob
        assertEq(pec.balanceOf(bob, 1), 37); // 35 free + 2 from Alice
    }

    function test_addAuthorizeTransfer() public dmtMintable {
        // We need to have both users as players, with DMT bought
        buyDmt(alice, 100);
        buyDmt(bob, 100);

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
        buyDmt(alice, 100);
        buyDmt(bob, 100);

        // A transfer without authorization should fail
        vm.prank(alice);
        vm.expectRevert(PeriodicElementsCollection.PEC__UnauthorizedTransfer.selector);
        pec.safeTransferFrom(alice, address(bob), 1, 1, "");

        // Authorizing a user should allow them to transfer any and many elements
        vm.prank(bob);
        pec.setAuthorizedAddressForTransfer(alice, true);

        vm.startPrank(alice);
        pec.safeTransferFrom(alice, address(bob), 1, 10, "");
        pec.safeTransferFrom(alice, address(bob), 2, 10, "");
        vm.stopPrank();

        // `addAuthorizeTransfer` should not decrease if the address is authorized
        vm.prank(bob);
        pec.addAuthorizeTransfer(alice, 1, 5);

        vm.prank(alice);
        pec.safeTransferFrom(alice, address(bob), 1, 5, "");
        assertEq(pec.authorizedTransfer(bob, alice, 1), 5);

        // If `authorizedAddressForTransfer` is removed, `authorizedTransfer` decrease
        vm.prank(bob);
        pec.setAuthorizedAddressForTransfer(alice, false);

        vm.prank(alice);
        pec.safeTransferFrom(alice, address(bob), 1, 5, "");
        assertEq(pec.authorizedTransfer(bob, alice, 1), 0);

        vm.prank(alice);
        vm.expectRevert(PeriodicElementsCollection.PEC__UnauthorizedTransfer.selector);
        pec.safeTransferFrom(alice, address(bob), 1, 1, "");
    }
}
