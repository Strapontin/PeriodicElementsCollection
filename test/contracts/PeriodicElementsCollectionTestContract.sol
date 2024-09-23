// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {console} from "forge-std/console.sol";
import {PeriodicElementsCollection} from "../../src/PeriodicElementsCollection.sol";

contract PeriodicElementsCollectionTestContract is PeriodicElementsCollection {
    mapping(uint256 requestId => uint256[] words) predefinedRandomWordsOfRequestId;

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

    function getVRFStateFromRequestId(uint256 requestId) public view returns (VRFState memory) {
        return requestIdToVRFState[requestId];
    }

    // This function sets all elements artificialRAM to the same value,
    //  by calculating the required burned amount for each element
    //  based on the heaviest
    function setAllEllementsArtificialRamEqual() public {
        for (uint256 i = 1; i <= 118; i++) {
            setUserElementBurnedTimes(msg.sender, i, 999999999999706);
        }
    }

    // Assums that all RAMs are equal to 1
    function setPredefinedRandomWords(uint256 requestId, uint256[] memory randomWords) public {
        predefinedRandomWordsOfRequestId[requestId] = randomWords;
    }

    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {
        // pre-logic to implement for tests
        uint256[] memory predefinedRandomWords = predefinedRandomWordsOfRequestId[requestId];

        if (predefinedRandomWords.length > 0) {
            console.log(
                "predefinedRandomWords.length == randomWords.length :",
                predefinedRandomWords.length == randomWords.length
            );
            require(
                predefinedRandomWords.length == randomWords.length, "Unexpected number of words compared to predefined"
            );

            storeRandomnessResult(requestId, predefinedRandomWords);
            return;
        }
        storeRandomnessResult(requestId, randomWords);
    }
}
