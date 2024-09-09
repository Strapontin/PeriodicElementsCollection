// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import {console} from "forge-std/console.sol";
import {ElementsData} from "./ElementsData.sol";
import {DarkMatterTokens} from "./DarkMatterTokens.sol";

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {ERC1155Burnable} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import {ERC1155Supply} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

//Chainlink VRF imports
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/// @custom:security-contact "strapontin" on discord. Join Cyfrin server to contact more easily.
contract PeriodicElementsCollection is ERC1155Supply, VRFConsumerBaseV2Plus, ElementsData {
    error PEC_NoPackToMint();
    error PEC_EthNotSend();

    string public constant name = "Periodic Elements Collection";

    mapping(uint256 => address) public _requestIdToMinter;

    // Chainlink Variables
    uint256 public immutable subscriptionId;
    // TODO : put this value in constructor, define it in deployer.s.sol
    bytes32 keyHash = 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c; // 750 gwei Sepolia
    uint32 callbackGasLimit = 1_000_000;
    uint16 blockConfirmations = 10;
    uint32 numWords = 1;

    // Gameplay variables
    DarkMatterTokens public immutable darkMatterTokens;
    mapping(address user => uint256 timestampLastFreeMint) lastFreeMintFromUsers;
    uint256 mintPackPrice = 0.002 ether;

    event MintRequestInitalized(uint256 indexed requestId, address indexed account);

    constructor(uint256 _subscriptionId, address _vrfCoordinatorV2Address, ElementDataStruct[] memory datas)
        VRFConsumerBaseV2Plus(_vrfCoordinatorV2Address)
        ElementsData(datas)
        ERC1155(
            "https://gray-acute-wildfowl-4.mypinata.cloud/ipfs/QmcYB1e51yEXG5hosQ2N8RP8zVLTy5wUrc6523Jy21YczT/{id}.json"
        )
        ERC1155Supply()
    {
        subscriptionId = _subscriptionId;
        darkMatterTokens = new DarkMatterTokens();
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function mintPack() public payable returns (uint256 requestId) {
        // The next two lines returns the timestamp at the start of the day
        uint256 startOfTheDay = block.timestamp / 1 days;
        startOfTheDay = startOfTheDay * 1 days;

        uint256 lastFreeMint = lastFreeMintFromUsers[msg.sender];
        uint256 numOfFreePacksAvailable = (startOfTheDay / 1 days) - (lastFreeMint / 1 days);

        // If no free packs available and not enough ether send, revert
        if (numOfFreePacksAvailable == 0 && msg.value < mintPackPrice) {
            revert PEC_NoPackToMint();
        }

        lastFreeMint = block.timestamp;

        // Max 7 days free minting
        if (numOfFreePacksAvailable > 7) {
            numOfFreePacksAvailable = 7;
        }

        uint256 numOfPaidPacksToMint = msg.value / mintPackPrice;
        uint256 elementsInPack = 5;
        uint32 totalNumElementsToMint = uint32((numOfFreePacksAvailable + numOfPaidPacksToMint) * elementsInPack);
        require(totalNumElementsToMint < 100, "Too many packs to mint");

        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient.RandomWordsRequest({
            keyHash: keyHash,
            subId: subscriptionId,
            requestConfirmations: blockConfirmations,
            callbackGasLimit: callbackGasLimit,
            numWords: totalNumElementsToMint,
            extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false}))
        });

        requestId = s_vrfCoordinator.requestRandomWords(request);

        _requestIdToMinter[requestId] = msg.sender;

        uint256 leftOverEth = msg.value - (mintPackPrice * numOfPaidPacksToMint);
        if (leftOverEth != 0) {
            (bool sent,) = address(msg.sender).call{value: leftOverEth}("");
            if (!sent) revert PEC_EthNotSend();
        }

        emit MintRequestInitalized(requestId, msg.sender);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {
        address accountMinting = _requestIdToMinter[requestId];

        uint256[] memory ids = new uint256[](240);
        uint256[] memory values = new uint256[](240);

        // The minted element is selected from :
        //  - the elements under playerLevel
        //  - relative to the available elements RAM

        // For each randomWords, we mint one card
        for (uint256 wordsId = 0; wordsId < randomWords.length; wordsId++) {
            // If the number is a multiple of 10_000, the minted element is antimatter
            uint256 tokenId = pickRandomElementAvailable(randomWords[wordsId]);

            console.log("randomWords[wordId]", randomWords[wordsId]);
            if (randomWords[wordsId] % 2 == 0) {
                // This is an antimatter element
                tokenId += 10_000;
                // why doesn't this throw ? forge test -vvv --mt test1Random
                require(false, "PERFECT ! AN ANTIMATTER");
            }

            // Updates the number of elementsToMint
            uint256 firstZeroValueIndex = 999;
            for (uint256 i = 0; i < ids.length; i++) {
                if (ids[i] == tokenId) {
                    values[i]++;
                    break;
                } else if (ids[i] == 0) {
                    firstZeroValueIndex = i;
                    break;
                }
            }
            // Adds the element to mint if first of pack
            if (firstZeroValueIndex != 999) {
                ids[firstZeroValueIndex] = tokenId;
                values[firstZeroValueIndex] = 1;
            }
        }

        // Finally mint the tokens
        _mintBatch(accountMinting, ids, values, "");
    }

    function getElementsUnlockedUnderLevel(uint256 level) public view returns (uint256[] memory) {
        return elementsUnlockedUnderLevel[level];
    }

    function _update(address from, address to, uint256[] memory ids, uint256[] memory values)
        internal
        override(ERC1155Supply)
    {
        // put the code to run **before** the transfer HERE
        super._update(from, to, ids, values);
    }
}
