// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@contracts/interfaces/IListing.sol";
import "@contracts/interfaces/ICore.sol";
import "@contracts/interfaces/IProperty.sol";
import "@contracts/libraries/DataTypes.sol";

contract Listing is IListing {
    ICore coreInstance;
    IProperty propertyInstance;

    constructor(address _coreAddress, address _propertyAddress) {
        coreInstance = ICore(_coreAddress);
        propertyInstance = IProperty(_propertyAddress);
    }

    function _getListingPropertyById(uint256 id) internal view returns (DataTypes.ListingProperty memory) {
        string memory uri = propertyInstance.tokenURI(id);
        address owner = propertyInstance.ownerOf(id);
        DataTypes.Property memory property = coreInstance.getPropertyById(id);
        DataTypes.Rental memory rental = coreInstance.getRentalById(id);

        return DataTypes.ListingProperty({
            id: id,
            rentPrice: property.rentPrice,
            owner: owner,
            published: property.published,
            uri: uri,
            status: rental.status
        });
    }

    /**
     * @dev see {IListing-getSelfProperties}.
     */
    function getSelfProperties() external view returns (DataTypes.ListingProperty[] memory) {
        DataTypes.ListingProperty[] memory properties = getProperties();

        uint256 totalCount = 0;
        for (uint256 i = 0; i < properties.length; i++) {
            if (properties[i].owner == msg.sender) {
                totalCount++;
            }
        }

        DataTypes.ListingProperty[] memory ret = new  DataTypes.ListingProperty[](totalCount);
        uint256 id = 0;
        for (uint256 i = 0; i < properties.length; i++) {
            if (properties[i].owner == msg.sender) {
                ret[id] = properties[i];

                id++;
            }
        }

        return ret;
    }

    /**
     * @dev see {IListing-getPublishedProperties}.
     */
    function getPublishedProperties() external view returns (DataTypes.ListingProperty[] memory) {
        DataTypes.ListingProperty[] memory properties = getProperties();

        uint256 totalCount = 0;
        for (uint256 i = 0; i < properties.length; i++) {
            if (properties[i].published) {
                totalCount++;
            }
        }

        DataTypes.ListingProperty[] memory ret = new  DataTypes.ListingProperty[](totalCount);

        uint256 id = 0;
        for (uint256 i = 0; i < properties.length; i++) {
            if (properties[i].published) {
                ret[id] = properties[i];

                id++;
            }
        }

        return ret;
    }

    /**
     * @dev see {IListing-getProperties}.
     */
    function getProperties() public view returns (DataTypes.ListingProperty[] memory) {
        uint256 totalCount = propertyInstance.getTotalPropertyCount();

        DataTypes.ListingProperty[] memory res = new  DataTypes.ListingProperty[](totalCount);

        for (uint256 id = 0; id < totalCount; id++) {
            res[id] = _getListingPropertyById(id);
        }

        return res;
    }

    /**
     * @dev see {IListing-getPropertyById}.
     */
    function getPropertyById(uint256 property) external view returns (DataTypes.ListingProperty memory) {
        return _getListingPropertyById(property);
    }
}
