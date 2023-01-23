// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// TODO: refine logic for this interface
interface ICoreExtension {
    /**
     * @dev Emitted when `rental` gets cancelled.
     */
    event RentalCancelled(uint256 indexed request);

    /**
     * @dev Emitted when `request` gets renewed.
     */
    event RentalRenewed(uint256 indexed request);

    /**
     * @dev Allows sender to cancel `rental` before its due date by paying a penalty.
     */
    function cancelRental(uint256 rental) external;

    /**
     * @dev Allows sender to renew `rental` if it hasn't expired yet.
     */
    function renewRental(uint256 rental) external;
}
