// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library Errors {
    /**
     * @dev Thrown when a function receives an invalid address as input like the 0 address.
     */
    error InvalidAddress(address);

    /**
     * @dev Thrown when the user with the provided address does not exist.
     */
    error UserNotFound();

    /**
     * @dev Thrown when the property with the provided id does not exist.
     */
    error PropertyNotFound();

    /**
     * @dev Thrown when sender submits a score with a value out of a given range.
     */
    error ScoreValueOutOfRange(uint256, uint256);

    /**
     * @dev Thrown when the rental request with the provided id does not exist.
     */
    error RentalRequestNotFound();

    /**
     * @dev Thrown when sender tries to pay with an incorrect deposit.
     */
    error InsufficientDeposit();

    /**
     * @dev Thrown when sender tries to withdraw 0 from its balance.
     */
    error InsufficientBalance();
}
