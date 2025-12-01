// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IPeriodicElementsCollection {
    enum VRFStatus {
        None,
        PendingVRFCallback,
        ReadyToMint,
        Minted
    }

    struct VrfState {
        address minterAddress;
        uint256[] randomWords;
        VRFStatus status;
        uint256 levelToMint;
    }

    function mintPack() external payable returns (uint256 requestId);
    function mintFreePacks() external;
    function unpackRandomMatter(uint256 requestId) external returns (uint256[] memory ids, uint256[] memory values);
    function fuseToNextLevel(uint256 levelToBurn, uint32 lineAmountToBurn, bool isMatter)
        external
        returns (uint256 requestId);
    function increaseRelativeAtomicMass(uint256[] memory ids, uint256[] memory values) external;
    function addAuthorizeTransfer(address from, uint256 id, uint256 addValue) external;
    function decreaseAuthorizeTransfer(address from, uint256 id, uint256 removeValue) external;
    function setAuthorizedAddressForTransfer(address from, bool isAuthorized) external;
    function bigBang(address user) external;
    function fundSubscription() external payable;
}
