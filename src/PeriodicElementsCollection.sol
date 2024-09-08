// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import {console} from "forge-std/console.sol";
import {ElementsData} from "./ElementsData.sol";

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

//Chainlink VRF imports
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

/// @custom:security-contact "strapontin" on discord. Join Cyfrin server to contact more easily.
contract PeriodicElementsCollection is
    ERC1155,
    Ownable,
    ERC1155Burnable,
    ERC1155Supply,
    VRFConsumerBaseV2,
    ElementsData
{
    string public constant name = "Periodic Elements Collection";

    mapping(uint256 => address) public _requestIdToMinter;

    // Chainlink Variables
    VRFCoordinatorV2Interface private immutable coordinatorInterface;
    uint64 public immutable subscriptionId;
    address private immutable vrfCoordinatorV2Address;
    // TODO : put this value in constructor, define it in deployer.s.sol
    bytes32 keyHash = 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c; // 750 gwei Sepolia
    uint32 callbackGasLimit = 1_000_000;
    uint16 blockConfirmations = 10;
    uint32 numWords = 1;

    // Gameplay variables
    mapping(address user => uint256 timestampLastFreeMint) lastFreeMintFromUsers;
    uint256 mintPackPrice = 0.002 ether;

    event MintRequestInitalized(uint256 indexed requestId, address indexed account);
    event TokenMinted(address indexed account, uint256 indexed id);

    error Error_PEC_NoFreePackAvailableAndNotEnoughEtherSendToMintPack();
    error Error_PEC_EthNotSend();

    constructor(uint64 _subscriptionId, address _vrfCoordinatorV2Address, ElementDataStruct[] memory datas)
        VRFConsumerBaseV2(vrfCoordinatorV2Address)
        ElementsData(datas)
        ERC1155(
            "https://gray-acute-wildfowl-4.mypinata.cloud/ipfs/QmcYB1e51yEXG5hosQ2N8RP8zVLTy5wUrc6523Jy21YczT/{id}.json"
        )
        Ownable(msg.sender)
    {
        console.log(msg.sender);
        subscriptionId = _subscriptionId;
        vrfCoordinatorV2Address = _vrfCoordinatorV2Address;
        coordinatorInterface = VRFCoordinatorV2Interface(_vrfCoordinatorV2Address);
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function mintPack() public payable returns (uint256 requestId) {
        // The next two lines returns the timestamp at the start of the day
        uint256 startOfTheDay = block.timestamp / 1 days;
        startOfTheDay = startOfTheDay * 1 days;

        uint256 lastFreeMint = lastFreeMintFromUsers[msg.sender];
        uint256 numOfFreePacksAvailable =
            lastFreeMint > startOfTheDay ? (lastFreeMint / 1 days) - (startOfTheDay / 1 days) : 0;

        // If no free packs available and not enough ether send, revert
        if (numOfFreePacksAvailable == 0 && msg.value < mintPackPrice) {
            revert Error_PEC_NoFreePackAvailableAndNotEnoughEtherSendToMintPack();
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

        requestId = coordinatorInterface.requestRandomWords(
            keyHash, subscriptionId, blockConfirmations, callbackGasLimit, totalNumElementsToMint
        );

        _requestIdToMinter[requestId] = msg.sender;

        uint256 leftOverEth = msg.value - (mintPackPrice * numOfPaidPacksToMint);
        (bool sent,) = address(msg.sender).call{value: leftOverEth}("");
        if (!sent) revert Error_PEC_EthNotSend();

        emit MintRequestInitalized(requestId, msg.sender);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        address accountMinting = _requestIdToMinter[requestId];

        // The minted element is selected from :
        //  - the elements under playerLevel
        //  - relative to the available elements RAM

        // For each randomWords, we mint one card
        for (uint256 wordsId = 0; wordsId < randomWords.length; wordsId++) {
            // If the number is a multiple of 10_000, the minted element is antimatter
            uint256 isAntimatter = randomWords[wordsId] % 10_000;

            uint256 tokenId;

            // //manipulate the random number to get the tokenId with a variable probability
            // if (randomNumber == 100) {
            //     tokenId = 1;
            // } else if (randomNumber % 3 == 0) {
            //     tokenId = 2;
            // } else {
            //     tokenId = 3;
            // }

            // Finally mint the token
            // _mint(account, id, amount, data);
            _mint(accountMinting, tokenId, 1, "");

            // emit an event
            emit TokenMinted(accountMinting, tokenId);
        }
    }

    function getElementArtificialRelativeAtomicMass(uint8 elementNumber) public view returns (uint256 artificialRAM) {
        uint256 elementBaseRAM = elementsData[elementNumber].initialRAM;
        uint256 burnedTimes = burnedTimes[msg.sender][elementNumber];

        // 1e22 allows the heaviest burnable element to be burned (10_000 - 222) times
        artificialRAM = 1e22 / (elementBaseRAM + (burnedTimes * 1e18));
    }

    function _update(address from, address to, uint256[] memory ids, uint256[] memory values)
        internal
        override(ERC1155, ERC1155Supply)
    {
        // put the code to run **before** the transfer HERE
        super._update(from, to, ids, values);
    }
}
