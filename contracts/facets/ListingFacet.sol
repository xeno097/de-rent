// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@contracts/interfaces/IListing.sol";
import "@contracts/libraries/DataTypes.sol";
import "@contracts/libraries/Modifiers.sol";

contract ListingFacet is Modifiers, IListingFacet {
    function _getListingPropertyById(uint256 id) internal view returns (DataTypes.ListingProperty memory) {
        string memory uri = s.propertyInstance.tokenURI(id);
        address owner = s.propertyInstance.ownerOf(id);
        DataTypes.Property memory property = s.properties[id];
        DataTypes.Rental memory rental = s.rentals[id];

        return DataTypes.ListingProperty({
            id: id,
            rentPrice: property.rentPrice,
            owner: owner,
            published: property.published,
            uri: uri,
            status: rental.status
        });
    }

    function _getPropertiesByFilter(function(DataTypes.ListingProperty memory) view returns(bool) filterFunc)
        internal
        view
        returns (DataTypes.ListingProperty[] memory)
    {
        DataTypes.ListingProperty[] memory properties = getProperties();

        uint256 totalCount = 0;
        for (uint256 i = 0; i < properties.length; i++) {
            if (filterFunc(properties[i])) {
                totalCount++;
            }
        }

        DataTypes.ListingProperty[] memory ret = new  DataTypes.ListingProperty[](totalCount);
        uint256 id = 0;
        for (uint256 i = 0; i < properties.length; i++) {
            if (filterFunc(properties[i])) {
                ret[id] = properties[i];

                id++;
            }
        }

        return ret;
    }

    function _filterByPublished(DataTypes.ListingProperty memory property) internal pure returns (bool) {
        return property.published;
    }

    function _filterByOwner(DataTypes.ListingProperty memory property) internal view returns (bool) {
        return property.owner == msg.sender;
    }

    /**
     * @dev see {IListingFacet-getSelfProperties}.
     */
    function getSelfProperties() external view returns (DataTypes.ListingProperty[] memory) {
        return _getPropertiesByFilter(_filterByOwner);
    }

    /**
     * @dev see {IListingFacet-getPublishedProperties}.
     */
    function getPublishedProperties() external view returns (DataTypes.ListingProperty[] memory) {
        return _getPropertiesByFilter(_filterByPublished);
    }

    /**
     * @dev see {IListingFacet-getProperties}.
     */
    function getProperties() public view returns (DataTypes.ListingProperty[] memory) {
        uint256 totalCount = s.propertyInstance.getTotalPropertyCount();

        DataTypes.ListingProperty[] memory res = new  DataTypes.ListingProperty[](totalCount);

        for (uint256 id = 0; id < totalCount; id++) {
            res[id] = _getListingPropertyById(id);
        }

        return res;
    }

    /**
     * @dev see {IListing-getPropertyById}.
     */
    function getPropertyById(uint256 property)
        external
        view
        propertyExist(property)
        returns (DataTypes.ListingProperty memory)
    {
        return _getListingPropertyById(property);
    }
}
