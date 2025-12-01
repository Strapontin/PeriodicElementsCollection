// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IElementsData {
    struct ElementDataStruct {
        uint256 number; // Number of the element in the periodic table
        string name; // Full name of the element
        string symbol; // Short symbol of the element
        uint256 initialRam; // Initial Relative Atomic Mass of the element
        uint256 level; // Level of the element (from 1 to 7)
    }

    function getRealUserWeightsAtLevel(address user, uint256 level)
        external
        returns (uint256[] memory elementsWeight, uint256 totalWeight, uint256[] memory elementsUnlocked);
    function getElementsUnlockedByPlayer(address user) external returns (uint256[] memory);
    function getElementsUnlockedUnderLevel(uint256 level) external returns (uint256[] memory);
    function getElementArtificialRamWeight(address user, uint256 elementNumber) external returns (uint256 artificialRam);
    function getElementsAtLevel(uint256 level) external returns (uint256[] memory);
}
