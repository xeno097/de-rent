// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

import "@contracts/interfaces/IProperty.sol";
import "@contracts/libraries/Errors.sol";
import "@contracts/libraries/Modifiers.sol";
import "@contracts/libraries/LibERC1155.sol";
import "@contracts/libraries/ERC1155NftCounter.sol";

contract PropertyFacet is Modifiers, IPropertyFacet {
    using ERC1155NftCounter for ERC1155NftCounter.Counter;
    using LibERC1155 for AppStorage;

    /**
     * @dev see {IPropertyFacet-getTotalPropertyCount}.
     */
    function getTotalPropertyCount() external view returns (uint256) {
        return s.tokenCounter.current();
    }

    /**
     * @dev see {IPropertyFacet-createProperty}.
     */
    function createProperty(string memory uri, uint256 rentPrice) external {
        if (rentPrice < Constants.MIN_RENT_PRICE) {
            revert Errors.IncorrectRentPrice();
        }

        uint256 propertyId = s.tokenCounter.current();
        s.tokenCounter.increment();

        s._mint(msg.sender, propertyId, 1, bytes(""));
        s._setURI(propertyId, uri);
        s.owners[propertyId] = msg.sender;

        s.properties[propertyId] = DataTypes.Property({rentPrice: rentPrice, published: true});
    }

    /**
     * @dev see {IPropertyFacet-updateProperty}.
     */
    function updateProperty(uint256 property, string memory uri) external requirePropertyOwner(property) {
        s._setURI(property, uri);
    }

    /**
     * @dev see {IPropertyFacet-setPropertyVisibility}.
     */
    function setPropertyVisibility(uint256 property, bool visibility) external requirePropertyOwner(property) {
        s.properties[property].published = visibility;
    }
}
