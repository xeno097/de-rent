// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@contracts/libraries/DataTypes.sol";

interface ICoreFacet {
    /**
     * @dev Returns `user` balance.
     */
    function balanceOf(address user) external view returns (uint256);

    /**
     * @dev Returns `property` data if `property` exists.
     */
    function getPropertyById(uint256 property) external view returns (DataTypes.Property memory);

    /**
     * @dev Returns `rental` data if `property` exists.
     */
    function getRentalById(uint256 id) external view returns (DataTypes.Rental memory);

    /**
     * @dev Allows sender to approve `request` if exists and he/she is the property owner and `request` is pending.
     *
     * Requirements:
     * - `request`  must exist.
     *
     *  Emits a {RentalRequestApproved} event.
     */
    function approveRentalRequest(uint256 request) external;

    /**
     * @dev Allows sender to reject `request` if exists and he/she is the property owner and `request` is pending.
     *
     * Requirements:
     * - `request`  must exist.
     *
     *  Emits a {RentalRequestRejected} event.
     */
    function rejectRentalRequest(uint256 request) external;

    /**
     * @dev Allows sender to create a rental request for `property` if it's not already rented.
     *
     * Requirements:
     * - `property`  must exist.
     *
     *  Emits a {RentalRequested} event.
     */
    function requestRental(uint256 property) external payable;

    /**
     * @dev Allows sender to update the `property` visibility if he/she is `property` owner.
     *
     * Requirements:
     * - `property`  must exist.
     *
     */
    function setPropertyVisibility(uint256 property, bool visibility) external;

    /**
     * @dev Allows sender to mint a new property with the given metadata uri.
     */
    function createProperty(string memory uri, uint256 rentPrice) external;

    /**
     * @dev Allows sender to update `property` uri metadata if he/she is the owner and `property` exists.
     */
    function updateProperty(uint256 property, string memory newUri) external;

    /**
     * @dev Allows sender to pay the rent for `rental`.
     */
    function payRent(uint256 rental) external payable;

    /**
     * @dev Allows sender to report that a payment was not made on time for `rental`.
     */
    function signalMissedPayment(uint256 rental) external;

    /**
     * @dev Allows sender to score the property and its owner after a `rental` has been completed.
     */
    function reviewRental(uint256 rental, uint256 rentalScore, uint256 ownerScore) external;

    /**
     * @dev Allows sender to perform the closing steps after `rental` has been completed.
     */
    function completeRental(uint256 rental, uint256 scoreUser) external;

    /**
     * @dev Allows sender to withdraw his/her balance.
     */
    function withdraw() external;
}
