// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {PeriodicElementsCollection} from "src/PeriodicElementsCollection.sol";
// import {DarkMatterTokens} from "src/DarkMatterTokens.sol";
// import {ElementsData} from "src/ElementsData.sol";
// import {HelperConfig} from "script/HelperConfig.s.sol";
// import {PECDeployer} from "script/PECDeployer.s.sol";
// import {PECTestContract, RevertOnReceive} from "test/contracts/PECTestContract.sol";

// import {Test, console2} from "forge-std/Test.sol";
// import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {PECBaseTest} from "test/PECBaseTest.t.sol";

contract PECEventTest is PECBaseTest {
    function test_mintPack_emit(uint32 packsToMint) public fundSubscriptionMax {
        packsToMint = uint32(bound(packsToMint, 1, type(uint32).max));

        vm.expectEmit(false, true, true, false, address(pec));
        emit PeriodicElementsCollection.MintRequestInitalized(0, address(alice), packsToMint);

        // Go through the process of minting a pack
        vm.prank(alice);
        pec.mintPack{value: PACK_PRICE * packsToMint}();
    }

    function test_fundingSubscription_emit(uint256 amount) public {
        amount = _bound(amount, 0, 100 ether);

        uint256[] memory ids = new uint256[](2);
        uint256[] memory values = new uint256[](2);
        ids[0] = 1; // Hydrogen
        ids[1] = 2; // Helium
        // Earns 5 hydrogen and helium per pack price send to refuel the subscription
        values[0] = amount * 5 / PACK_PRICE;
        values[1] = amount * 5 / PACK_PRICE;

        vm.expectEmit(true, true, true, false, address(pec));
        emit PeriodicElementsCollection.ElementsMinted(address(alice), ids, values);

        vm.prank(alice);
        pec.fundSubscription{value: amount}();
    }

    function test_mintFreePacks_emit() public {
        vm.warp(block.timestamp + 8 days);

        // Calculates amount of free elements minted for the event
        uint256[] memory ids = new uint256[](2);
        uint256[] memory values = new uint256[](2);
        ids[0] = 1; // Hydrogen
        ids[1] = 2; // Helium
        values[0] = 5 * 7;
        values[1] = 5 * 7;

        vm.expectEmit(false, true, true, false, address(pec));
        emit PeriodicElementsCollection.ElementsMinted(address(alice), ids, values);

        vm.startPrank(alice);
        pec.mintFreePacks();
    }

    function test_unpackRandomMatter_emit(uint256 packsToMint) public fundSubscriptionMax {
        packsToMint = bound(packsToMint, 1, NUM_MAX_PACKS_MINTED_AT_ONCE);

        vm.prank(alice);
        uint256 requestId = pec.mintPack{value: PACK_PRICE * packsToMint}();

        vm.prank(address(vrfCoordinator));
        vrfCoordinator.fulfillRandomWords(requestId, address(pec));

        uint256[] memory ids = new uint256[](2);
        uint256[] memory values = new uint256[](2);
        ids[0] = 1; // Hydrogen
        ids[1] = 2; // Helium
        // Earns 5 hydrogen and helium per pack price send to refuel the subscription
        values[0] = packsToMint * 5 / PACK_PRICE;
        values[1] = packsToMint * 5 / PACK_PRICE;

        vm.expectEmit(true, true, true, false, address(pec));
        emit PeriodicElementsCollection.ElementsMinted(address(alice), ids, values);

        pec.unpackRandomMatter(requestId);
    }

    function test_fulfillRandomWords_emit(address caller) public fundSubscriptionMax {
        vm.assume(caller != address(0));
        vm.deal(caller, PACK_PRICE);
        vm.prank(caller);
        uint256 requestId = pec.mintPack{value: PACK_PRICE}();

        vm.expectEmit(true, true, true, true, address(pec));
        emit PeriodicElementsCollection.ElementsReadyToMint(caller);

        vm.prank(address(vrfCoordinator));
        vrfCoordinator.fulfillRandomWords(requestId, address(pec));
    }

    function test_fuseToNextLevel_emit(uint256 level, bool isMatter, uint32 amountOfLinesFused) public {
        level = _bound(level, 1, 7);
        vm.assume(level != 7 || isMatter);

        amountOfLinesFused = uint32(_bound(amountOfLinesFused, 1, 100));

        pec.mintAll(alice, amountOfLinesFused);

        vm.warp(block.timestamp + 7 days);
        vm.startPrank(alice);
        pec.mintFreePacks();

        vm.expectEmit(true, true, true, true, address(pec));
        emit PeriodicElementsCollection.ElementsFused(alice, level, isMatter, amountOfLinesFused);

        pec.fuseToNextLevel(level, amountOfLinesFused, isMatter);
    }
}

/*
Events to add


event ElementsFused(address indexed user, uint256 level, bool isMatter, uint256 amountOfLinesFused);
event ElementsBurned(address indexed user, uint256[] ids, uint256[] values);
event AuthorizeTransferChanged(
    address indexed from, address indexed to, uint256 id, uint256 oldValue, uint256 newValue
);
event AddressSetAsAuthorized(address indexed from, address indexed to, bool isAuthorized);
event BigBangExploded(address indexed user, uint256 prize);


event DMTBought(address from, uint256 amount);
event DMTBurned(address from, uint256 amount);



event NewFeeReceiverProposed(address);
event NewFeeReceiverAccepted(address);
*/