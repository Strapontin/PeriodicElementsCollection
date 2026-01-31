# Project Documentation

The elements details in this project were taken from [this github page](https://github.com/Bowserinator/Periodic-Table-JSON)

## Description

This is a periodic elements collection game. Users can collect elements from the periodic table.

This is implemented using ERC1155.

Randomness is implemented using Chainlink VRF.

Since I probably won’t have the funds to audit this, I will probably deploy this game on testnet. The contract is upgradeable in order to fix eventual issues. 

# Features

## Minting

Users can mint a free pack of **5 Hydrogen & Helium** elements per day.

Free packs not minted can be minted the next day. This stacks up to 14 days. When the app goes live, users are expected to be able to mint 14 free packs directly, just like if they didn’t use the app for 14 days.

When a user mints a free pack, they become a player. The main change is that players pay fees on element transfer (both for sending and receiving, more on that in the transferring elements section). 

Daily free packs are reset at midnight, GMT time. This means that, for example, if you mint your free pack at 11pm, your next free pack will be available one hour later.

For paid packs, the elements minted will be randoms, using Chainlink VRF. Elements minted depends on the current **level** of the player. Minting costs a fixed price of `0.002 ether` per pack. A 1% fee goes to the owner, the rest goes to the prize pool.

Buying pack(s) automatically mints available free packs.

When buying a pack, users mints 5 random available elements, based on their relative atomic mass. An available element is an element unlocked by the player, depending on their level.

Between all available elements, the random elements minted are picked randomly depending on their relative atomic mass. Heavier elements are less likely to be minted.

## Minting level (fusing)

Users start at minting level 1 (Hydrogen & Helium level). When they have all elements of a level, they can fuse them together to earn the lightest element from the next level. A user can not mint elements from a level higher than the next level they should be able to, even if they have the elements. 

> Example: Alice is level 1. Bob gives alice all elements from level 2 (or higher). Alice can not fuse them, because her level is too low. She needs to fuse elements of level 1 first.

The process of burning elements to reach a new level is called **fusing elements.**

Each Big Bang (see later in the doc) will increase the fusing power by 1: at first, a user will increase the element weight by 1 when fusing. Once they complete the whole collection once, fusing will increase the weight by 2. This effect cumulates for each big bang a user creates.

## Transferring elements

Addresses that have minted free tokens at least once are considered `players`.

Players can exchange their elements between each other. To do so, both of them must first own $DMT, as a fee is taken from players on elements transfer. 

Addresses that never minted free tokens are not players, and don’t pay fees. This is to avoid marketplaces from being DoS by this mechanic.

A player can receive an element if they authorize the transfer of a specific element from a specific address, or if they allowed an address for all transfers.

The fees start from `0.000_005 ether` per element, and increase by this same value for every element transferred.

## Burning elements

Users can burn their elements to decrease the chances to mint them. The more an element is burned this way, the less chances the user has to mint this element. 

Burned elements have their calculated Relative Atomic Mass increased by 0.1, reducing their chances of being minted. Burning an antimatter element increase RAM by 100.

For more information about the RAM of elements, you can refer to this table: https://github.com/Bowserinator/Periodic-Table-JSON/blob/master/PeriodicTableCSV.csv, column `atomic_mass`.

## Buying DarkMatterTokens ($DMT)

$DMTs are the main currency of the game. 

`DMT = (1 / 1 + pricePerUniverseCreated * amountOfUniversesCreated)`

*A universe is created after each Big Bang.*

1 ETH = 1 DMT at the beginning of the game. 1% of ether used to buy goes to the owner, while the rest goes to the prize pool.

DMT are used as fee for transferring. When a player transfers or receives a periodic table element, they must pay a fee. The fee is automatically calculated, and the corresponding amount of DMT is burned from the player’s balance. 

Players can choose who is allowed to send them elements, and which elements are allowed to be transferred. This prevents malicious users to burn DMT of other players by sending them unwanted elements.

Transferring tokens to a non-player is free of charge for the receiver (if the sender is a player, they still pay the fees).

Players can also choose between ETH and DMT to buy packs.

## Antimatter

Antimatter is a rarer version of matter. Minting a paid pack may pop an antimatter particle with a 1/10_000 chance. The other way to get your first antimatter is through fusing level 7 of elements of matter. This will mint a random antimatter element of lvl 1. Fusing antimatter elements works like matter, generating a random element of antimatter of the next lvl. This can’t be done with antimatter lvl 7.

When fusing antimatter, you have 100% chance of minting a new antimatter element of the next level. The element minted will be the lightest element from this level (the weight for these calculations is shared between matter and antimatter).

## Big Bang

When a player has 1 or more copy of ALL elements (both matter and antimatter), they can call the function `bigBang` to win the game. 

They will lose ALL their elements, get a share of the pool depending of packs they bought (**TODO** SPECIFY), their fusing level goes back to lvl 1, burned tokens count goes back to 0 and they earn a 1 point increase in future burning to decrease chances of minting a burned token (see burning mechanics). The price of DMT increase by `0.01 ether` for all users except for the current caller of `bigBang`. The amount of DMT they hold stays unchanged.

## Pool, shares, and passive earning

Buying pack gives shares from the pool (1% fee).

Buying DMT adds funds to the pool (1 % fee).

When a new universe is created (through a big bang), the price to mint DMT increases, except for the user triggering it.

Users earn a fixed amount of shares when they buy a pack. The potential rewards earned from ending the game increase in size when users buy packs, and when anyone buys DMT.

There are several financial strategies expected with this game:

- Users who don't plan on playing the game buy DMT and hold. When other users call big bang, the price of DMT will increase, and the initial buyers may expect to sell their DMT on AMM at a better rate.

- Players rush to win the game multiple times. This increases their arbitrage opportunities by having the possibility to mint DMT at a better rate than what should be accessible on AMMs. The more big bang they create, the  more arbitrage they'll profit from.

- More calm users by one pack and play the game for free, more slowly. When they manage to make their first big bang, they will be able to receive a part of their share in rewards.

## Refill the VRF subscription

A function allows users to replenish the VRF subscription themselves. This will mint 5 Hydrogen and 5 Helium elements for each `0.002 ether` sent this way.
