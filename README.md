# DeRent

A decentralized house renting platform developed as final project for Alchemy University Ethereum Bootcamp.

## Overview

The project is built using the [EIP2535](https://eips.ethereum.org/EIPS/eip-2535) Diamond Proxy standard, for contract upgradability and Foundry, and the [ERC1155](https://eips.ethereum.org/EIPS/eip-1155) Multi Token standard to manage user houses as NFTs and their balances. As its focus is on implementing the Diamond Proxy standard, the number of features is limited:

* Mint a house NFT for rental: A user can mint a property as an NFT and make it available for rental.
* On-chain credit score: Users have an on-chain credit score that is directly updated based on their payment performance. Owners can use this score to determine the acceptability of a rental request.
* Rental collateral: On rental request, the user must deposit an equivalent of 2 times the rent price. This deposit will serve as collateral if the tenant fails to pay on time, allowing the owner to claim it as payment.
* Post-rental voting and property rating: At the end of the rental period, both parties can vote on each other, and the tenant can also assign a score to the property.
* Deposit withdrawal: Once the rental agreement is complete, the tenant can withdraw the initial deposit if it is still available.

A posible future improvement would be to allow users to set their rental terms. For example, a user with a payment score below 4 would have his request immeadiately rejected by the protocol if the owner decided so.

## Architecture

### Contracts Required by EIP2535

* [DiamondCutFacet](./contracts/diamond/facets/DiamondCutFacet.sol): Contract in charge of handling the update logic of the diamond.
* [DiamondLoupeFacet](./contracts/diamond/facets/DiamondLoupeFacet.sol): Contract in charge of introspection. Allows to se the facet addresses and their functions.
* [Diamond](./contracts/diamond/Diamond.sol): The proxy contract that handles the routing logic to send user requests to the correct facet if one is available.

### Other Contracts

* [OwnershipFacet](./contracts/diamond/facets/OwnershipFacet.sol): Implementor of the [ERC173](https://eips.ethereum.org/EIPS/eip-173) standard for contract ownership.
* [ReputationFacet](./contracts/facets/ReputationFacet.sol): Contract that exposes functions to read users and properties scores.
* [PropertyFacet](./contracts/facets/PropertyFacet.sol): Contract in charge of handling properties that are available for rental.
* [ListingFacet](./contracts/facets/ListingFacet.sol): A contract that aggregates the properties' data and exposes it in a single place.
* [ERC1155TokenReceiverFacet](./contracts/facets/ERC1155TokenReceiverFacet.sol): Implementor of the [ERC1155TokenReceiver](https://eips.ethereum.org/EIPS/eip-1155#erc-1155-token-receiver) interface.
* [ERC1155Facet](./contracts/facets/ERC1155Facet.sol): A readonly implementation of the [ERC1155](https://eips.ethereum.org/EIPS/eip-1155) standard.
* [CoreFacet](./contracts/facets/CoreFacet.sol): Contract that handles the rental logic.

### Diagram

![Project Diagram](./.github/assets/diagram.png)

### Contract Deployments

The project has been deployed on the `optimism-goerli` testnet.

<table>

<tr>
<th>Contract</th>
<th>Address</th>
</tr>

<tr><td>CoreFacet</td><td> 

[0x739051ebe51FC306B30577D75CF2979dd17a8a22](https://goerli-optimism.etherscan.io/address/0x739051ebe51FC306B30577D75CF2979dd17a8a22#code)

</td></tr>

<tr><td>ERC1155Facet</td><td>

[0x72C264Cb4bE59C72641aae82357284F8c8c456f4](https://goerli-optimism.etherscan.io/address/0x72C264Cb4bE59C72641aae82357284F8c8c456f4#code)

</td></tr>

<tr><td>ERC1155TokenReceiverFacet</td><td>

[0x88B3bd902010Eb224b6f0564DC5DC365515D294a](https://goerli-optimism.etherscan.io/address/0x88B3bd902010Eb224b6f0564DC5DC365515D294a#code)

</td></tr>

<tr><td>ListingFacet</td><td>

[0xce9180134cba34F1aDAf302F3d7aBb05fa060cA3](https://goerli-optimism.etherscan.io/address/0xce9180134cba34F1aDAf302F3d7aBb05fa060cA3#code)

</td></tr>

<tr><td>PropertyFacet</td><td>

[0x99E1cEB467e3cB7D74b4B243Cf9D84191f0A521C](https://goerli-optimism.etherscan.io/address/0x99E1cEB467e3cB7D74b4B243Cf9D84191f0A521C#code)

</td></tr>

<tr><td>ReputationFacet</td><td>

[0xcc25046E00a6a9046346BD5a99474baaB7516423](https://goerli-optimism.etherscan.io/address/0xcc25046E00a6a9046346BD5a99474baaB7516423#code)

</td></tr>

<tr><td>DiamondCutFacet</td><td>

[0x0074E4b52Fe9695b97689C20Ad42421ee8F18adD](https://goerli-optimism.etherscan.io/address/0x0074E4b52Fe9695b97689C20Ad42421ee8F18adD#code)

</td></tr>

<tr><td>DiamondLoupeFacet</td><td>

[0x288791D8ef2e1CBbD700aa82395923D7Dabde4F8](https://goerli-optimism.etherscan.io/address/0x288791D8ef2e1CBbD700aa82395923D7Dabde4F8#code)

</td></tr>

<tr><td>OwnershipFacet</td><td>

[0xEC22680e8A978AA3DC99d36a9eAAb6eff148b5cb](https://goerli-optimism.etherscan.io/address/0xEC22680e8A978AA3DC99d36a9eAAb6eff148b5cb#code)

</td></tr>

<tr><td>DiamondInit</td><td>

[0x982DEF9dC7dB61d9C0D0C6b32E84E0811EC950Ea](https://goerli-optimism.etherscan.io/address/0x982DEF9dC7dB61d9C0D0C6b32E84E0811EC950Ea#code)

</td></tr>

<tr><td>Diamond</td><td>

[0x0141b696Ba60A391Dbf35BF04E93aFCc27FA24d4](https://goerli-optimism.etherscan.io/address/0x0141b696Ba60A391Dbf35BF04E93aFCc27FA24d4#code)

</td></tr>

</td></tr>


</table>

## Resources

The only set of resources you'll ever need to undestand [EIP2535](https://eips.ethereum.org/EIPS/eip-2535)

* [Awesome Diamonds](https://github.com/mudgen/awesome-diamonds)
