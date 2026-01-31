// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IElementsData {
    /// @notice Element metadata structure
    /// @param number Element number (atomic number)
    /// @param name Element name
    /// @param symbol Chemical symbol
    /// @param initialRam Initial Relative Atomic Mass weight
    /// @param level Level at which element is unlocked
    struct ElementDataStruct {
        uint256 number;
        string name;
        string symbol;
        uint256 initialRam;
        uint256 level;
    }

    /// @notice Gets weighted probabilities for elements available to user at a specific level
    /// @param user Address of the user
    /// @param level Level to check availability at. 0 for all available elements to the user
    /// @return elementsWeight Array of weights for each unlocked element
    /// @return totalWeight Sum of all weights
    /// @return elementsUnlocked Array of element numbers unlocked
    function getRealUserWeightsUnderLevel(address user, uint256 level)
        external
        returns (uint256[] memory elementsWeight, uint256 totalWeight, uint256[] memory elementsUnlocked);

    /// @notice Gets the lightest element from a user at a certain level
    /// @param user The user to get the element weights from
    /// @param level The level of the user to check
    /// @return lightestElement The lightest element from the user at this level
    function getLightestElementFromUserAtLevel(address user, uint256 level)
        external
        view
        returns (uint256 lightestElement);

    /// @notice Gets all elements unlocked by a player
    /// @param user Address of the player
    /// @return Array of element numbers the player has unlocked
    function getElementsUnlockedByPlayer(address user) external returns (uint256[] memory);

    /// @notice Gets all elements unlocked below a certain level
    /// @param level Maximum level (inclusive)
    /// @return Array of element numbers unlocked at or below the level
    function getElementsUnlockedUnderLevel(uint256 level) external returns (uint256[] memory);

    /// @notice Gets the artificial RAM weight bonus for a user's element
    /// @dev Artificial RAM increases drop probability
    /// @param user Address of the user
    /// @param elementNumber Element number to check
    /// @return artificialRam Additional weight from artificial RAM
    function getElementArtificialRamWeight(address user, uint256 elementNumber) external returns (uint256 artificialRam);

    /// @notice Gets all elements that unlock at a specific level
    /// @param level Level to query
    /// @return Array of element numbers that unlock at this level
    function getElementsAtLevel(uint256 level) external returns (uint256[] memory);
}
