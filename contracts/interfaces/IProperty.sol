// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

interface IProperty is IERC721Metadata {
    /**
     * @dev Returns the total number of minted properties.
     */
    function getTotalPropertyCount() external view returns (uint256);

    /**
     * @dev Mints a new property owned by `user` with URIStorage set to `uri`.
     *
     * Requirements:
     * - `user` cannot be the 0 address.
     */
    function mint(address user, string memory uri) external returns (uint256 property);

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

interface IPropertyFacet {
    /**
     * @dev Returns the total number of minted properties.
     */
    function getTotalPropertyCount() external view returns (uint256);

    /**
     * @dev Allows sender to update the `property` visibility.
     *
     * Requirements:
     * - sender must be the `property` owner
     * - `property` must exist.
     *
     */
    function setPropertyVisibility(uint256 property, bool visibility) external;

    /**
     * @dev Allows sender to mint a new property with the given metadata uri.
     */
    function createProperty(string memory uri, uint256 rentPrice) external;

    /**
     * @dev Allows sender to update the `property` uri metadata.
     * Requirements:
     * - sender must be the `property` owner
     * - `property` must exist.
     *
     */
    function updateProperty(uint256 property, string memory newUri) external;
}
