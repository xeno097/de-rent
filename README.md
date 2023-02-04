# DeRent

A decentralized house renting platform developed as final project for Alchemy University Ethereum Bootcamp.

## Overview

The project as been developed using the [EIP2535](https://eips.ethereum.org/EIPS/eip-2535) Diamond Proxy standard and foundry. It uses the [ERC1155](https://eips.ethereum.org/EIPS/eip-1155) Multi Token standard to manage both the user houses as NFTs and their balances on the platform. As the aim of the project was to understand and implement the Diamond Proxy standard, the number of features is limited. A user can mint a house as an NFT and make it available for rental. Users have an on chain credit score that is directly updated based on their payment perfomance so that other users can decide to accept or reject a rental request based on his historical behaviour. An improvement that could be made in the future is to actually allow users to set their terms for allowing user to rent a house, for example, a user with a payment score below 4 would have his request immeadiately rejected by the protocol if the owner decided so.
On rental request, the user must deposit an equivalent of 2 times the rent price. This deposit will be used as collateral in case he fails to pay on time and the owner can claim that as payment instead.

## Architecture

## Resources

The only set of resources you'll ever need to undestand [EIP2535](https://eips.ethereum.org/EIPS/eip-2535)

* [Awesome Diamonds](https://github.com/mudgen/awesome-diamonds)
