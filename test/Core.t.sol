// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "@contracts/Core.sol";
import "@contracts/libraries/Errors.sol";

contract CoreTest is Test {
    Core coreContract;
    address constant mockAddress = address(97);

    string constant ozOwnableContractError = "Ownable: caller is not the owner";

    event RentalRequested(uint256 indexed request);

    function setUp() public {
        coreContract = new Core(mockAddress,mockAddress);
    }

    function _setUpMintMockCall() private {
        vm.mockCall(mockAddress, abi.encodeWithSelector(IProperty.mint.selector), abi.encode(0));
    }

    function _setUpOwnerOfMockCall(address returnData) private {
        vm.mockCall(mockAddress, abi.encodeWithSelector(IERC721.ownerOf.selector), abi.encode(returnData));
    }

    // createProperty()
    function testCannotCreatePropertyWithRentLowerThanMintRentPrice(uint256 expectedRentPrice) external {
        // Arrange
        uint256 MIN_RENT_PRICE = coreContract.MIN_RENT_PRICE();
        vm.assume(expectedRentPrice < MIN_RENT_PRICE);

        // Assert
        vm.expectRevert(Errors.IncorrectRentPrice.selector);

        // Act
        coreContract.createProperty("", expectedRentPrice);
    }

    function testCreateProperty(uint256 expectedRentPrice) external {
        // Arrange
        uint256 MIN_RENT_PRICE = coreContract.MIN_RENT_PRICE();
        vm.assume(expectedRentPrice >= MIN_RENT_PRICE);
        _setUpMintMockCall();

        // Act
        coreContract.createProperty("", expectedRentPrice);

        // Assert
        (uint256 rentPrice, bool published) = coreContract.properties(0);

        assertEq(rentPrice, expectedRentPrice);
        assertTrue(published);
    }

    // updateProperty()
    function testCannotUpdatePropertyIfNotThePropertyOwner(address user) external {
        // Arrange
        vm.assume(user != address(this) && user != mockAddress);

        _setUpMintMockCall();
        _setUpOwnerOfMockCall(mockAddress);

        uint256 MIN_RENT_PRICE = coreContract.MIN_RENT_PRICE();
        coreContract.createProperty("", MIN_RENT_PRICE);

        vm.prank(user);

        // Assert
        vm.expectRevert(Errors.NotPropertyOwner.selector);

        // Act
        coreContract.updateProperty(0, "");
    }

    function testUpdateProperty(address user, string memory uri) external {
        // Arrange
        vm.assume(user != address(this));

        _setUpMintMockCall();
        _setUpOwnerOfMockCall(user);

        uint256 MIN_RENT_PRICE = coreContract.MIN_RENT_PRICE();
        coreContract.createProperty("", MIN_RENT_PRICE);

        vm.prank(user);

        // Act
        coreContract.updateProperty(0, uri);
    }

    // setPropertyVisibility()
    function testCannotSetPropertyVisibilityIfNotPropertyOwner(address user) external {
        // Arrange
        vm.assume(user != address(this));

        uint256 MIN_RENT_PRICE = coreContract.MIN_RENT_PRICE();
        _setUpMintMockCall();
        _setUpOwnerOfMockCall(user);

        coreContract.createProperty("", MIN_RENT_PRICE);

        // Assert
        vm.expectRevert(Errors.NotPropertyOwner.selector);

        // Act
        coreContract.setPropertyVisibility(0, true);
    }

    function testSetPropertyVisibility(bool expectedVisibility) external {
        // Arrange
        uint256 MIN_RENT_PRICE = coreContract.MIN_RENT_PRICE();
        _setUpMintMockCall();
        _setUpOwnerOfMockCall(address(this));

        coreContract.createProperty("", MIN_RENT_PRICE);

        // Act
        coreContract.setPropertyVisibility(0, expectedVisibility);

        // Assert
        (, bool visibility) = coreContract.properties(0);
        assertEq(visibility, expectedVisibility);
    }

    // requestRental()
    function testCannotRequestRentalForOwnProperty(address user) external {
        //    Arrange
        _setUpOwnerOfMockCall(user);
        vm.prank(user);

        // Assert
        vm.expectRevert(Errors.CannotRentOwnProperty.selector);

        // Act
        coreContract.requestRental(0);
    }

    function testCannotRequestRentalIfPropertyIsAlreadyRented(address user) external {
        // Arrange
        vm.assume(user != mockAddress);
        _setUpOwnerOfMockCall(mockAddress);

        // Equivalent to setting rentals[0].tenant to mockAddress
        bytes32 storageSlot = bytes32(uint256(keccak256(abi.encode(uint256(0), uint256(6)))) + 1);
        vm.store(address(coreContract), storageSlot, bytes32(uint256(uint160(mockAddress))));

        vm.prank(user);

        // Assert
        vm.expectRevert(Errors.CannotRentAlreadyRentedProperty.selector);

        // Act
        coreContract.requestRental(0);
    }

    function testCannotRequestRentalIfPropertyIsHidden(address user) external {
        // Arrange
        vm.assume(user != mockAddress);
        _setUpOwnerOfMockCall(mockAddress);

        vm.prank(user);

        // Assert
        vm.expectRevert(Errors.CannotRentHiddenProperty.selector);

        // Act
        coreContract.requestRental(0);
    }

    function testCannotRequestRentalWithInvalidDeposit(address user) external {
        // Arrange
        vm.assume(user != mockAddress);
        _setUpOwnerOfMockCall(mockAddress);

        uint256 MIN_RENT_PRICE = coreContract.MIN_RENT_PRICE();

        // Equivalent to setting properties[0].published to true
        bytes32 storageSlot = bytes32(uint256(keccak256(abi.encode(uint256(0), uint256(5)))) + 1);
        vm.store(address(coreContract), storageSlot, bytes32(uint256(1)));

        // Equivalent to setting properties[0].rentPrice to 0.02 ether
        storageSlot = keccak256(abi.encode(uint256(0), uint256(5)));
        vm.store(address(coreContract), storageSlot, bytes32(MIN_RENT_PRICE));

        // Assert
        vm.expectRevert(Errors.IncorrectDeposit.selector);

        // Act
        coreContract.requestRental(0);
    }

    function testRequestRental(address user) external {
        // Arrange
        vm.assume(user != mockAddress);
        _setUpOwnerOfMockCall(mockAddress);

        uint256 MIN_RENT_PRICE = coreContract.MIN_RENT_PRICE();
        uint256 RENTAL_REQUEST_NUMBER_OF_DEPOSITS = coreContract.RENTAL_REQUEST_NUMBER_OF_DEPOSITS();

        // Equivalent to setting properties[0].published to true
        bytes32 storageSlot = bytes32(uint256(keccak256(abi.encode(uint256(0), uint256(5)))) + 1);
        vm.store(address(coreContract), storageSlot, bytes32(uint256(1)));

        // Equivalent to setting properties[0].rentPrice to 0.02 ether
        storageSlot = keccak256(abi.encode(uint256(0), uint256(5)));
        vm.store(address(coreContract), storageSlot, bytes32(MIN_RENT_PRICE));

        uint256 deposit = MIN_RENT_PRICE * RENTAL_REQUEST_NUMBER_OF_DEPOSITS;
        hoax(user, deposit);

        // Act
        coreContract.requestRental{value: deposit}(0);

        // Assert
        (, address tenant,,,) = coreContract.rentals(0);
        assertEq(tenant, user);
    }

    function testRequestRentalEmitsRentalRequested(address user) external {
        // Arrange
        vm.assume(user != mockAddress);
        _setUpOwnerOfMockCall(mockAddress);

        uint256 MIN_RENT_PRICE = coreContract.MIN_RENT_PRICE();
        uint256 RENTAL_REQUEST_NUMBER_OF_DEPOSITS = coreContract.RENTAL_REQUEST_NUMBER_OF_DEPOSITS();

        // Equivalent to setting properties[0].published to true
        bytes32 storageSlot = bytes32(uint256(keccak256(abi.encode(uint256(0), uint256(5)))) + 1);
        vm.store(address(coreContract), storageSlot, bytes32(uint256(1)));

        // Equivalent to setting properties[0].rentPrice to 0.02 ether
        storageSlot = keccak256(abi.encode(uint256(0), uint256(5)));
        vm.store(address(coreContract), storageSlot, bytes32(MIN_RENT_PRICE));

        uint256 deposit = MIN_RENT_PRICE * RENTAL_REQUEST_NUMBER_OF_DEPOSITS;
        hoax(user, deposit);

        // Assert
        vm.expectEmit(true, false, false, true);

        emit RentalRequested(0);

        // Act
        coreContract.requestRental{value: deposit}(0);
    }
}
