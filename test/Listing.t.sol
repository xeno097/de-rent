// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "@contracts/Listing.sol";
import "@contracts/libraries/Errors.sol";
import "@contracts/libraries/Constants.sol";
import "@contracts/libraries/DataTypes.sol";

contract ListingTest is Test {
    Listing listingContract;
    address constant mockAddress = address(97);
    address constant alternativeMockAddress = address(53);

    bytes32 constant RENTALS_MAPPING_BASE_STORAGE_SLOT = keccak256(abi.encode(uint256(0), uint256(3)));
    bytes32 constant PROPERTIES_MAPPING_BASE_STORAGE_SLOT = keccak256(abi.encode(uint256(0), uint256(2)));

    function setUp() public {
        listingContract = new Listing(mockAddress,mockAddress);
    }

    function _setUpOwnerOfMockCall(uint256 property, address returnData) private {
        vm.mockCall(mockAddress, abi.encodeWithSelector(IERC721.ownerOf.selector, property), abi.encode(returnData));
    }

    function _setUpTokenUriMockCall(uint256 property, string memory returnValue) private {
        vm.mockCall(
            mockAddress, abi.encodeWithSelector(IERC721Metadata.tokenURI.selector, property), abi.encode(returnValue)
        );
    }

    function _setUpGetTotalPropertyCountMockCall(uint256 returnValue) private {
        vm.mockCall(
            mockAddress, abi.encodeWithSelector(IProperty.getTotalPropertyCount.selector), abi.encode(returnValue)
        );
    }

    function _setUpGetPropertyByIdMockCall(uint256 property, DataTypes.Property memory returnValue) private {
        vm.mockCall(
            mockAddress, abi.encodeWithSelector(ICore.getPropertyById.selector, property), abi.encode(returnValue)
        );
    }

    function _setUpGetRentalByIdMockCall(uint256 property, DataTypes.Rental memory returnValue) private {
        vm.mockCall(
            mockAddress, abi.encodeWithSelector(ICore.getRentalById.selector, property), abi.encode(returnValue)
        );
    }

    function _createFakeProperty(uint256 rentPrice, bool published) private pure returns (DataTypes.Property memory) {
        return DataTypes.Property({rentPrice: rentPrice, published: published});
    }

    function _createFakeRental(
        uint256 rentPrice,
        address tenant,
        uint256 availableDeposits,
        uint256 paymentDate,
        DataTypes.RentalStatus status,
        uint256 createdAt
    ) private pure returns (DataTypes.Rental memory) {
        return DataTypes.Rental({
            rentPrice: rentPrice,
            tenant: tenant,
            availableDeposits: availableDeposits,
            paymentDate: paymentDate,
            status: status,
            createdAt: createdAt
        });
    }

    // function getPropertyById()
    function testGetPropertyById(uint256 id) external {
        // Arrange
        _setUpOwnerOfMockCall(id, mockAddress);

        string memory expectedUri = "some random uri";
        _setUpTokenUriMockCall(id, expectedUri);

        _setUpGetPropertyByIdMockCall(id, _createFakeProperty(Constants.MIN_RENT_PRICE, false));

        _setUpGetRentalByIdMockCall(
            id,
            _createFakeRental(
                Constants.MIN_RENT_PRICE, alternativeMockAddress, 2, Constants.MONTH, DataTypes.RentalStatus.Approved, 0
            )
        );

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

        for (uint256 i = 0; i < expectedLen; i++) {
            _setUpOwnerOfMockCall(i, data[i]);

            string memory expectedUri = "some random uri";
            _setUpTokenUriMockCall(i, expectedUri);

            _setUpGetPropertyByIdMockCall(i, _createFakeProperty(Constants.MIN_RENT_PRICE, i % 2 == 0));

            _setUpGetRentalByIdMockCall(
                i,
                _createFakeRental(
                    Constants.MIN_RENT_PRICE,
                    alternativeMockAddress,
                    2,
                    Constants.MONTH,
                    DataTypes.RentalStatus.Approved,
                    0
                )
            );
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

        for (uint256 i = 0; i < data.length; i++) {
            address owner = i % 2 == 0 ? mockAddress : data[i];

            _setUpOwnerOfMockCall(i, owner);

            string memory expectedUri = "some random uri";
            _setUpTokenUriMockCall(i, expectedUri);

            _setUpGetPropertyByIdMockCall(i, _createFakeProperty(Constants.MIN_RENT_PRICE, true));

            _setUpGetRentalByIdMockCall(
                i,
                _createFakeRental(
                    Constants.MIN_RENT_PRICE,
                    alternativeMockAddress,
                    2,
                    Constants.MONTH,
                    DataTypes.RentalStatus.Approved,
                    0
                )
            );
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

        for (uint256 i = 0; i < properties; i++) {
            _setUpOwnerOfMockCall(i, mockAddress);

            string memory expectedUri = "some random uri";
            _setUpTokenUriMockCall(i, expectedUri);

            _setUpGetPropertyByIdMockCall(i, _createFakeProperty(Constants.MIN_RENT_PRICE, i % 2 == 1));

            _setUpGetRentalByIdMockCall(
                i,
                _createFakeRental(
                    Constants.MIN_RENT_PRICE,
                    alternativeMockAddress,
                    2,
                    Constants.MONTH,
                    DataTypes.RentalStatus.Approved,
                    0
                )
            );
        }

        // Act
        DataTypes.ListingProperty[] memory listingProperties = listingContract.getPublishedProperties();

        // Assert
        for (uint256 i = 0; i < listingProperties.length; i++) {
            assertEq(listingProperties[i].published, true);
        }
    }
}
