// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @dev A counter  that caps the number of NFTs at 2^128 - 1
library ERC1155NftCounter {
    error MaxNFTCapacityReached();

    struct Counter {
        uint256 _counter;
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._counter;
    }

    function increment(Counter storage counter) internal {
        if (counter._counter == type(uint128).max) {
            revert MaxNFTCapacityReached();
        }

        unchecked {
            counter._counter += 1;
        }
    }
}
