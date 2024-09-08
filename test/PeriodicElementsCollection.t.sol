// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {PeriodicElementsCollection} from "../src/PeriodicElementsCollection.sol";
import {DarkMatterTokens} from "../src/DarkMatterTokens.sol";
import {ElementsData} from "../src/ElementsData.sol";
import {PeriodicElementsCollectionDeployer} from "../script/PeriodicElementsCollection.s.sol";

import {Test, console} from "forge-std/Test.sol";
import {VRFCoordinatorV2Mock} from
    "../lib/chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract PeriodicElementsCollectionTest is Test {
    PeriodicElementsCollection periodicElementsCollection;
    DarkMatterTokens darkMatterTokens;
    VRFCoordinatorV2Mock public mockVRF;

    address owner = makeAddr("owner");

    function setUp() public {
        darkMatterTokens = new DarkMatterTokens(owner);

    }

    function testIsAlive() public {
        vm.startPrank(owner);
        (periodicElementsCollection, mockVRF) = (new PeriodicElementsCollectionDeployer()).run();
        vm.stopPrank();
        
        assert(address(periodicElementsCollection) != address(0));
        assertEq(owner, periodicElementsCollection.owner());
        uint64 subId = periodicElementsCollection.subscriptionId();

        // funding the subscription with 1000 LINK
        mockVRF.fundSubscription(subId, 1000000000000000000000);

        // Adding the consumer contract to the subscription
        // Only owner of subscription can add consumers
        vm.prank(owner);
        mockVRF.addConsumer(subId, address(periodicElementsCollection));

        assertEq("Periodic Elements Collection", periodicElementsCollection.name());
        (uint8 number, string memory name, string memory symbol, uint256 ram, uint8 level) =
            periodicElementsCollection.elementsData(1);

        assertEq(1, number);
        assertEq("Hydrogen", name);
        assertEq("H", symbol);
        assertEq(1.008 * 1e18, ram);
        assertEq(1, level);
    }

    function notestRandomness() public {
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
