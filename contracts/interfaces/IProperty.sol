// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

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
