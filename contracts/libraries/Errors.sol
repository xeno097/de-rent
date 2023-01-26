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
    error IncorrectDeposit();

    /**
     * @dev Thrown when sender tries to set with an incorrect rent price.
     */
    error IncorrectRentPrice();

    /**
     * @dev Thrown when sender tries to withdraw 0 from its balance.
     */
    error InsufficientBalance();

    /**
     * @dev Thrown when sender tries to perform an action on a property that does not own.
     */
    error NotPropertyOwner();

    /**
     * @dev Thrown when sender tries to performan action on a property that is not renting.
     */
    error NotPropertyTenant();

    /**
     * @dev Thrown when sender tries to rent a non existant property.
     */
    error CannotRentNonExistantProperty();

    /**
     * @dev Thrown when sender tries to rent his/her own property.
     */
    error CannotRentOwnProperty();

    /**
     * @dev Thrown when sender tries to rent an already rented property.
     */
    error CannotRentAlreadyRentedProperty();

    /**
     * @dev Thrown when sender tries to rent a hidden property.
     */
    error CannotRentHiddenProperty();

    /**
     * @dev Thrown when sender tries to approve a rental request that does not have status set to {RentalStatus.Pending} .
     */
    error CannotApproveNotPendingRentalRequest();

    /**
     * @dev Thrown when sender tries withdraw his/her funds but the transfer fails.
     */
    error FailedToWithdraw();

    /**
     * @dev Thrown when sender tries to pay rent before the pay date is reached.
     */
    error RentPaymentDateNotReached();

    /**
     * @dev Thrown when sender tries to pay rent after the late payment deadline is reached.
     */
    error RentLatePaymentDeadlineReached();

    /**
     * @dev Thrown when the late payment deadline has not been reached yet.
     */
    error RentLatePaymentDeadlineNotReached();

    /**
     * @dev Thrown when sender tries to pay rent after a year has passed.
     */
    error RentContractExpiryDateReached();

    /**
     * @dev Thrown when sender tries to perform an action that requires the rental to be approved.
     */
    error RentalNotApproved();

    /**
     * @dev Thrown when sender tries to perform an action that requires the rental completion date to be reached.
     */
    error RentalCompletionDateNotReached();

    /**
     * @dev Thrown when sender tries to perform an action after the rental review date.
     */
    error RentalReviewDeadlineReached();

    /**
     * @dev Thrown when sender tries to perform an action before the rental review date.
     */
    error RentalReviewDeadlineNotReached();
}
