// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@contracts/interfaces/ICore.sol";
import "@contracts/interfaces/IProperty.sol";
import "@contracts/interfaces/IReputation.sol";
import "@contracts/libraries/Errors.sol";
import "@contracts/libraries/Constants.sol";

contract Core is ICore {
    IProperty propertyInstance;
    IReputation reputationInstance;

    enum RentalStatus {
        Free,
        Pending,
        Approved
    }

    struct Property {
        uint256 rentPrice;
        bool published;
    }

    struct Rental {
        uint256 rentPrice;
        address tenant;
        uint256 availableDeposits;
        uint256 paymentDate;
        RentalStatus status;
        uint256 createdAt;
    }

    mapping(uint256 => Property) public properties;
    mapping(uint256 => Rental) public rentals;
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
        if (rentals[request].status != RentalStatus.Pending) {
            revert Errors.CannotApproveNotPendingRentalRequest();
        }
        _;
    }

    modifier requireApprovedRentalRequest(uint256 request) {
        if (rentals[request].status != RentalStatus.Approved) {
            revert Errors.RentalNotApproved();
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

        Rental memory rental = rentals[propertyId];

        if (rental.tenant != address(0)) {
            revert Errors.CannotRentAlreadyRentedProperty();
        }

        Property memory property = properties[propertyId];

        if (!property.published) {
            revert Errors.CannotRentHiddenProperty();
        }

        if (msg.value != Constants.RENTAL_REQUEST_NUMBER_OF_DEPOSITS * property.rentPrice) {
            revert Errors.IncorrectDeposit();
        }

        rental.availableDeposits = Constants.RENTAL_REQUEST_NUMBER_OF_DEPOSITS;
        rental.rentPrice = property.rentPrice;
        rental.status = RentalStatus.Pending;
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
        Rental memory rental = rentals[request];

        rental.createdAt = block.timestamp;
        rental.paymentDate = block.timestamp + Constants.MONTH;
        rental.status = RentalStatus.Approved;

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
        Rental memory rental = rentals[request];

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

        properties[propertyId] = Property({rentPrice: rentPrice, published: true});
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
        Rental memory property = rentals[rental];

        if (block.timestamp > property.createdAt + Constants.CONTRACT_DURATION) {
            revert Errors.CannotPayRentAfterContractExpiry();
        }

        if (block.timestamp < property.paymentDate) {
            revert Errors.PayRentDateNotReached();
        }

        if (block.timestamp > property.paymentDate + Constants.LATE_PAYMENT_DEADLINE) {
            revert Errors.CannotPayRentAfterLatePaymentDeadline();
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
        Rental memory property = rentals[rental];

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
     * @dev see {ICore-completeRental}.
     */
    function completeRental(uint256 rental) external onlyPropertyOwner(rental) requireApprovedRentalRequest(rental) {
        Rental memory property = rentals[rental];

        if (block.timestamp <= property.createdAt + Constants.CONTRACT_DURATION) {
            revert Errors.RentalCompletionDateNotReached();
        }

        balances[property.tenant] = property.rentPrice * property.availableDeposits;

        delete rentals[rental];
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
