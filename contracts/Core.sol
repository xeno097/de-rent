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
            revert();
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
        Property memory property = properties[propertyId];
        Rental memory rental = rentals[propertyId];

        // TODO: check that the property exists and that the owner is not the 0 address
        if (propertyInstance.ownerOf(propertyId) == msg.sender) {
            revert Errors.CannotRentOwnProperty();
        }

        if (rental.tenant != address(0)) {
            revert Errors.CannotRentAlreadyRentedProperty();
        }

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
        rental.paymentDate = block.timestamp + 30 days;
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
        // Property memory property = properties[rental];

        // if (msg.value != property.rentPrice) {
        //     revert Errors.IncorrectDeposit();
        // }

        // address owner = propertyInstance.ownerOf(rental);
        // balances[owner] += msg.value;

        // reputationInstance.scoreUserPaymentPerformance(msg.sender, true);
    }

    /**
     * @dev see {ICore-withdraw}.
     */
    function withdraw() external {}
}
