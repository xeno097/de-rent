// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/BaseTest.sol";

import {IDiamond} from "@diamonds/interfaces/IDiamond.sol";
import {Diamond, DiamondArgs} from "@diamonds/Diamond.sol";
import {DiamondInit} from "@diamonds/upgradeInitializers/DiamondInit.sol";

import "@contracts/facets/ListingFacet.sol";
import "@contracts/libraries/Constants.sol";
import "@contracts/libraries/DataTypes.sol";

contract ListingTest is BaseTest {
    ListingFacet listingContract;

    function setUp() public {
        ListingFacet coreContractInstance = new ListingFacet();
        DiamondInit initer = new DiamondInit();

        bytes4[] memory selectors = new bytes4[](4);

        selectors[0] = (IListingFacet.getSelfProperties.selector);
        selectors[1] = (IListingFacet.getPublishedProperties.selector);
        selectors[2] = (IListingFacet.getProperties.selector);
        selectors[3] = (IListingFacet.getPropertyById.selector);

        IDiamond.FacetCut[] memory diamondCut = new IDiamond.FacetCut[](1);

        diamondCut[0] = IDiamond.FacetCut({
            facetAddress: address(coreContractInstance),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: selectors
        });

        DiamondArgs memory args = DiamondArgs({
            owner: address(this),
            init: address(initer),
            initCalldata: abi.encodeWithSelector(DiamondInit.init.selector, abi.encode())
        });

        Diamond diamondProxy = new Diamond(diamondCut, args);
        listingContract = ListingFacet(address(diamondProxy));
    }

    function _setupListingPropertyTests(uint128 id, address owner, bool published) internal {
        vm.assume(id < type(uint128).max);

        _setTokenOwner(address(listingContract), id, owner);
        _setPropertyCount(address(listingContract), id + 1);

        string memory expectedUri = "some random uri";
        _createTokenUri(address(listingContract), id, expectedUri);

        DataTypes.Property memory propertyMock =
            DataTypes.Property({rentPrice: Constants.MIN_RENT_PRICE, published: published});
        DataTypes.Rental memory rentalMock = DataTypes.Rental({
            rentPrice: Constants.MIN_RENT_PRICE,
            tenant: alternativeMockAddress,
            availableDeposits: Constants.RENTAL_REQUEST_NUMBER_OF_DEPOSITS,
            paymentDate: Constants.MONTH,
            status: DataTypes.RentalStatus.Approved,
            createdAt: block.timestamp
        });

        _createRental(address(listingContract), id, rentalMock);
        _createProperty(address(listingContract), id, propertyMock);
    }

    // function getPropertyById()
    function testCannotGetPropertyByIdIfDoesNotExist(uint128 id) external {
        // Assert
        vm.expectRevert(Errors.PropertyNotFound.selector);

        // Act
        listingContract.getPropertyById(id);
    }

    function testGetPropertyById(uint128 id) external {
        // Arrange
        _setupListingPropertyTests(id, mockAddress, false);

        // Act
        DataTypes.ListingProperty memory listingProperty = listingContract.getPropertyById(id);

        // Assert
        assertEq(listingProperty.id, id);
        assertEq(listingProperty.rentPrice, Constants.MIN_RENT_PRICE);
        assertEq(listingProperty.owner, mockAddress);
        assertEq(listingProperty.published, false);
        assertEq(uint8(listingProperty.status), uint8(DataTypes.RentalStatus.Approved));
    }

    // getProperties()
    function testGetProperties(address[] memory data) external {
        // Arrange
        uint256 expectedLen = data.length;
        _setUpGetTotalPropertyCountMockCall(expectedLen);

        for (uint128 id = 0; id < expectedLen; id++) {
            _setupListingPropertyTests(id, data[id], id % 2 == 0);
        }

        // Act
        DataTypes.ListingProperty[] memory listingProperties = listingContract.getProperties();

        // Assert
        assertEq(listingProperties.length, expectedLen);
        for (uint256 i = 0; i < listingProperties.length; i++) {
            assertEq(listingProperties[i].id, i);
            assertEq(listingProperties[i].rentPrice, Constants.MIN_RENT_PRICE);
            assertEq(listingProperties[i].owner, data[i]);
            assertEq(listingProperties[i].published, i % 2 == 0);
            assertEq(uint8(listingProperties[i].status), uint8(DataTypes.RentalStatus.Approved));
        }
    }

    // getSelfProperties()
    function testGetSelfProperties(address[] memory data) external {
        // Arrange
        _setUpGetTotalPropertyCountMockCall(data.length);

        for (uint128 id = 0; id < data.length; id++) {
            address owner = id % 2 == 0 ? mockAddress : data[id];

            _setupListingPropertyTests(id, owner, true);
        }

        vm.prank(mockAddress);

        // Act
        DataTypes.ListingProperty[] memory listingProperties = listingContract.getSelfProperties();

        // Assert
        for (uint256 i = 0; i < listingProperties.length; i++) {
            assertEq(listingProperties[i].owner, mockAddress);
        }
    }

    // getPublishedProperties()
    function testGetPublishedProperties(uint8 properties) external {
        // Arrange
        _setUpGetTotalPropertyCountMockCall(properties);

        for (uint128 id = 0; id < properties; id++) {
            _setupListingPropertyTests(id, mockAddress, id % 2 == 1);
        }

        // Act
        DataTypes.ListingProperty[] memory listingProperties = listingContract.getPublishedProperties();

        // Assert
        for (uint256 i = 0; i < listingProperties.length; i++) {
            assertEq(listingProperties[i].published, true);
        }
    }
}
