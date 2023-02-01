// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/BaseTest.sol";

import {IDiamond} from "@diamonds/interfaces/IDiamond.sol";
import {Diamond, DiamondArgs} from "@diamonds/Diamond.sol";
import {DiamondInit} from "@diamonds/upgradeInitializers/DiamondInit.sol";

import "@contracts/facets/PropertyFacet.sol";
import "@contracts/libraries/Errors.sol";
import "@contracts/libraries/Constants.sol";
import "@contracts/libraries/DataTypes.sol";

contract PropertyFacetTest is BaseTest {
    using ScoreCounters for ScoreCounters.ScoreCounter;

    PropertyFacet propertyContract;

    function setUp() public {
        PropertyFacet propertyContractInstance = new PropertyFacet();
        DiamondInit initer = new DiamondInit();

        bytes4[] memory selectors = new bytes4[](4);

        selectors[0] = IPropertyFacet.getTotalPropertyCount.selector;
        selectors[1] = IPropertyFacet.setPropertyVisibility.selector;
        selectors[2] = IPropertyFacet.createProperty.selector;
        selectors[3] = IPropertyFacet.updateProperty.selector;

        IDiamond.FacetCut[] memory diamondCut = new IDiamond.FacetCut[](1);

        diamondCut[0] = IDiamond.FacetCut({
            facetAddress: address(propertyContractInstance),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: selectors
        });

        DiamondArgs memory args = DiamondArgs({
            owner: address(this),
            init: address(initer),
            initCalldata: abi.encodeWithSelector(DiamondInit.init.selector, abi.encode())
        });

        Diamond diamondProxy = new Diamond(diamondCut, args);
        propertyContract = PropertyFacet(address(diamondProxy));
    }

    // getTotalPropertyCount()
    function testGetTotalPropertyCount(uint256 expectedValue) external {
        // Arrange
        _setPropertyCount(address(propertyContract), expectedValue);

        // Act
        uint256 count = propertyContract.getTotalPropertyCount();

        // Assert
        assertEq(count, expectedValue);
    }

    // createProperty()
    function testCannotCreatePropertyWithRentPriceLowerThanMintRentPrice(uint256 expectedRentPrice) external {
        // Arrange
        vm.assume(expectedRentPrice < Constants.MIN_RENT_PRICE);

        // Assert
        vm.expectRevert(Errors.IncorrectRentPrice.selector);

        // Act
        propertyContract.createProperty("", expectedRentPrice);
    }

    function testCreateProperty(uint256 expectedRentPrice) external {
        // Arrange
        vm.assume(expectedRentPrice >= Constants.MIN_RENT_PRICE);

        _setUpOnERC1155ReceivedMockCall(address(this));

        // Act
        propertyContract.createProperty("", expectedRentPrice);

        // Assert
        DataTypes.Property memory property = _readProperty(address(propertyContract), 0);

        assertEq(property.rentPrice, expectedRentPrice);
        assertTrue(property.published);
    }

    // updateProperty()
    function testCannotUpdatePropertyIfNotThePropertyOwner(address user) external {
        // Arrange
        vm.assume(user != address(this) && user != mockAddress);

        _setUpOnERC1155ReceivedMockCall(address(this));
        propertyContract.createProperty("", Constants.MIN_RENT_PRICE);

        vm.prank(user);

        // Assert
        vm.expectRevert(Errors.NotPropertyOwner.selector);

        // Act
        propertyContract.updateProperty(0, "");
    }

    function testUpdateProperty(address user, string memory uri) external {
        // Arrange
        vm.assume(user != address(this) && user!=address(0));

        vm.startPrank(user);

        _setUpOnERC1155ReceivedMockCall(user);
        propertyContract.createProperty("", Constants.MIN_RENT_PRICE);

        // Act
        propertyContract.updateProperty(0, uri);

        // Clean up
        vm.stopPrank();
    }

    // setPropertyVisibility()
    function testCannotSetPropertyVisibilityIfNotPropertyOwner(address user) external {
        // Arrange
        vm.assume(user != address(this));

        _setUpOnERC1155ReceivedMockCall(address(this));
        propertyContract.createProperty("", Constants.MIN_RENT_PRICE);

        vm.prank(user);

        // Assert
        vm.expectRevert(Errors.NotPropertyOwner.selector);

        // Act
        propertyContract.setPropertyVisibility(0, true);
    }

    function testSetPropertyVisibility(bool expectedVisibility) external {
        // Arrange
        _setUpOnERC1155ReceivedMockCall(address(this));
        propertyContract.createProperty("", Constants.MIN_RENT_PRICE);

        // Act
        propertyContract.setPropertyVisibility(0, expectedVisibility);

        // Assert
        DataTypes.Property memory property = _readProperty(address(propertyContract), 0);
        assertEq(property.published, expectedVisibility);
    }
}
