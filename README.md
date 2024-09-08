# Project Documentation

The elements details in this project were taken from [this github page](https://github.com/Bowserinator/Periodic-Table-JSON)

## Description
This is a periodic elements collection game. Users can collect periodic elements.

### Cool stuff to implement :
- Signatures : Users can sign a transaction to be executed by someone else to delegate gas costs. In exchange, 20% of cards minted (1 card per mint) are given to the query executor (search ressources about this behaviour online).
- ERC1155 : The list of elements will probably be stored in an ERC1155 style contract.
- UUPSUpgradeable : The contract will need to be upgradeable in order to fix issues when they are spotted.
- Chainlink : used for randomness.

## Features
### Minting
Users can mint packs of elements. 1 pack contains **5** elements. 

The first pack minted each day is free.

If users did not mint for up to 7 days, they cumulate these free mints, allowing to mint a maximum of 7 free packs at once.

After free mints are expired, users can pay for packs. 1 pack costs `0.002 ether`. A **5% fee** goes straight to the owner (if not address(0)). The rest goes into the prize pool.

Elements minted are random using chainlink. Elements minted cannot be higher than the current level of the user (e.g. at first, lvl 1 users can only mint Hydrogen and Helium).

The randomness of the minted element depends on available elements (user level) and the relative element atomic mass (higher atomic mass has less chances to be picked).

For every element minted, there is a 1/10_000 chances to mint an antimatter element. The same rules (regarding levels) apply here.

### Batch Minting
Allows minting of multiple packs, given the amount of eth transfered.

### Minting Level
Users start at minting level 1 (Hydrogen & Helium level). When they have all elements of a level, they can burn them to earn a random element of the next level. If a user earns this way an element of the next level, they level up (can’t skip 3 levels if someone else transferred the elements).

### Selling/Buying/Transferring elements
When a transfer occurs, a `0.0005 ether` fee is taken by the contract from the previous owner of an element, to incentivize players to end the game rather than become farming machines. Every time a user sends an element, their total fee increases by `0.0005 ether`.

This fee is collected via DarkMatterTokens.

### Burning Elements
Users can burn their elements to decrease the chances they have to mint them. The more an element is burned this way, the less chances the user has to mint this element.

Elements can't be burned if they belong to the max level unlocked by the user.

### Buying DarkMatterTokens ($DMT)
$DMTs are the main currency of the game. 1 ETH = 1 DMT. 5% of ETH used to buy DMT goes straight to the owner (if not address(0)), while the rest goes to the prize pool.

$DMTs are used as fee for transferring elements.

*Users could also use them for minting paid packs, instead of ETH* (this is to be thought of)

### Antimatter
Antimatter is a rarer version of matter. Minting an element may result in an antimatter element minted with a 1/10_000% chance. 

The rest of the antimatter collection works the same as for the matter collection, with a parallel level system (updating matter level doesn't change antimatter level; can't mint lvl 2 antimatter if antimatter level == 1, even if matter level > 1).

An antimatter row can be burned to get an antimatter element of the next level.

Antimatter elements can't be burned individually to decrease chances to mint elements from this level (the chances to mint a specific antimatter element depends on the RAM of the matter elements).

If a user manages to collect the entire periodic table of antimatter, they can withdraw the prize pool. Their matter and antimatter tokens are all burned. Their matter level goes back to lvl 1, antimatter level stays the same, and burned tokens count remains the same (allowing for a faster progression for a new run).

### LINK tokens
In order for the application to work as intended, the subscription contract needs to own enough LINK to start a VRF request. In order to incentivize users to fund LINKs to the contract, they would earn cards/packs for doing so. The amount of the reward should depend on the amount of LINK transfered.


# Foundry Doc

## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
