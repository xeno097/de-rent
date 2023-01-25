// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@contracts/interfaces/ICore.sol";
import "@contracts/interfaces/IProperty.sol";
import "@contracts/interfaces/IReputation.sol";
import "@contracts/libraries/Errors.sol";

contract Core is ICore {
    IProperty propertyInstance;
    IReputation reputationInstance;

    uint256 CONTRACT_DURATION = 52 weeks; // ~ 1 year
    uint256 public RENTAL_REQUEST_NUMBER_OF_DEPOSITS = 2;
    uint256 public MIN_RENT_PRICE = 0.02 ether;

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

    uint256 public constant MONTH = 30 days;
    uint256 public constant ON_TIME_PAYMENT_DEADLINE = 3 days;
    uint256 public constant LATE_PAYMENT_DEADLINE = ON_TIME_PAYMENT_DEADLINE + 2 days;

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

        if (msg.value != RENTAL_REQUEST_NUMBER_OF_DEPOSITS * property.rentPrice) {
            revert Errors.IncorrectDeposit();
        }

        rental.availableDeposits = RENTAL_REQUEST_NUMBER_OF_DEPOSITS;
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
        rental.paymentDate = block.timestamp + MONTH;
        rental.status = RentalStatus.Approved;

        rentals[request] = rental;
        balances[msg.sender] += rental.rentPrice * rental.availableDeposits;

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
        if (rentPrice < MIN_RENT_PRICE) {
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
    function payRent(uint256 rental) external payable onlyPropertyTenant(rental) {
        Rental memory property = rentals[rental];

        if(block.timestamp > property.createdAt + CONTRACT_DURATION){
            revert Errors.CannotPayRentAfterContractExpiry();
        }

        if (block.timestamp < property.paymentDate) {
            revert Errors.PayRentDateNotReached();
        }

        if (block.timestamp > property.paymentDate + LATE_PAYMENT_DEADLINE) {
            revert Errors.CannotPayRentAfterLatePaymentDeadline();
        }

        if (msg.value != property.rentPrice) {
            revert Errors.IncorrectDeposit();
        }

        address owner = propertyInstance.ownerOf(rental);
        balances[owner] += msg.value;

        property.paymentDate += MONTH;
        rentals[rental] = property;

        bool paidOnTime = block.timestamp <= ON_TIME_PAYMENT_DEADLINE;

        reputationInstance.scoreUserPaymentPerformance(msg.sender, paidOnTime);
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
