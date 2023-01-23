// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ICore {
    /**
     * @dev Emitted when `request` gets approved.
     */
    event RentalRequestApproved(uint256 indexed request);

    /**
     * @dev Emitted when `request` gets rejected.
     */
    event RentalRequestRejected(uint256 indexed request);

    /**
     * @dev Emitted when `request` gets created.
     */
    event RentalRequested(uint256 indexed request);

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
    function requestRental(uint256 property) external;

    /**
     * @dev Allows sender to publish `property` for rent if he/she is the owner and it is not already published.
     *
     * Requirements:
     * - `property`  must exist.
     *
     */
    function publishProperty(uint256 property) external;

    /**
     * @dev Allows sender to hide `property` for rent if he/she is the owner and it is not already hidden.
     *
     * Requirements:
     * - `property`  must exist.
     *
     */
    function hideProperty(uint256 property) external;

    /**
     * @dev Allows sender to mint a new property with the given metadata uri.
     */
    function createProperty(string memory uri) external;

    /**
     * @dev Allows sender to update `property` uri metadata if he/she is the owner and `property` exists.
     */
    function updateProperty(uint256 property, string memory newUri) external;

    /**
     * @dev Allows sender to pay the rent for `rental`.
     */
    function payRent(uint256 rental) external;

    /**
     * @dev Allows sender to withdraw his/her balance.
     */
    function withdraw() external;
}
