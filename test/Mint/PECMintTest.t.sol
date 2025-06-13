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

contract PECMintTest is PECBaseTest {
    modifier fundSubscriptionMax() {
        fundSubscription.fundSubscription(config, type(uint256).max - 3 ether);
        _;
    }

    modifier setAllEllementsArtificialRamEqual() {
        pec.setAllEllementsArtificialRamEqual();
        _;
    }

    function test_fulfillRandomWordsCanOnlyBeCalledAfterRequestId() public {
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(0, address(pec));

        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(1, address(pec));
    }

    function test_mintingStates() public fundSubscriptionMax {
        if (user.code.length > 0) {
            return;
        }

        vm.warp(block.timestamp + 1 days);

        vm.prank(user);
        uint256 requestId = pec.mintPack{value: PACK_PRICE}();

        // Status is now Pending for VRF Callback
        assertEq(
            uint256(PeriodicElementsCollection.VRFStatus.PendingVRFCallback),
            uint256(pec.getVRFStateFromRequestId(requestId).status)
        );

        vm.prank(address(vrfCoordinator));
        vrfCoordinator.fulfillRandomWords(requestId, address(pec));

        // Status is now Ready To Mint (need EOA call)
        assertEq(
            uint256(PeriodicElementsCollection.VRFStatus.ReadyToMint),
            uint256(pec.getVRFStateFromRequestId(requestId).status)
        );

        pec.unpackRandomMatter(requestId);

        // Status is now Minted
        assertEq(
            uint256(PeriodicElementsCollection.VRFStatus.Minted),
            uint256(pec.getVRFStateFromRequestId(requestId).status)
        );
    }

    function test_payMoreShouldPayBack() public {
        // 1st test, pay 1.5 pack, should pay back 0.5
        vm.startPrank(user);
        pec.mintPack{value: PACK_PRICE + PACK_PRICE / 2}();

        assertEq(type(uint128).max - PACK_PRICE, user.balance);

        // 2nd test, should not pay more than max amount possible
        // Note that it pays back 1 more PACK_PRICE due to previous mintPack
        pec.mintPack{value: user.balance}();
        assertEq(
            type(uint128).max - (PACK_PRICE + PACK_PRICE * NUM_MAX_PACKS_MINTED_AT_ONCE), user.balance
        );
    }

    function test_mintFreePacksShouldMint5HeliumAndHydrogen() public {
        vm.warp(block.timestamp + 1e18);
        vm.startPrank(user);
        pec.mintFreePacks();

        assertEq(pec.totalSupply(), 70);
    }

    function test_mintFreeTwiceShouldNotGiveMore() public {
        vm.warp(block.timestamp + 1e18);
        vm.startPrank(user);
        pec.mintFreePacks();

        vm.expectRevert(PeriodicElementsCollection.PEC__NoPackToMint.selector);
        pec.mintFreePacks();

        assertEq(pec.totalSupply(), 70);
    }

    function test_mintFreeEveryDayShouldGive1Pack() public {
        vm.warp(block.timestamp + 1e18);
        vm.startPrank(user);
        pec.mintFreePacks();

        vm.warp(block.timestamp + 1 days);

        pec.mintFreePacks();
        assertEq(pec.totalSupply(), 80);

        vm.warp(block.timestamp + 1 days);

        pec.mintFreePacks();
        assertEq(pec.totalSupply(), 90);

        vm.warp(block.timestamp + 1 days);

        pec.mintFreePacks();
        assertEq(pec.totalSupply(), 100);
    }
}
