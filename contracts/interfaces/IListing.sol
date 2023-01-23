// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IListing {
    /**
     * @dev Returns the properties owned by sender.
     */
    function getSelfProperties() external view;

    /**
     * @dev Returns all the properties existing on the platform.
     */
    function getProperties() external view;

    /**
     * @dev Returns `property` if exists.
     *
     * Requirements:
     * - `property` must exist.
     *
     */
    function getHouseById(uint256 property) external view;
}
