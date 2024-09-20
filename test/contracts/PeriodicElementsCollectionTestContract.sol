// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {console} from "forge-std/console.sol";
import {PeriodicElementsCollection} from "../../src/PeriodicElementsCollection.sol";

contract PeriodicElementsCollectionTestContract is PeriodicElementsCollection {
    constructor(uint256 _subscriptionId, address _vrfCoordinatorV2Address, ElementDataStruct[] memory datas)
        PeriodicElementsCollection(_subscriptionId, _vrfCoordinatorV2Address, datas)
    {}

    function setUserLevel(address user, uint256 level) public {
        usersLevel[user] = level;
    }

    function getUserLevel(address user) public view returns (uint256) {
        return usersLevel[user];
    }

    function setUserElementBurnedTimes(address user, uint256 elementNumber, uint256 numBurnedTimes) public {
        burnedTimes[user][elementNumber] = numBurnedTimes;
    }

    // This function sets all elements artificialRAM to the same value,
    //  by calculating the required burned amount for each element
    //  based on the heaviest
    function setAllEllementsArtificialRamEqual() public {
        for (uint256 i = 1; i <= 118; i++) {
            uint256 burnedTimesNeeded = ((294 * 1e18) - elementsData[i].initialRAM) / 1e18;

            setUserElementBurnedTimes(msg.sender, i, burnedTimesNeeded);
        }
    }

    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {
        // pre-logic to implement for tests
        storeRandomnessResult(requestId, randomWords);
    }
}
