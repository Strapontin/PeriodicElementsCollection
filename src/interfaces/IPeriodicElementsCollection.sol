// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IPeriodicElementsCollection {
    /// @notice VRF request lifecycle status
    enum VRFStatus {
        None,
        PendingVRFCallback,
        ReadyToMint,
        Minted
    }

    /// @notice State tracking for VRF randomness requests
    /// @param minterAddress Address that initiated the mint
    /// @param randomWords Random values from Chainlink VRF
    /// @param status Current status of the VRF request
    /// @param levelToMint Level at which elements will be minted
    struct VrfState {
        address minterAddress;
        uint256[] randomWords;
        VRFStatus status;
        uint256 currentUserLevel;
        uint256 currentUniversesCreated;
    }

    /// @notice Purchases and requests randomness for a pack of elements
    /// @dev Requires payment of PACK_PRICE in ETH
    /// @return requestId Chainlink VRF request ID
    function mintPack() external payable returns (uint256 requestId);

    /// @notice Purchases and requests randomness for a pack of elements
    /// @dev Requires payment of PACK_PRICE in DMT
    /// @return requestId Chainlink VRF request ID
    function mintPackWithDmt(uint256 amountPacksToMint) external returns (uint256 requestId);

    /// @notice Mints free starter packs for new players
    function mintFreePacks() external;

    /// @notice Unpacks elements after VRF randomness is fulfilled
    /// @param requestId VRF request ID to unpack
    /// @return ids Array of element token IDs minted
    /// @return values Array of quantities for each element
    function unpackRandomMatter(uint256 requestId) external returns (uint256[] memory ids, uint256[] memory values);

    /// @notice Fuses elements to create a higher level element
    /// @dev Burns multiple elements of one level to mint one of the next level
    /// @param levelToBurn Level of elements being burned
    /// @param lineAmountToBurn Number of elements to burn
    /// @param isMatter True for matter, false for antimatter
    function fuseToNextLevel(uint256 levelToBurn, uint32 lineAmountToBurn, bool isMatter) external returns (uint256);

    /// @notice Increases artificial RAM weight for elements to boost drop rates
    /// @param ids Array of element token IDs
    /// @param values Array of RAM amounts to add to each element
    function increaseRelativeAtomicMass(uint256[] memory ids, uint256[] memory values) external;

    /// @notice Authorizes additional transfer allowance for an element
    /// @param from Address granting the allowance
    /// @param id Element token ID
    /// @param addValue Amount to add to authorized transfer
    function addAuthorizeTransfer(address from, uint256 id, uint256 addValue) external;

    /// @notice Reduces authorized transfer allowance for an element
    /// @param from Address reducing the allowance
    /// @param id Element token ID
    /// @param removeValue Amount to remove from authorized transfer
    function decreaseAuthorizeTransfer(address from, uint256 id, uint256 removeValue) external;

    /// @notice Sets blanket transfer authorization for an address
    /// @param from Address granting authorization
    /// @param isAuthorized True to authorize, false to revoke
    function setAuthorizedAddressForTransfer(address from, bool isAuthorized) external;

    /// @notice Resets a user's collection and grants rewards
    /// @dev Called when player completes the collection
    /// @param user Address of the user to reset
    function bigBang(address user) external;

    /// @notice Funds the Chainlink VRF subscription with LINK
    /// @dev Payable function to add funds to subscription
    function fundSubscription() external payable;
}
