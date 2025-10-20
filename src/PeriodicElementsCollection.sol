// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import {ElementsData} from "./ElementsData.sol";
import {DarkMatterTokens} from "./DarkMatterTokens.sol";
import {PrizePool} from "./PrizePool.sol";

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {ERC1155Supply} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

//Chainlink VRF imports
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/// @custom:security-contact
/// "strapontin" on discord
/// https://x.com/0xStrapontin on X
contract PeriodicElementsCollection is ERC1155Supply, VRFConsumerBaseV2Plus, ElementsData {
    error PEC__NoPackToMint();
    error PEC__UserDidNotPayEnough(uint256 amountMissing);
    error PEC__EthNotSend();
    error PEC__NotInReadyToMintState(VRFStatus currentStatus);
    error PEC__RequestIdAlreadyMinted();
    error PEC__LevelDoesNotExist();
    error PEC__CantFuseLastLevelOfAntimatter();
    error PEC__ZeroValue();
    error PEC__IncorrectParameters();
    error PEC__UnauthorizedTransfer();
    error PEC__UserDoesNotHaveAllElementsToCallBigBang(uint256 level);

    event MintRequestInitalized(uint256 indexed requestId, address indexed account, uint256 numPacksPaid);
    event ElementsMinted(address indexed from, uint256[] ids, uint256[] values);
    event ElementsReadyToMint(address indexed user);
    event ElementsFused(address indexed user, uint256 level, bool isMatter, uint256 amountOfLinesFused);
    event ElementsBurned(address indexed user, uint256[] ids, uint256[] values);
    event AuthorizeTransferChanged(
        address indexed from, address indexed to, uint256 id, uint256 oldValue, uint256 newValue
    );
    event AddressSetAsAuthorized(address indexed from, address indexed to, bool isAuthorized);
    event BigBangExploded(address indexed user, uint256 prize);

    enum VRFStatus {
        None,
        PendingVRFCallback,
        ReadyToMint,
        Minted
    }

    struct VRFState {
        address minterAddress;
        uint256[] randomWords;
        VRFStatus status;
        uint256 levelToMint;
    }

    mapping(uint256 => VRFState) public requestIdToVRFState;

    uint256 public constant ELEMENTS_IN_PACK = 5;
    uint256 public constant NUM_MAX_PACKS_MINTED_AT_ONCE = 100;
    uint256 public constant PACK_PRICE = 0.002 ether;
    uint256 public constant DMT_FEE_PER_TRANSFER = 0.000_005 ether;
    uint256 public constant DMT_PRICE_INCREASE_PER_UNIVERSE = 0.02 ether;

    // Chainlink Variables
    uint256 public immutable SUBSCRIPTION_ID;
    // TODO : put this value in constructor, define it in deployer.s.sol
    bytes32 constant KEY_HASH = 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c; // 750 gwei Sepolia
    uint32 constant CALLBACK_GAS_LIMIT = 1_000_000_000;
    uint16 constant BLOCK_CONFIRMATIONS = 10;

    // Gameplay variables
    DarkMatterTokens public darkMatterTokens;
    PrizePool public prizePool;
    mapping(address user => uint256 timestampLastFreeMint) lastFreeMintFromUsers;

    // Amount of an NFT authorized to be received from a transfer of a sender to our user
    mapping(address receiver => mapping(address sender => mapping(uint256 id => uint256 amount))) public
        authorizedTransfer;
    // True if sender is authorized to send any NFT to receiver
    mapping(address receiver => mapping(address sender => bool)) public authorizedAddressForTransfer;

    // Amount of transfers made by a user. Determines the DMT fee when transfering
    mapping(address user => uint256) public amountTransfers;

    constructor(
        uint256 _subscriptionId,
        address _vrfCoordinatorV2Address,
        ElementDataStruct[] memory datas,
        address feesReceiver
    )
        VRFConsumerBaseV2Plus(_vrfCoordinatorV2Address)
        ElementsData(datas)
        ERC1155(
            "https://gray-acute-wildfowl-4.mypinata.cloud/ipfs/QmcYB1e51yEXG5hosQ2N8RP8zVLTy5wUrc6523Jy21YczT/{id}.json"
        )
        ERC1155Supply()
    {
        SUBSCRIPTION_ID = _subscriptionId;
        darkMatterTokens = new DarkMatterTokens();
        prizePool = new PrizePool(feesReceiver);
    }

    // function setURI(string memory newuri) public onlyOwner {
    //     _setURI(newuri);
    // }

    function mintPack() public payable returns (uint256 requestId) {
        // If no free packs available and not enough ether send, revert
        if (msg.value < PACK_PRICE) revert PEC__UserDidNotPayEnough(PACK_PRICE - msg.value);

        uint256 numPacksPaid = msg.value / PACK_PRICE;
        uint32 numWordsToRequest = uint32(numPacksPaid * ELEMENTS_IN_PACK);

        // Too many packs minted (because of high msg.value)
        if (numPacksPaid > NUM_MAX_PACKS_MINTED_AT_ONCE) {
            numPacksPaid = NUM_MAX_PACKS_MINTED_AT_ONCE;
            numWordsToRequest = uint32(NUM_MAX_PACKS_MINTED_AT_ONCE * ELEMENTS_IN_PACK);
        }

        requestId = generateNewVrfRequest(numWordsToRequest, 0);

        uint256 leftOverEth = msg.value - (numPacksPaid * PACK_PRICE);
        prizePool.playerBoughtPacks{value: msg.value - leftOverEth}(msg.sender);

        if (leftOverEth != 0) {
            (bool sent,) = address(msg.sender).call{value: leftOverEth}("");
            if (!sent) revert PEC__EthNotSend();
        }

        emit MintRequestInitalized(requestId, msg.sender, numPacksPaid);
    }

    // levelToMint = 0 => all available elements
    function generateNewVrfRequest(uint32 numWordsToRequest, uint256 levelToMint) private returns (uint256 requestId) {
        requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: KEY_HASH,
                subId: SUBSCRIPTION_ID,
                requestConfirmations: BLOCK_CONFIRMATIONS,
                callbackGasLimit: CALLBACK_GAS_LIMIT,
                numWords: numWordsToRequest,
                extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: true}))
            })
        );

        requestIdToVRFState[requestId].minterAddress = msg.sender;
        requestIdToVRFState[requestId].status = VRFStatus.PendingVRFCallback;
        requestIdToVRFState[requestId].levelToMint = levelToMint;
    }

    function mintFreePacks() external {
        if (_mintFreePacks(msg.sender) == 0) revert PEC__NoPackToMint();
    }

    function _mintFreePacks(address user) internal returns (uint256 numPacksMinted) {
        // Registers as a player
        if (usersLevel[user] == 0) usersLevel[user] = 1;

        uint256 startOfTheDay = block.timestamp / 1 days * 1 days;
        numPacksMinted = (startOfTheDay / 1 days) - (lastFreeMintFromUsers[msg.sender] / 1 days);

        // If no free packs available and not enough ether send, revert
        if (numPacksMinted == 0) return 0;

        lastFreeMintFromUsers[msg.sender] = startOfTheDay;

        // Max 7 days free minting
        if (numPacksMinted > 7) {
            numPacksMinted = 7;
        }

        uint256[] memory ids = new uint256[](2);
        uint256[] memory values = new uint256[](2);
        ids[0] = 1; // Hydrogen
        ids[1] = 2; // Helium
        values[0] = 5 * numPacksMinted;
        values[1] = 5 * numPacksMinted;

        // Mint 5 Hydrogen and 5 Helium to the user for each pack
        _mintBatch(user, ids, values, "");

        emit ElementsMinted(user, ids, values);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal virtual override {
        requestIdToVRFState[requestId].randomWords = randomWords;
        requestIdToVRFState[requestId].status = VRFStatus.ReadyToMint;

        address user = requestIdToVRFState[requestId].minterAddress;
        emit ElementsReadyToMint(user);
    }

    function unpackRandomMatter(uint256 requestId) external returns (uint256[] memory ids, uint256[] memory values) {
        VRFState memory vrfState = requestIdToVRFState[requestId];

        if (vrfState.status == VRFStatus.Minted) revert PEC__RequestIdAlreadyMinted();
        if (vrfState.status != VRFStatus.ReadyToMint) revert PEC__NotInReadyToMintState(vrfState.status);
        requestIdToVRFState[requestId].status = VRFStatus.Minted;

        ids = new uint256[](vrfState.randomWords.length);
        values = new uint256[](vrfState.randomWords.length);
        uint256 uniqueTokenCount = 0;

        // Process each randomWord to determine the tokenId and its quantity
        uint256[] memory tokenIds = pickRandomElementAvailable(
            vrfState.minterAddress, vrfState.randomWords, requestIdToVRFState[requestId].levelToMint
        );

        for (uint256 tokenIndex = 0; tokenIndex < tokenIds.length; tokenIndex++) {
            // Check if this tokenId already exists in ids array
            bool tokenFound = false;
            for (uint256 i = 0; i < uniqueTokenCount; i++) {
                if (ids[i] == tokenIds[tokenIndex]) {
                    unchecked {
                        values[i]++; // Increase the count for this token
                    }
                    tokenFound = true;
                    break;
                }
            }

            // If tokenId is not found, add it as a new unique token
            if (!tokenFound) {
                ids[uniqueTokenCount] = tokenIds[tokenIndex];
                values[uniqueTokenCount] = 1;
                unchecked {
                    uniqueTokenCount++;
                }
            }
        }

        // Resize the arrays to the unique count
        assembly {
            mstore(ids, uniqueTokenCount)
            mstore(values, uniqueTokenCount)
        }

        // Finally, mint the tokens
        _mintBatch(vrfState.minterAddress, ids, values, "");

        emit ElementsMinted(vrfState.minterAddress, ids, values);
    }

    function fuseToNextLevel(uint256 levelToBurn, uint32 lineAmountToBurn, bool isMatter)
        external
        returns (uint256 requestId)
    {
        if (lineAmountToBurn == 0) revert PEC__ZeroValue();
        if (levelToBurn < 1 || levelToBurn > 7) revert PEC__LevelDoesNotExist();
        if (levelToBurn == 7 && !isMatter) revert PEC__CantFuseLastLevelOfAntimatter();

        uint256 amountElements = elementsAtLevel[levelToBurn].length;
        uint256 matterOffset = isMatter ? 0 : ANTIMATTER_OFFSET;

        uint256[] memory ids = new uint256[](amountElements);
        uint256[] memory values = new uint256[](amountElements);

        for (uint256 i = 0; i < amountElements; i++) {
            ids[i] = elementsAtLevel[levelToBurn][i] + matterOffset;
            values[i] = lineAmountToBurn;
        }

        _burnBatch(msg.sender, ids, values);

        // Lvl up if user reaches a new tier
        if (usersLevel[msg.sender] == levelToBurn && levelToBurn < 7) usersLevel[msg.sender]++;

        uint256 levelToMint = levelToBurn + 1;
        if (levelToMint == 8) levelToMint = ANTIMATTER_OFFSET + 1;

        emit ElementsFused(msg.sender, levelToBurn, isMatter, lineAmountToBurn);

        // Need to request X new random element from the next level
        return generateNewVrfRequest(lineAmountToBurn, levelToMint);
    }

    /* Burn Functions */

    // This function burns an amount of elements to make them less likely to drop randomly
    function increaseRelativeAtomicMass(uint256[] memory ids, uint256[] memory values) external {
        if (ids.length == 0) revert PEC__IncorrectParameters();

        _burnBatch(msg.sender, ids, values);

        // Increase by 1 to burn the correct amount
        uint256 userUniversesCreated = universesCreated[msg.sender] + 1;

        // Update the RAM of the elements
        for (uint256 i = 0; i < ids.length; i++) {
            if (ids[i] > ANTIMATTER_OFFSET) {
                // Burning an antimatter increase RAM by 100
                burnedTimes[msg.sender][ids[i]] += values[i] * 100 * userUniversesCreated;
            } else {
                burnedTimes[msg.sender][ids[i]] += values[i] * userUniversesCreated;
            }
        }

        emit ElementsBurned(msg.sender, ids, values);
    }

    /* Transfers */

    // @info: These authorization functions allow `from` to send NFTs to `msg.sender`
    // When a player receives an NFT, they have to pay fees, hence the need to authorize sender.

    function addAuthorizeTransfer(address from, uint256 id, uint256 addValue) external {
        uint256 oldValue = authorizedTransfer[msg.sender][from][id];
        authorizedTransfer[msg.sender][from][id] += addValue;
        uint256 newValue = authorizedTransfer[msg.sender][from][id];

        emit AuthorizeTransferChanged(from, msg.sender, id, oldValue, newValue);
    }

    function decreaseAuthorizeTransfer(address from, uint256 id, uint256 removeValue) external {
        uint256 oldValue = authorizedTransfer[msg.sender][from][id];

        if (authorizedTransfer[msg.sender][from][id] < removeValue) authorizedTransfer[msg.sender][from][id] = 0;
        else authorizedTransfer[msg.sender][from][id] -= removeValue;

        uint256 newValue = authorizedTransfer[msg.sender][from][id];

        emit AuthorizeTransferChanged(from, msg.sender, id, oldValue, newValue);
    }

    function setAuthorizedAddressForTransfer(address from, bool isAuthorized) external {
        authorizedAddressForTransfer[msg.sender][from] = isAuthorized;
        emit AddressSetAsAuthorized(from, msg.sender, isAuthorized);
    }

    function _update(address from, address to, uint256[] memory ids, uint256[] memory values)
        internal
        override(ERC1155Supply)
    {
        // Only do these if users are transfering (not minting or burning)
        if (from != address(0) && to != address(0)) {
            // A player receiving an NFT must accept the transfer
            _handlerNftReception(from, to, ids, values);

            // players who send/receive NFTs need to pay DMT fee
            _payFees(from, to, values);
        }

        super._update(from, to, ids, values);
    }

    function _handlerNftReception(address from, address to, uint256[] memory ids, uint256[] memory values) internal {
        // If the receiver is not a player, the transfer is authorized
        if (usersLevel[to] == 0) return;

        // If the sender is not authorized to send NFTs to the receiver, revert
        if (!authorizedAddressForTransfer[to][from]) {
            for (uint256 i = 0; i < ids.length; i++) {
                if (authorizedTransfer[to][from][ids[i]] < values[i]) revert PEC__UnauthorizedTransfer();
                authorizedTransfer[to][from][ids[i]] -= values[i];
            }
        }
    }

    function _payFees(address from, address to, uint256[] memory values) internal {
        _burnFeeDMT(from, values);
        _burnFeeDMT(to, values);
    }

    function _burnFeeDMT(address user, uint256[] memory values) internal {
        // If the user is not a player, no fees to pay
        if (usersLevel[user] == 0) {
            return;
        }

        uint256 start = amountTransfers[user];
        uint256 end = start;

        // Calculates the amount of DMT to burn based on current user's transfer and amount of values to send
        for (uint256 i = 0; i < values.length; i++) {
            end += values[i];
        }

        // Calculate sum of arithmetic sequence from start+1 to end
        uint256 n = end - start;
        uint256 amountToBurn = n * (start + 1 + end) / 2;

        // Update the user's transfer count and burn the fees
        amountTransfers[user] = end;
        darkMatterTokens.burn(user, DMT_FEE_PER_TRANSFER * amountToBurn);
    }

    /* End the game */

    function bigBang(address user) public {
        uint256[] memory allElements = elementsUnlockedUnderLevel[7];
        uint256[] memory idsToBurn = new uint256[](allElements.length * 2);
        uint256[] memory valuesToBurn = new uint256[](allElements.length * 2);

        // Verifies the user owns at least one of each element
        for (uint256 i = 0; i < allElements.length; i++) {
            // Matter
            idsToBurn[i] = allElements[i];
            valuesToBurn[i] = balanceOf(user, allElements[i]);
            burnedTimes[user][allElements[i]] = 0;

            if (valuesToBurn[i] == 0) {
                revert PEC__UserDoesNotHaveAllElementsToCallBigBang(allElements[i]);
            }

            // Antimatter
            idsToBurn[i + allElements.length] = allElements[i] + ANTIMATTER_OFFSET;
            valuesToBurn[i + allElements.length] = balanceOf(user, allElements[i] + ANTIMATTER_OFFSET);
            burnedTimes[user][allElements[i] + ANTIMATTER_OFFSET] = 0;

            if (valuesToBurn[i + allElements.length] == 0) {
                revert PEC__UserDoesNotHaveAllElementsToCallBigBang(allElements[i] + ANTIMATTER_OFFSET);
            }
        }

        // Burns all elements, and reset the player's level and transfers
        _burnBatch(user, idsToBurn, valuesToBurn);
        usersLevel[user] = 1;
        amountTransfers[user] = 0;

        // Earns a 1 point increase in burning
        universesCreated[user]++;

        // Increase DMT price for other users
        totalUniversesCreated++;

        // Add rewards
        uint256 prize = prizePool.playerWon(user);

        emit BigBangExploded(user, prize);
    }

    function fundSubscription() public payable {
        _mintFreePacks(msg.sender);
        
        // When users fund the subscription, they get a small amount of elements from it
        uint256[] memory ids = new uint256[](2);
        uint256[] memory values = new uint256[](2);
        ids[0] = 1; // Hydrogen
        ids[1] = 2; // Helium

        // Earns 5 hydrogen and helium per pack price send to refuel the subscription
        values[0] = msg.value * 5 / PACK_PRICE;
        values[1] = msg.value * 5 / PACK_PRICE;

        // Mint 5 Hydrogen and 5 Helium to the user for each pack
        _mintBatch(msg.sender, ids, values, "");

        emit ElementsMinted(msg.sender, ids, values);

        s_vrfCoordinator.fundSubscriptionWithNative{value: msg.value}(SUBSCRIPTION_ID);
    }
}
