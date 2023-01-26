// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@contracts/interfaces/ICore.sol";
import "@contracts/interfaces/IProperty.sol";
import "@contracts/interfaces/IReputation.sol";
import "@contracts/libraries/Errors.sol";
import "@contracts/libraries/Constants.sol";
import "@contracts/libraries/DataTypes.sol";

contract Core is ICore {
    IProperty propertyInstance;
    IReputation reputationInstance;

    mapping(uint256 => DataTypes.Property) public properties;
    mapping(uint256 => DataTypes.Rental) public rentals;
    mapping(address => uint256) public balances;

    constructor(address _propertyAddress, address _reputationAddress) {
        propertyInstance = IProperty(_propertyAddress);
        reputationInstance = IReputation(_reputationAddress);
    }

    modifier onlyPropertyOwner(uint256 property) {
        if (propertyInstance.ownerOf(property) != msg.sender) {
            revert Errors.NotPropertyOwner();
        }
        _;
    }

    modifier onlyPropertyTenant(uint256 property) {
        if (rentals[property].tenant != msg.sender) {
            revert Errors.NotPropertyTenant();
        }
        _;
    }

    modifier onlyPendingRentalRequest(uint256 request) {
        if (rentals[request].status != DataTypes.RentalStatus.Pending) {
            revert Errors.CannotApproveNotPendingRentalRequest();
        }
        _;
    }

    modifier requireApprovedRentalRequest(uint256 request) {
        if (rentals[request].status != DataTypes.RentalStatus.Approved) {
            revert Errors.RentalNotApproved();
        }
        _;
    }

    modifier requireRentalCompletionDateReached(uint256 request) {
        if (block.timestamp <= rentals[request].createdAt + Constants.CONTRACT_DURATION) {
            revert Errors.RentalCompletionDateNotReached();
        }
        _;
    }

    /**
     * @dev see {ICore-requestRental}.
     */
    function requestRental(uint256 propertyId) external payable {
        address owner = propertyInstance.ownerOf(propertyId);

        // If the owner is the 0 address we can assume that the
        // property does not exists.
        if (owner == address(0)) {
            revert Errors.CannotRentNonExistantProperty();
        }

        if (owner == msg.sender) {
            revert Errors.CannotRentOwnProperty();
        }

        DataTypes.Rental memory rental = rentals[propertyId];

        if (rental.tenant != address(0)) {
            revert Errors.CannotRentAlreadyRentedProperty();
        }

        DataTypes.Property memory property = properties[propertyId];

        if (!property.published) {
            revert Errors.CannotRentHiddenProperty();
        }

        if (msg.value != Constants.RENTAL_REQUEST_NUMBER_OF_DEPOSITS * property.rentPrice) {
            revert Errors.IncorrectDeposit();
        }

        rental.availableDeposits = Constants.RENTAL_REQUEST_NUMBER_OF_DEPOSITS;
        rental.rentPrice = property.rentPrice;
        rental.status = DataTypes.RentalStatus.Pending;
        rental.tenant = msg.sender;

        rentals[propertyId] = rental;

        emit RentalRequested(propertyId);
    }

    /**
     * @dev see {ICore-approveRentalRequest}.
     */
    function approveRentalRequest(uint256 request)
        external
        onlyPropertyOwner(request)
        onlyPendingRentalRequest(request)
    {
        DataTypes.Rental memory rental = rentals[request];

        rental.createdAt = block.timestamp;
        rental.paymentDate = block.timestamp + Constants.MONTH;
        rental.status = DataTypes.RentalStatus.Approved;

        rentals[request] = rental;

        emit RentalRequestApproved(request);
    }

    /**
     * @dev see {ICore-rejectRentalRequest}.
     */
    function rejectRentalRequest(uint256 request)
        external
        onlyPropertyOwner(request)
        onlyPendingRentalRequest(request)
    {
        DataTypes.Rental memory rental = rentals[request];

        balances[rental.tenant] += rental.rentPrice * rental.availableDeposits;

        delete rentals[request];

        emit RentalRequestRejected(request);
    }

    /**
     * @dev see {ICore-createProperty}.
     */
    function createProperty(string memory uri, uint256 rentPrice) external {
        if (rentPrice < Constants.MIN_RENT_PRICE) {
            revert Errors.IncorrectRentPrice();
        }

        uint256 propertyId = propertyInstance.mint(msg.sender, uri);

        properties[propertyId] = DataTypes.Property({rentPrice: rentPrice, published: true});
    }

    /**
     * @dev see {ICore-updateProperty}.
     */
    function updateProperty(uint256 property, string memory uri) external onlyPropertyOwner(property) {
        propertyInstance.updateMetadata(property, uri);
    }

    /**
     * @dev see {ICore-setPropertyVisibility}.
     */
    function setPropertyVisibility(uint256 property, bool visibility) external onlyPropertyOwner(property) {
        properties[property].published = visibility;
    }

    /**
     * @dev see {ICore-payRent}.
     */
    function payRent(uint256 rental) external payable onlyPropertyTenant(rental) requireApprovedRentalRequest(rental) {
        DataTypes.Rental memory property = rentals[rental];

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

        address owner = propertyInstance.ownerOf(rental);
        balances[owner] += msg.value;

        property.paymentDate += Constants.MONTH;
        rentals[rental] = property;

        bool paidOnTime = block.timestamp <= property.paymentDate + Constants.ON_TIME_PAYMENT_DEADLINE;

        reputationInstance.scoreUserPaymentPerformance(msg.sender, paidOnTime);
    }

    /**
     * @dev see {ICore-signalMissedPayment}.
     */
    function signalMissedPayment(uint256 rental)
        external
        onlyPropertyOwner(rental)
        requireApprovedRentalRequest(rental)
    {
        DataTypes.Rental memory property = rentals[rental];

        if (block.timestamp <= property.paymentDate + Constants.LATE_PAYMENT_DEADLINE) {
            revert Errors.RentLatePaymentDeadlineNotReached();
        }

        if (property.availableDeposits > 0) {
            balances[msg.sender] += property.rentPrice;
            property.availableDeposits -= 1;
        }

        property.paymentDate += Constants.MONTH;
        rentals[rental] = property;
        reputationInstance.scoreUserPaymentPerformance(msg.sender, false);
    }

    /**
     * @dev see {ICore-reviewRental}.
     */
    function reviewRental(uint256 rental, uint256 rentalScore, uint256 ownerScore)
        external
        onlyPropertyTenant(rental)
        requireApprovedRentalRequest(rental)
        requireRentalCompletionDateReached(rental)
    {
        DataTypes.Rental memory property = rentals[rental];

        if (block.timestamp > property.createdAt + Constants.CONTRACT_DURATION + 2 days) {
            revert Errors.RentalReviewDeadlineReached();
        }

        address owner = propertyInstance.ownerOf(rental);

        property.status = DataTypes.RentalStatus.Completed;
        rentals[rental] = property;

        reputationInstance.scoreUser(owner, ownerScore);
        reputationInstance.scoreProperty(rental, rentalScore);
    }

    /**
     * @dev see {ICore-completeRental}.
     */
    function completeRental(uint256 rental, uint256 scoreUser)
        external
        onlyPropertyOwner(rental)
        requireRentalCompletionDateReached(rental)
    {
        DataTypes.Rental memory property = rentals[rental];

        if (
            property.status == DataTypes.RentalStatus.Completed
                || block.timestamp <= property.createdAt + Constants.CONTRACT_DURATION + 2 days
        ) {
            revert Errors.RentalReviewDeadlineNotReached();
        }

        balances[property.tenant] = property.rentPrice * property.availableDeposits;

        delete rentals[rental];

        reputationInstance.scoreUser(property.tenant, scoreUser);
    }

    /**
     * @dev see {ICore-withdraw}.
     */
    function withdraw() external {
        uint256 balance = balances[msg.sender];
        balances[msg.sender] = 0;

        if (balance == 0) {
            revert Errors.InsufficientBalance();
        }

        (bool ok,) = msg.sender.call{value: balance}("");

        if (!ok) {
            revert Errors.FailedToWithdraw();
        }
    }
}
