// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {console} from "forge-std/console.sol";
import {PeriodicElementsCollection} from "src/PeriodicElementsCollection.sol";

contract PECTestContract is PeriodicElementsCollection {
    mapping(uint256 requestId => uint256[] words) predefinedRandomWordsOfRequestId;

    constructor(uint256 _subscriptionId, address _vrfCoordinatorV2Address, ElementDataStruct[] memory datas)
        PeriodicElementsCollection(_subscriptionId, _vrfCoordinatorV2Address, datas)
    {}

    function setUserLevel(address user, uint256 level) public {
        usersLevel[user] = level;
    }

    function setUserElementBurnedTimes(address user, uint256 elementNumber, uint256 numBurnedTimes) public {
        burnedTimes[user][elementNumber] = numBurnedTimes;
    }

    function setAmountTransfers(address user, uint256 value) public {
        amountTransfers[user] = value;
    }

    function getVRFStateFromRequestId(uint256 requestId) public view returns (VRFState memory) {
        return requestIdToVRFState[requestId];
    }

    function forceMint(address user, uint256 id, uint256 value) public {
        _mint(user, id, value, "");
    }

    function forceMint(address user, uint256[] memory ids, uint256[] memory values) public {
        _mintBatch(user, ids, values, "");
    }

    function mintAll(address user) public {
        mintAll(user, 1);
    }

    function mintAll(address user, uint256 times) public {
        setUserLevel(user, 7);

        uint256[] memory elementsUnlocked = getElementsUnlockedByPlayer(user);
        uint256 length = elementsUnlocked.length;
        uint256[] memory ids = new uint256[](length);
        uint256[] memory values = new uint256[](length);

        // Matter
        for (uint256 i = 0; i < length; i++) {
            ids[i] = i + 1;
            values[i] = times;
        }
        forceMint(user, ids, values);

        // Antimatter
        for (uint256 i = 0; i < length; i++) {
            ids[i] = i + 1 + ANTIMATTER_OFFSET;
            values[i] = times;
        }
        forceMint(user, ids, values);
    }
}

contract RevertOnReceive {}
