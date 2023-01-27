// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@contracts/libraries/DataTypes.sol";

interface IListing {
    /**
     * @dev Returns the properties owned by sender.
     */
    function getSelfProperties() external view returns (DataTypes.ListingProperty[] memory);

    /**
     * @dev Returns all the properties existing on the platform.
     */
    function getProperties() external view returns (DataTypes.ListingProperty[] memory);

    /**
     * @dev Returns `property` if exists.
     *
     * Requirements:
     * - `property` must exist.
     *
     */
    function getPropertyById(uint256 property) external view returns (DataTypes.ListingProperty memory);
}
