// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@contracts/libraries/AppStorage.sol";
import "@contracts/libraries/LibERC1155.sol";

/// @dev Wrapper lib around the LibERC1155 to make it easier to manipulate the properties.
library DeRentNFT {
    using ERC1155NftCounter for ERC1155NftCounter.Counter;
    using LibERC1155 for AppStorage;

    function getCount(AppStorage storage s) internal view returns (uint256) {
        return s.tokenCounter.current();
    }

    function ownerOf(AppStorage storage s, uint256 tokenId) internal view returns (address) {
        return s.owners[tokenId];
    }

    function tokenURI(AppStorage storage s, uint256 tokenId) internal view returns (string memory) {
        return s.tokenUris[tokenId];
    }

    function mint(AppStorage storage s, address to, string memory uri) internal returns (uint256) {
        uint256 tokenId = s.tokenCounter.current();
        s.tokenCounter.increment();

        s._mint(to, tokenId, 1, bytes(""));
        s._setURI(tokenId, uri);
        s.owners[tokenId] = to;

        return tokenId;
    }

    function setTokenURI(AppStorage storage s, uint256 tokenId, string memory uri) internal {
        s._setURI(tokenId, uri);
    }
}
