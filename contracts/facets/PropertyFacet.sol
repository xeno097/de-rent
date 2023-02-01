// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@contracts/interfaces/IProperty.sol";
import "@contracts/libraries/Errors.sol";
import "@contracts/libraries/Modifiers.sol";
import "@contracts/libraries/DeRentNFT.sol";

contract PropertyFacet is Modifiers, IPropertyFacet {
    using DeRentNFT for AppStorage;

    /**
     * @dev see {IPropertyFacet-getTotalPropertyCount}.
     */
    function getTotalPropertyCount() external view returns (uint256) {
        return s.getCount();
    }

    /**
     * @dev see {IPropertyFacet-createProperty}.
     */
    function createProperty(string memory uri, uint256 rentPrice) external {
        if (rentPrice < Constants.MIN_RENT_PRICE) {
            revert Errors.IncorrectRentPrice();
        }

        uint256 propertyId = s.mint(msg.sender, uri);

        s.properties[propertyId] = DataTypes.Property({rentPrice: rentPrice, published: true});
    }

    /**
     * @dev see {IPropertyFacet-updateProperty}.
     */
    function updateProperty(uint256 property, string memory uri) external requirePropertyOwner(property) {
        s.setTokenURI(property, uri);
    }

    /**
     * @dev see {IPropertyFacet-setPropertyVisibility}.
     */
    function setPropertyVisibility(uint256 property, bool visibility) external requirePropertyOwner(property) {
        s.properties[property].published = visibility;
    }
}
