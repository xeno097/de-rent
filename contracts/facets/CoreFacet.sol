// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

import "@contracts/interfaces/ICore.sol";
import "@contracts/libraries/Errors.sol";
import "@contracts/libraries/Constants.sol";
import "@contracts/libraries/DataTypes.sol";
import "@contracts/libraries/ScoreCounters.sol";
import "@contracts/libraries/ReputationWriter.sol";
import "@contracts/libraries/AppStorage.sol";
import "@contracts/libraries/Modifiers.sol";
import "@contracts/libraries/LibERC1155.sol";

contract CoreFacet is Modifiers, ICoreFacet {
    using ScoreCounters for ScoreCounters.ScoreCounter;
    using ReputationWriter for AppStorage;
    using LibERC1155 for AppStorage;

    /**
     * @dev see {ICoreFacet-balanceOf}.
     */
    function balanceOf(address user) external view returns (uint256) {
        return s._balanceOf(user, Constants.DE_RENT_USER_BALANCES_TOKEN_ID);
    }

    /**
     * @dev see {ICoreFacet-requestRental}.
     */
    function requestRental(uint256 propertyId) external payable {
        address owner = s.owners[propertyId];

        // If the owner is the 0 address we can assume that the
        // property does not exists.
        if (owner == address(0)) {
            revert Errors.CannotRentNonExistantProperty();
        }

        if (owner == msg.sender) {
            revert Errors.CannotRentOwnProperty();
        }

        DataTypes.Rental memory rental = s.rentals[propertyId];

        if (rental.tenant != address(0)) {
            revert Errors.CannotRentAlreadyRentedProperty();
        }

        DataTypes.Property memory property = s.properties[propertyId];

        if (!property.published) {
            revert Errors.CannotRentHiddenProperty();
        }

        if (msg.value != Constants.RENTAL_REQUEST_NUMBER_OF_DEPOSITS * property.rentPrice) {
            revert Errors.IncorrectDeposit();
        }

        s._mint(address(this), Constants.DE_RENT_USER_BALANCES_TOKEN_ID, msg.value, bytes(""));

        rental.availableDeposits = Constants.RENTAL_REQUEST_NUMBER_OF_DEPOSITS;
        rental.rentPrice = property.rentPrice;
        rental.status = DataTypes.RentalStatus.Pending;
        rental.tenant = msg.sender;

        s.rentals[propertyId] = rental;

        emit Events.RentalRequested(propertyId);
    }

    /**
     * @dev see {ICoreFacet-approveRentalRequest}.
     */
    function approveRentalRequest(uint256 request)
        external
        requirePropertyOwner(request)
        onlyPendingRentalRequest(request)
    {
        DataTypes.Rental memory rental = s.rentals[request];

        rental.createdAt = block.timestamp;
        rental.paymentDate = block.timestamp + Constants.MONTH;
        rental.status = DataTypes.RentalStatus.Approved;

        s.rentals[request] = rental;

        emit Events.RentalRequestApproved(request);
    }

    /**
     * @dev see {ICoreFacet-rejectRentalRequest}.
     */
    function rejectRentalRequest(uint256 request)
        external
        requirePropertyOwner(request)
        onlyPendingRentalRequest(request)
    {
        DataTypes.Rental memory rental = s.rentals[request];

        s._safeTransferFrom(
            address(this),
            rental.tenant,
            Constants.DE_RENT_USER_BALANCES_TOKEN_ID,
            rental.rentPrice * rental.availableDeposits,
            bytes("")
        );

        delete s.rentals[request];

        emit Events.RentalRequestRejected(request);
    }

    /**
     * @dev see {ICoreFacet-payRent}.
     */
    function payRent(uint256 rental) external payable onlyPropertyTenant(rental) requireApprovedRentalRequest(rental) {
        DataTypes.Rental memory property = s.rentals[rental];

        if (block.timestamp > property.createdAt + Constants.CONTRACT_DURATION) {
            revert Errors.RentContractExpiryDateReached();
        }

        if (block.timestamp < property.paymentDate) {
            revert Errors.RentPaymentDateNotReached();
        }

        if (block.timestamp > property.paymentDate + Constants.LATE_PAYMENT_DEADLINE) {
            revert Errors.RentLatePaymentDeadlineReached();
        }

        if (msg.value != property.rentPrice) {
            revert Errors.IncorrectDeposit();
        }

        address owner = s.owners[rental];

        s._mint(owner, Constants.DE_RENT_USER_BALANCES_TOKEN_ID, msg.value, bytes(""));

        property.paymentDate += Constants.MONTH;
        s.rentals[rental] = property;

        bool paidOnTime = block.timestamp <= property.paymentDate + Constants.ON_TIME_PAYMENT_DEADLINE;

        s.scoreUserPaymentPerformance(msg.sender, paidOnTime);
    }

    /**
     * @dev see {ICoreFacet-signalMissedPayment}.
     */
    function signalMissedPayment(uint256 rental)
        external
        requirePropertyOwner(rental)
        requireApprovedRentalRequest(rental)
    {
        DataTypes.Rental memory property = s.rentals[rental];

        if (block.timestamp <= property.paymentDate + Constants.LATE_PAYMENT_DEADLINE) {
            revert Errors.RentLatePaymentDeadlineNotReached();
        }

        if (property.availableDeposits > 0) {
            s._safeTransferFrom(
                address(this), msg.sender, Constants.DE_RENT_USER_BALANCES_TOKEN_ID, property.rentPrice, bytes("")
            );
            property.availableDeposits -= 1;
        }

        property.paymentDate += Constants.MONTH;
        s.rentals[rental] = property;
        s.scoreUserPaymentPerformance(property.tenant, false);
    }

    /**
     * @dev see {ICoreFacet-reviewRental}.
     */
    function reviewRental(uint256 rental, uint256 rentalScore, uint256 ownerScore)
        external
        onlyPropertyTenant(rental)
        requireApprovedRentalRequest(rental)
        requireRentalCompletionDateReached(rental)
    {
        DataTypes.Rental memory property = s.rentals[rental];

        if (block.timestamp > property.createdAt + Constants.CONTRACT_DURATION + 2 days) {
            revert Errors.RentalReviewDeadlineReached();
        }

        address owner = s.owners[rental];

        property.status = DataTypes.RentalStatus.Completed;
        s.rentals[rental] = property;

        s.scoreUser(owner, ownerScore);
        s.scoreProperty(rental, rentalScore);
    }

    /**
     * @dev see {ICoreFacet-completeRental}.
     */
    function completeRental(uint256 rental, uint256 scoreUser)
        external
        requirePropertyOwner(rental)
        requireRentalCompletionDateReached(rental)
    {
        DataTypes.Rental memory property = s.rentals[rental];

        if (
            property.status == DataTypes.RentalStatus.Completed
                || block.timestamp <= property.createdAt + Constants.CONTRACT_DURATION + 2 days
        ) {
            revert Errors.RentalReviewDeadlineNotReached();
        }

        s._safeTransferFrom(
            address(this),
            property.tenant,
            Constants.DE_RENT_USER_BALANCES_TOKEN_ID,
            property.rentPrice * property.availableDeposits,
            bytes("")
        );

        delete s.rentals[rental];

        s.scoreUser(property.tenant, scoreUser);
    }

    /**
     * @dev see {ICoreFacet-withdraw}.
     */
    function withdraw() external {
        uint256 balance = s._balanceOf(msg.sender, Constants.DE_RENT_USER_BALANCES_TOKEN_ID);
        s._burn(msg.sender, Constants.DE_RENT_USER_BALANCES_TOKEN_ID, balance);

        if (balance == 0) {
            revert Errors.InsufficientBalance();
        }

        (bool ok,) = msg.sender.call{value: balance}("");

        if (!ok) {
            revert Errors.FailedToWithdraw();
        }
    }
}
