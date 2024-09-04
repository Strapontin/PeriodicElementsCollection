// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {PeriodicElementsCollection} from "../src/PeriodicElementsCollection.sol";
import {VRFCoordinatorV2Mock} from
    "../lib/chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract PeriodicElementsCollectionTest is Test {
    PeriodicElementsCollection periodicElementsCollection;
    VRFCoordinatorV2Mock public mockVRF;

    address owner = makeAddr("owner");

    function setUp() public {
        // Can ignore this. Just sets some base values
        // In real-world scenarios, you won't be deciding the
        // constructor values of the coordinator contract anyways
        vm.prank(owner);
        mockVRF = new VRFCoordinatorV2Mock(100000000000000000, 1000000000);

        // Creating a new subscription through account 0x1
        vm.prank(owner);
        uint64 subId = mockVRF.createSubscription();

        // funding the subscription with 1000 LINK
        mockVRF.fundSubscription(subId, 1000000000000000000000);

        // Creating a new instance of the main consumer contract
        periodicElementsCollection = new PeriodicElementsCollection(subId, address(periodicElementsCollection));

        // Adding the consumer contract to the subscription
        // Only owner of subscription can add consumers
        vm.prank(owner);
        mockVRF.addConsumer(subId, address(periodicElementsCollection));
    }

    function testIsAlive() public view {
        assertEq("Periodic Elements Collection", periodicElementsCollection.name());
    }

    function testRandomness() public {
        for (uint256 i = 1; i <= 1000; i++) {
            //Creating a random address using the
            //variable {i}
            //Useful to call the mint function from a 100
            //different addresses
            address addr = address(bytes20(uint160(i)));
            vm.prank(addr);
            uint256 requestID = periodicElementsCollection.mint();

            //Have to impersonate the VRFCoordinatorV2Mock contract
            //since only the VRFCoordinatorV2Mock contract
            //can call the fulfillRandomWords function
            vm.prank(address(mockVRF));
            mockVRF.fulfillRandomWords(requestID, address(periodicElementsCollection));
        }

        // //Calling the total supply function on all tokenIDs
        // //to get a final tally, before logging the values.
        // supplytracker[1] = periodicElementsCollection.totalSupply(1);
        // supplytracker[2] = periodicElementsCollection.totalSupply(2);
        // supplytracker[3] = periodicElementsCollection.totalSupply(3);

        // console2.log("Supply with tokenID 1 is " , supplytracker[1]);
        // console2.log("Supply with tokenID 2 is " , supplytracker[2]);
        // console2.log("Supply with tokenID 3 is " , supplytracker[3]);
    }
}
