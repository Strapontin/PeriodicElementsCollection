// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IElementsData} from "./interfaces/IElementsData.sol";

abstract contract ElementsData is IElementsData {
    uint256 public constant ANTIMATTER_OFFSET = 1000;

    mapping(uint256 elementNumber => ElementDataStruct) public elementsData; // List of elements' datas
    mapping(uint256 level => uint256[]) public elementsAtLevel;
    mapping(uint256 level => uint256[]) public elementsUnlockedUnderLevel;
    mapping(address user => mapping(uint256 elementNumber => uint256)) public burnedTimes;
    mapping(address user => uint256) public usersLevel;

    uint256 public totalUniversesCreated;
    mapping(address user => uint256) public universesCreated;

    constructor(ElementDataStruct[] memory datas) {
        for (uint256 i = 0; i < datas.length; i++) {
            elementsData[datas[i].number] = datas[i];
            elementsAtLevel[datas[i].level].push(datas[i].number);

            // Fills lvl 1 elements in all levels, lvl 2 in all except lvl 1, ...
            for (uint256 lvl = 7; lvl >= datas[i].level; lvl--) {
                elementsUnlockedUnderLevel[lvl].push(datas[i].number);
            }
        }
    }

    // levelToMint > ANTIMATTER_OFFSET => must mint an antimatter
    function _pickRandomElementAvailable(address user, uint256[] memory randomWords, uint256 levelToMint)
        internal
        view
        returns (uint256[] memory result)
    {
        result = new uint256[](randomWords.length);
        (uint256[] memory weights, uint256 totalWeight, uint256[] memory elementsUnlocked) =
            getRealUserWeightsAtLevel(user, levelToMint);

        for (uint256 rngIndex = 0; rngIndex < randomWords.length; rngIndex++) {
            uint256 random = randomWords[rngIndex] % totalWeight;

            uint256 cumulativeWeight = 0;
            for (uint256 i = 0; i < elementsUnlocked.length; i++) {
                cumulativeWeight += weights[i];

                if (cumulativeWeight > random) {
                    result[rngIndex] = elementsUnlocked[i];

                    // 1/10k chances to be antimatter
                    if (
                        levelToMint > ANTIMATTER_OFFSET
                            || (uint256(keccak256(abi.encode(randomWords[rngIndex])))) % 10_000 == 0
                    ) {
                        result[rngIndex] += ANTIMATTER_OFFSET;
                    }

                    break;
                }
            }
        }
    }

    /* Public View Functions */

    /// @inheritdoc IElementsData
    function getRealUserWeightsAtLevel(address user, uint256 level)
        public
        view
        returns (uint256[] memory elementsWeight, uint256 totalWeight, uint256[] memory elementsUnlocked)
    {
        if (level == 0) {
            elementsUnlocked = getElementsUnlockedByPlayer(user);
        } else {
            // If the level is provided, we are going to mint random elements of this level
            if (level > ANTIMATTER_OFFSET) level -= ANTIMATTER_OFFSET;
            elementsUnlocked = getElementsAtLevel(level);
        }

        uint256 availableElementsLength = elementsUnlocked.length;

        elementsWeight = new uint256[](availableElementsLength);

        for (uint256 i = 0; i < availableElementsLength; i++) {
            elementsWeight[i] = getElementArtificialRamWeight(user, elementsUnlocked[i]);
            totalWeight += elementsWeight[i];
        }
    }

    /// @inheritdoc IElementsData
    function getElementsUnlockedByPlayer(address user) public view returns (uint256[] memory) {
        uint256 level = usersLevel[user] == 0 ? 1 : usersLevel[user];
        return elementsUnlockedUnderLevel[level];
    }

    /// @inheritdoc IElementsData
    function getElementsUnlockedUnderLevel(uint256 level) public view returns (uint256[] memory) {
        return elementsUnlockedUnderLevel[level];
    }

    /// @inheritdoc IElementsData
    function getElementArtificialRamWeight(address user, uint256 elementNumber)
        public
        view
        returns (uint256 artificialRam)
    {
        uint256 elementBaseRam = elementsData[elementNumber].initialRam;
        uint256 numBurnedTimes = burnedTimes[user][elementNumber];

        // elementBaseRam is set in deployer
        artificialRam = 1e18 / (elementBaseRam + (numBurnedTimes * 100));
    }

    /// @inheritdoc IElementsData
    function getElementsAtLevel(uint256 level) public view returns (uint256[] memory) {
        return elementsAtLevel[level];
    }
}
