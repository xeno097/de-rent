// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "@contracts/Property.sol";
import "@contracts/libraries/Errors.sol";
import "@contracts/interfaces/IERC4906.sol";

contract PropertyTest is Test {
    Property propertyContract;
    address constant mockAddress = address(97);

    string constant ozOwnableContractError = "Ownable: caller is not the owner";

    event MetadataUpdate(uint256 _tokenId);

    function setUp() public {
        propertyContract = new Property(mockAddress);
    }

    // mint()
    function testCannotMintIfNotFromCoreContractAddress(address user) external {
        // Arrange
        vm.assume(user > address(10) && user != mockAddress);
        vm.prank(user);

        // Arrange
        vm.expectRevert(bytes(ozOwnableContractError));

        // Act
        propertyContract.mint(user, "");
    }

    function testMint() external {
        // Arrange
        vm.prank(mockAddress);

        // Act
        propertyContract.mint(mockAddress, "");

        // Arrange
        uint256 balance = propertyContract.balanceOf(mockAddress);
        assertEq(balance, 1);
    }

    function testMintMultipleProperties() external {
        // Arrange
        vm.startPrank(mockAddress);

        // Act
        propertyContract.mint(mockAddress, "");
        propertyContract.mint(mockAddress, "");

        // Arrange
        uint256 balance = propertyContract.balanceOf(mockAddress);
        assertEq(balance, 2);

        // Cleanup
        vm.stopPrank();
    }

    function testMintSetsCorrectlyTokenUri(string memory expectedUri) external {
        // Arrange
        vm.prank(mockAddress);

        // Act
        propertyContract.mint(mockAddress, expectedUri);

        // Arrange
        string memory uri = propertyContract.tokenURI(0);
        assertEq(uri, expectedUri);
    }

    // exists()
    function testExistsReturnsFalseIfPropertyDoesNotExists(uint256 property) external {
        // Act
        bool res = propertyContract.exists(property);

        // Assert
        assertFalse(res);
    }

    function testExistsReturnsTrueIfPropertyExists() external {
        // Arrange
        vm.prank(mockAddress);
        propertyContract.mint(mockAddress, "");

        // Act
        bool res = propertyContract.exists(0);

        // Assert
        assertTrue(res);
    }

    // updateMetadata()
    function testCannotUpdateMetadataIfNotFromCoreContractAddress(address user) external {
        // Arrange
        vm.assume(user != mockAddress);
        vm.prank(user);

        // Arrange
        vm.expectRevert(bytes(ozOwnableContractError));

        // Act
        propertyContract.updateMetadata(0, "");
    }

    function testUpdateMetadata(string memory expectedUri) external {
        // Arrange
        vm.startPrank(mockAddress);
        propertyContract.mint(mockAddress, "");

        // Act
        propertyContract.updateMetadata(0, expectedUri);

        // Assert
        string memory uri = propertyContract.tokenURI(0);
        assertEq(uri, expectedUri);

        // Cleanup
        vm.stopPrank();
    }

    function testUpdateMetadataEmitsMetadataUpdate(string memory expectedUri) external {
        // Arrange
        vm.startPrank(mockAddress);
        propertyContract.mint(mockAddress, "");

        // Assert
        vm.expectEmit(true, false, false, true);

        emit MetadataUpdate(0);

        // Act
        propertyContract.updateMetadata(0, expectedUri);

        // Cleanup
        vm.stopPrank();
    }
}
