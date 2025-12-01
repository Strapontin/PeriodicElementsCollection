// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {PeriodicElementsCollection} from "src/PeriodicElementsCollection.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

contract PECTestContract is PeriodicElementsCollection {
    mapping(uint256 requestId => uint256[] words) predefinedRandomWordsOfRequestId;

    constructor(
        uint256 _subscriptionId,
        address _vrfCoordinatorV2Address,
        ElementDataStruct[] memory datas,
        address feeReceiver
    ) PeriodicElementsCollection(_subscriptionId, _vrfCoordinatorV2Address, datas, feeReceiver) {}

    function setUserLevel(address user, uint256 level) public {
        usersLevel[user] = level;
    }

    function setUserElementBurnedTimes(address user, uint256 elementNumber, uint256 numBurnedTimes) public {
        burnedTimes[user][elementNumber] = numBurnedTimes;
    }

    function setAmountTransfers(address user, uint256 value) public {
        amountTransfers[user] = value;
    }

    function getVrfStateFromRequestId(uint256 requestId) public view returns (VrfState memory) {
        return requestIdToVrfState[requestId];
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

    function setTotalUniversesCreated(uint256 newValue) public {
        totalUniversesCreated = newValue;
    }
}

contract RevertOnReceive {
    // function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure returns (bytes4) {
    //     return IERC1155Receiver.onERC1155Received.selector;
    // }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata)
        external
        pure
        returns (bytes4)
    {
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }
}
