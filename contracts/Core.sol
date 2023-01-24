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
    uint256 RENTAL_REQUEST_NUMBER_OF_DEPOSITS = 2;
    uint256 public MIN_RENT_PRICE = 0.02 ether;

    struct Property {
        uint256 rentPrice;
        bool published;
    }

    struct Rental {
        uint256 rentPrice;
        address tenant;
    }

    mapping(uint256 => Property) public properties;
    mapping(uint256 => Rental) rentals;
    mapping(address => uint256) balances;

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

    /**
     * @dev see {ICore-requestRental}.
     */
    function requestRental(uint256 property) external {}

    /**
     * @dev see {ICore-approveRentalRequest}.
     */
    function approveRentalRequest(uint256 request) external {}

    /**
     * @dev see {ICore-rejectRentalRequest}.
     */
    function rejectRentalRequest(uint256 request) external {}

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
    }

    /**
     * @dev see {ICore-withdraw}.
     */
    function withdraw() external {}
}
