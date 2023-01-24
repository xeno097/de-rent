// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

interface IProperty is IERC721 {
    /**
     * @dev Mints a new property owned by `user` with URIStorage set to `uri`.
     *
     * Requirements:
     * - `user` cannot be the 0 address.
     */
    function mint(address user, string memory uri) external;

    /**
     * @dev Verifies that `property` exists.
     */
    function exists(uint256 property) external view returns (bool);

    /**
     * @dev Updates `property` metadata with `uri` if exists.
     *
     * Requirements:
     * - `property` must exists.
     *
     *  Emits a {MetadataUpdate} event.
     */
    function updateMetadata(uint256 property, string memory uri) external;
}
