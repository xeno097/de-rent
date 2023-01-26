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
    event RentalRequestApproved(uint256 indexed request);
    event RentalRequestRejected(uint256 indexed request);

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
    function testCannotRequestRentalForNonExistantProperty(address user) external {
        // Arrange
        _setUpOwnerOfMockCall(address(0));
        vm.prank(user);

        // Assert
        vm.expectRevert(Errors.CannotRentNonExistantProperty.selector);

        // Act
        coreContract.requestRental(0);
    }

    function testCannotRequestRentalForOwnProperty(address user) external {
        // Arrange
        vm.assume(user != address(0));
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
        (, address tenant,,,,) = coreContract.rentals(0);
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

    // approveRentalRequest()
    function testCannotApproveRentalRequestForNotOwnedProperty(address user) external {
        // Arrange
        vm.assume(user != mockAddress);
        _setUpOwnerOfMockCall(mockAddress);

        vm.prank(user);

        // Assert
        vm.expectRevert(Errors.NotPropertyOwner.selector);

        // Act
        coreContract.approveRentalRequest(0);
    }

    function testCannotApproveRentalRequestForNotPendingRequest(address user) external {
        // Arrange
        _setUpOwnerOfMockCall(user);

        // Equivalent to setting rentals[0].status to RentalStatus.Free
        bytes32 storageSlot = bytes32(uint256(keccak256(abi.encode(uint256(0), uint256(6)))) + 4);
        vm.store(address(coreContract), storageSlot, bytes32(uint256(0)));

        vm.prank(user);

        // Assert
        vm.expectRevert(Errors.CannotApproveNotPendingRentalRequest.selector);

        // Act
        coreContract.approveRentalRequest(0);
    }

    function testApproveRentalRequest(address user) external {
        // Arrange
        _setUpOwnerOfMockCall(user);

        // Equivalent to setting rentals[0].status to RentalStatus.Pending
        bytes32 storageSlot = bytes32(uint256(keccak256(abi.encode(uint256(0), uint256(6)))) + 4);
        vm.store(address(coreContract), storageSlot, bytes32(uint256(1)));

        vm.prank(user);

        // Act
        coreContract.approveRentalRequest(0);

        // Assert
        (,,, uint256 paymentDate, Core.RentalStatus status, uint256 createdAt) = coreContract.rentals(0);
        assertEq(uint8(status), uint8(Core.RentalStatus.Approved));
        assertGe(createdAt, uint256(0));
        assertEq(paymentDate, createdAt + 30 days);
    }

    function testApproveRentalRequestEmitsRentalRequestApproved(address user) external {
        // Arrange
        _setUpOwnerOfMockCall(user);

        // Equivalent to setting rentals[0].status to RentalStatus.Pending
        bytes32 storageSlot = bytes32(uint256(keccak256(abi.encode(uint256(0), uint256(6)))) + 4);
        vm.store(address(coreContract), storageSlot, bytes32(uint256(1)));

        vm.prank(user);

        // Assert
        vm.expectEmit(true, false, false, true);

        emit RentalRequestApproved(0);

        // Act
        coreContract.approveRentalRequest(0);
    }

    // rejectRentalRequest()
    function testCannotRejectRentalRequestForNotOwnedProperty(address user) external {
        // Arrange
        vm.assume(user != mockAddress);
        _setUpOwnerOfMockCall(mockAddress);

        vm.prank(user);

        // Assert
        vm.expectRevert(Errors.NotPropertyOwner.selector);

        // Act
        coreContract.rejectRentalRequest(0);
    }

    function testCannotRejectRentalRequestForNotPendingRequest(address user) external {
        // Arrange
        _setUpOwnerOfMockCall(user);

        // Equivalent to setting rentals[0].status to RentalStatus.Free
        bytes32 storageSlot = bytes32(uint256(keccak256(abi.encode(uint256(0), uint256(6)))) + 4);
        vm.store(address(coreContract), storageSlot, bytes32(uint256(0)));

        vm.prank(user);

        // Assert
        vm.expectRevert(Errors.CannotApproveNotPendingRentalRequest.selector);

        // Act
        coreContract.rejectRentalRequest(0);
    }

    function testRejectRentalRequest(address user) external {
        // Arrange
        _setUpOwnerOfMockCall(user);

        // Equivalent to setting rentals[0].status to RentalStatus.Pending
        bytes32 storageSlot = bytes32(uint256(keccak256(abi.encode(uint256(0), uint256(6)))) + 4);
        vm.store(address(coreContract), storageSlot, bytes32(uint256(1)));

        vm.prank(user);

        // Act
        coreContract.rejectRentalRequest(0);

        // Assert
        (
            uint256 rentPrice,
            address tenant,
            uint256 availableDeposits,
            uint256 paymentDate,
            Core.RentalStatus status,
            uint256 createdAt
        ) = coreContract.rentals(0);

        assertEq(rentPrice, 0);
        assertEq(tenant, address(0));
        assertEq(availableDeposits, 0);
        assertEq(paymentDate, 0);
        assertEq(uint8(status), uint8(Core.RentalStatus.Free));
        assertEq(createdAt, 0);
    }

    function testRejectRentalRequestIncreasesTenantBalance(address user) external {
        // Arrange
        _setUpOwnerOfMockCall(user);

        uint256 MIN_RENT_PRICE = coreContract.MIN_RENT_PRICE();
        uint256 RENTAL_REQUEST_NUMBER_OF_DEPOSITS = coreContract.RENTAL_REQUEST_NUMBER_OF_DEPOSITS();
        uint256 expectedBalance = MIN_RENT_PRICE * RENTAL_REQUEST_NUMBER_OF_DEPOSITS;

        // Equivalent to setting rentals[0].status to RentalStatus.Pending
        bytes32 storageSlot = bytes32(uint256(keccak256(abi.encode(uint256(0), uint256(6)))) + 4);
        vm.store(address(coreContract), storageSlot, bytes32(uint256(1)));

        // Equivalent to setting rentals[0].rentPrice to MIN_RENT_PRICE
        storageSlot = bytes32(uint256(keccak256(abi.encode(uint256(0), uint256(6)))));
        vm.store(address(coreContract), storageSlot, bytes32(uint256(MIN_RENT_PRICE)));

        // Equivalent to setting rentals[0].availableDeposits to RENTAL_REQUEST_NUMBER_OF_DEPOSITS
        storageSlot = bytes32(uint256(keccak256(abi.encode(uint256(0), uint256(6)))) + 2);
        vm.store(address(coreContract), storageSlot, bytes32(RENTAL_REQUEST_NUMBER_OF_DEPOSITS));

        // Equivalent to setting rentals[0].tenant to mockAddress
        storageSlot = bytes32(uint256(keccak256(abi.encode(uint256(0), uint256(6)))) + 1);
        vm.store(address(coreContract), storageSlot, bytes32(uint256(uint160(mockAddress))));

        vm.prank(user);

        // Act
        coreContract.rejectRentalRequest(0);

        // Assert
        uint256 balance = coreContract.balances(mockAddress);
        assertEq(balance, expectedBalance);
    }

    function testRejectRentalRequestEmitsRentalRequestApproved(address user) external {
        // Arrange
        _setUpOwnerOfMockCall(user);

        // Equivalent to setting rentals[0].status to RentalStatus.Pending
        bytes32 storageSlot = bytes32(uint256(keccak256(abi.encode(uint256(0), uint256(6)))) + 4);
        vm.store(address(coreContract), storageSlot, bytes32(uint256(1)));

        vm.prank(user);

        // Assert
        vm.expectEmit(true, false, false, true);

        emit RentalRequestRejected(0);

        // Act
        coreContract.rejectRentalRequest(0);
    }

    // payRent()
    function testCannotPayRentIfNotPropertyTenant(address user) external {
        // Arrange
        vm.assume(user != address(0));

        vm.prank(user);

        // Assert
        vm.expectRevert(Errors.NotPropertyTenant.selector);

        // Act
        coreContract.payRent(0);
    }

    function testCannotPayRentIfRentalIsNotApproved(address user) external {
        // Arrange

        // Equivalent to setting rentals[user].tenant to user
        bytes32 storageSlot = bytes32(uint256(keccak256(abi.encode(uint256(0), uint256(6)))) + 1);
        vm.store(address(coreContract), storageSlot, bytes32(uint256(uint160(user))));

        vm.prank(user);

        // Assert
        vm.expectRevert(Errors.RentalNotApproved.selector);

        // Act
        coreContract.payRent(0);
    }

    function testCannotPayRentIfContractExpired(address user) external {
        // Arrange

        // Equivalent to setting rentals[user].tenant to user
        bytes32 storageSlot = bytes32(uint256(keccak256(abi.encode(uint256(0), uint256(6)))) + 1);
        vm.store(address(coreContract), storageSlot, bytes32(uint256(uint160(user))));

        // Equivalent to setting rentals[0].status to RentalStatus.Approved
        storageSlot = bytes32(uint256(keccak256(abi.encode(uint256(0), uint256(6)))) + 4);
        vm.store(address(coreContract), storageSlot, bytes32(uint256(2)));

        vm.warp(53 weeks);
        vm.prank(user);

        // Assert
        vm.expectRevert(Errors.CannotPayRentAfterContractExpiry.selector);

        // Act
        coreContract.payRent(0);
    }

    function testCannotPayRentBeforePaymentDate(address user) external {
        // Arrange

        // Equivalent to setting rentals[user].tenant to user
        bytes32 storageSlot = bytes32(uint256(keccak256(abi.encode(uint256(0), uint256(6)))) + 1);
        vm.store(address(coreContract), storageSlot, bytes32(uint256(uint160(user))));

        // Equivalent to setting rentals[user].paymentDate to block.timestamp+ 7 days
        storageSlot = bytes32(uint256(keccak256(abi.encode(uint256(0), uint256(6)))) + 3);
        vm.store(address(coreContract), storageSlot, bytes32(block.timestamp + 7 days));

        // Equivalent to setting rentals[0].status to RentalStatus.Approved
        storageSlot = bytes32(uint256(keccak256(abi.encode(uint256(0), uint256(6)))) + 4);
        vm.store(address(coreContract), storageSlot, bytes32(uint256(2)));

        vm.prank(user);

        // Assert
        vm.expectRevert(Errors.PayRentDateNotReached.selector);

        // Act
        coreContract.payRent(0);
    }

    function testCannotPayRentAfterLatePaymentDeadline(address user) external {
        // Arrange

        // Equivalent to setting rentals[user].tenant to user
        bytes32 storageSlot = bytes32(uint256(keccak256(abi.encode(uint256(0), uint256(6)))) + 1);
        vm.store(address(coreContract), storageSlot, bytes32(uint256(uint160(user))));

        // Equivalent to setting rentals[user].paymentDate to block.timestamp+ 7 days
        storageSlot = bytes32(uint256(keccak256(abi.encode(uint256(0), uint256(6)))) + 3);
        vm.store(address(coreContract), storageSlot, bytes32(block.timestamp));

        // Equivalent to setting rentals[0].status to RentalStatus.Approved
        storageSlot = bytes32(uint256(keccak256(abi.encode(uint256(0), uint256(6)))) + 4);
        vm.store(address(coreContract), storageSlot, bytes32(uint256(2)));

        vm.warp(7 days);

        vm.prank(user);

        // Assert
        vm.expectRevert(Errors.CannotPayRentAfterLatePaymentDeadline.selector);

        // Act
        coreContract.payRent(0);
    }

    function testCannotPayRentWithAnIncorrectDeposit(address user, uint256 invalidDeposit) external {
        // Arrange
        vm.warp(7 days);

        uint256 MIN_RENT_PRICE = coreContract.MIN_RENT_PRICE();
        vm.assume(0 <= invalidDeposit && invalidDeposit < MIN_RENT_PRICE);

        // Equivalent to setting rentals[0].tenant to user
        bytes32 storageSlot = bytes32(uint256(keccak256(abi.encode(uint256(0), uint256(6)))) + 1);
        vm.store(address(coreContract), storageSlot, bytes32(uint256(uint160(user))));

        // Equivalent to setting rentals[0].paymentDate to block.timestamp - 1 days
        storageSlot = bytes32(uint256(keccak256(abi.encode(uint256(0), uint256(6)))) + 3);
        vm.store(address(coreContract), storageSlot, bytes32(block.timestamp - 1 days));

        // Equivalent to setting rentals[0].rentPrice to MIN_RENT_PRICE
        storageSlot = bytes32(uint256(keccak256(abi.encode(uint256(0), uint256(6)))));
        vm.store(address(coreContract), storageSlot, bytes32(MIN_RENT_PRICE));

        // Equivalent to setting rentals[0].status to RentalStatus.Approved
        storageSlot = bytes32(uint256(keccak256(abi.encode(uint256(0), uint256(6)))) + 4);
        vm.store(address(coreContract), storageSlot, bytes32(uint256(2)));

        hoax(user, invalidDeposit);

        // Assert
        vm.expectRevert(Errors.IncorrectDeposit.selector);

        // Act
        coreContract.payRent{value: invalidDeposit}(0);
    }

    function testPayRentIncreasesTheOwnerBalance(address user) external {
        // Arrange
        _setUpOwnerOfMockCall(mockAddress);

        uint256 MIN_RENT_PRICE = coreContract.MIN_RENT_PRICE();

        // Equivalent to setting rentals[0].tenant to user
        bytes32 storageSlot = bytes32(uint256(keccak256(abi.encode(uint256(0), uint256(6)))) + 1);
        vm.store(address(coreContract), storageSlot, bytes32(uint256(uint160(user))));

        // Equivalent to setting rentals[0].paymentDate to block.timestamp - 1 days
        storageSlot = bytes32(uint256(keccak256(abi.encode(uint256(0), uint256(6)))) + 3);
        vm.store(address(coreContract), storageSlot, bytes32(block.timestamp));

        // Equivalent to setting rentals[0].rentPrice to MIN_RENT_PRICE
        storageSlot = bytes32(uint256(keccak256(abi.encode(uint256(0), uint256(6)))));
        vm.store(address(coreContract), storageSlot, bytes32(MIN_RENT_PRICE));

        // Equivalent to setting rentals[0].status to RentalStatus.Approved
        storageSlot = bytes32(uint256(keccak256(abi.encode(uint256(0), uint256(6)))) + 4);
        vm.store(address(coreContract), storageSlot, bytes32(uint256(2)));

        hoax(user, MIN_RENT_PRICE);

        // Act
        coreContract.payRent{value: MIN_RENT_PRICE}(0);

        // Assert
        uint256 balance = coreContract.balances(mockAddress);

        assertEq(balance, MIN_RENT_PRICE);
    }

    function testPayRentUpdatesThePayDateForTheRental(address user) external {
        // Arrange
        _setUpOwnerOfMockCall(mockAddress);

        uint256 MIN_RENT_PRICE = coreContract.MIN_RENT_PRICE();
        uint256 currentPayDate = block.timestamp;

        // Equivalent to setting rentals[0].tenant to user
        bytes32 storageSlot = bytes32(uint256(keccak256(abi.encode(uint256(0), uint256(6)))) + 1);
        vm.store(address(coreContract), storageSlot, bytes32(uint256(uint160(user))));

        // Equivalent to setting rentals[0].paymentDate to block.timestamp
        storageSlot = bytes32(uint256(keccak256(abi.encode(uint256(0), uint256(6)))) + 3);
        vm.store(address(coreContract), storageSlot, bytes32(currentPayDate));

        // Equivalent to setting rentals[0].rentPrice to MIN_RENT_PRICE
        storageSlot = bytes32(uint256(keccak256(abi.encode(uint256(0), uint256(6)))));
        vm.store(address(coreContract), storageSlot, bytes32(MIN_RENT_PRICE));

        // Equivalent to setting rentals[0].status to RentalStatus.Approved
        storageSlot = bytes32(uint256(keccak256(abi.encode(uint256(0), uint256(6)))) + 4);
        vm.store(address(coreContract), storageSlot, bytes32(uint256(2)));

        hoax(user, MIN_RENT_PRICE);

        // Act
        coreContract.payRent{value: MIN_RENT_PRICE}(0);

        // Assert
        (,,, uint256 paymentDate,,) = coreContract.rentals(0);

        assertEq(paymentDate, currentPayDate + 30 days);
    }

    // signalMissedPayment
    function testCannotSignalMissedPaymentIfNotPropertyOwner(address user) external {
        // Arrange
        vm.assume(user != mockAddress);
        _setUpOwnerOfMockCall(mockAddress);

        vm.prank(user);

        // Assert
        vm.expectRevert(Errors.NotPropertyOwner.selector);

        // Act
        coreContract.signalMissedPayment(0);
    }

    function testCannotSignalMissedPaymentIfRentalIsNotApproved(address user) external {
        // Arrange
        _setUpOwnerOfMockCall(user);

        vm.prank(user);

        // Assert
        vm.expectRevert(Errors.RentalNotApproved.selector);

        // Act
        coreContract.signalMissedPayment(0);
    }

    function testCannotSignalMissedPaymentBeforeLatePaymentDeadline(address user) external {
        // Arrange
        _setUpOwnerOfMockCall(user);

        // Equivalent to setting rentals[0].status to RentalStatus.Approved
        bytes32 storageSlot = bytes32(uint256(keccak256(abi.encode(uint256(0), uint256(6)))) + 4);
        vm.store(address(coreContract), storageSlot, bytes32(uint256(2)));

        vm.prank(user);

        // Assert
        vm.expectRevert(Errors.RentLatePaymentDeadlineNotReached.selector);

        // Act
        coreContract.signalMissedPayment(0);
    }

    function testSignalMissedPaymentIncreasesTheOwnerBalanceIfAvailableDepositIsGreaterThan0(address user) external {
        // Arrange
        _setUpOwnerOfMockCall(user);

        uint256 MIN_RENT_PRICE = coreContract.MIN_RENT_PRICE();
        uint256 RENTAL_REQUEST_NUMBER_OF_DEPOSITS = coreContract.RENTAL_REQUEST_NUMBER_OF_DEPOSITS();

        // Equivalent to setting rentals[0].status to RentalStatus.Approved
        bytes32 storageSlot = bytes32(uint256(keccak256(abi.encode(uint256(0), uint256(6)))) + 4);
        vm.store(address(coreContract), storageSlot, bytes32(uint256(2)));

        // Equivalent to setting rentals[0].rentPrice to MIN_RENT_PRICE
        storageSlot = bytes32(uint256(keccak256(abi.encode(uint256(0), uint256(6)))));
        vm.store(address(coreContract), storageSlot, bytes32(MIN_RENT_PRICE));

        // Equivalent to setting rentals[0].availableDeposits to RENTAL_REQUEST_NUMBER_OF_DEPOSITS
        storageSlot = bytes32(uint256(keccak256(abi.encode(uint256(0), uint256(6)))) + 2);
        vm.store(address(coreContract), storageSlot, bytes32(RENTAL_REQUEST_NUMBER_OF_DEPOSITS));

        vm.warp(37 days);

        vm.prank(user);

        // Act
        coreContract.signalMissedPayment(0);

        // Assert
        uint256 balance = coreContract.balances(user);
        assertEq(balance, MIN_RENT_PRICE);
    }

    function testSignalMissedPaymentDecreasesTheNumberOfAvailableDepositsIfAvailableDepositIsGreaterThan0(address user)
        external
    {
        // Arrange
        _setUpOwnerOfMockCall(user);

        uint256 MIN_RENT_PRICE = coreContract.MIN_RENT_PRICE();
        uint256 RENTAL_REQUEST_NUMBER_OF_DEPOSITS = coreContract.RENTAL_REQUEST_NUMBER_OF_DEPOSITS();
        uint256 expectedNumberOfDeposits = RENTAL_REQUEST_NUMBER_OF_DEPOSITS - 1;

        // Equivalent to setting rentals[0].status to RentalStatus.Approved
        bytes32 storageSlot = bytes32(uint256(keccak256(abi.encode(uint256(0), uint256(6)))) + 4);
        vm.store(address(coreContract), storageSlot, bytes32(uint256(2)));

        // Equivalent to setting rentals[0].rentPrice to MIN_RENT_PRICE
        storageSlot = bytes32(uint256(keccak256(abi.encode(uint256(0), uint256(6)))));
        vm.store(address(coreContract), storageSlot, bytes32(MIN_RENT_PRICE));

        // Equivalent to setting rentals[0].availableDeposits to RENTAL_REQUEST_NUMBER_OF_DEPOSITS
        storageSlot = bytes32(uint256(keccak256(abi.encode(uint256(0), uint256(6)))) + 2);
        vm.store(address(coreContract), storageSlot, bytes32(RENTAL_REQUEST_NUMBER_OF_DEPOSITS));

        vm.warp(37 days);

        vm.prank(user);

        // Act
        coreContract.signalMissedPayment(0);

        // Assert
        (,, uint256 availableDeposits,,,) = coreContract.rentals(0);
        assertEq(availableDeposits, expectedNumberOfDeposits);
    }

    // completeRental()
    function testCannotCompleteRentalIfNotPropertyOwner(address user) external {
        // Arrange
        vm.assume(user != mockAddress);
        _setUpOwnerOfMockCall(mockAddress);

        vm.prank(user);

        // Assert
        vm.expectRevert(Errors.NotPropertyOwner.selector);

        // Act
        coreContract.completeRental(0);
    }

    function testCannotCompleteRentalIfRentalIsNotApproved(address user) external {
        // Arrange
        _setUpOwnerOfMockCall(user);

        vm.prank(user);

        // Assert
        vm.expectRevert(Errors.RentalNotApproved.selector);

        // Act
        coreContract.completeRental(0);
    }

    function testCannotCompleteRentalIfRentalCompletionDateIsNotReached(address user) external {
        // Arrange
        _setUpOwnerOfMockCall(user);

        // Equivalent to setting rentals[0].status to RentalStatus.Approved
        bytes32 storageSlot = bytes32(uint256(keccak256(abi.encode(uint256(0), uint256(6)))) + 4);
        vm.store(address(coreContract), storageSlot, bytes32(uint256(2)));

        vm.prank(user);

        // Assert
        vm.expectRevert(Errors.RentalCompletionDateNotReached.selector);

        // Act
        coreContract.completeRental(0);
    }

    function testCompleteIncrementsTenantBalance(address user) external {
        // Arrange
        _setUpOwnerOfMockCall(user);

        uint256 MIN_RENT_PRICE = coreContract.MIN_RENT_PRICE();
        uint256 RENTAL_REQUEST_NUMBER_OF_DEPOSITS = coreContract.RENTAL_REQUEST_NUMBER_OF_DEPOSITS();
        uint256 expectedBalance = MIN_RENT_PRICE * RENTAL_REQUEST_NUMBER_OF_DEPOSITS;

        // Equivalent to setting rentals[0].status to RentalStatus.Approved
        bytes32 storageSlot = bytes32(uint256(keccak256(abi.encode(uint256(0), uint256(6)))) + 4);
        vm.store(address(coreContract), storageSlot, bytes32(uint256(2)));

        // Equivalent to setting rentals[0].tenant to mockAddress
        storageSlot = bytes32(uint256(keccak256(abi.encode(uint256(0), uint256(6)))) + 1);
        vm.store(address(coreContract), storageSlot, bytes32(uint256(uint160(mockAddress))));

        // Equivalent to setting rentals[0].rentPrice to MIN_RENT_PRICE
        storageSlot = bytes32(uint256(keccak256(abi.encode(uint256(0), uint256(6)))));
        vm.store(address(coreContract), storageSlot, bytes32(MIN_RENT_PRICE));

        // Equivalent to setting rentals[0].availableDeposits to RENTAL_REQUEST_NUMBER_OF_DEPOSITS
        storageSlot = bytes32(uint256(keccak256(abi.encode(uint256(0), uint256(6)))) + 2);
        vm.store(address(coreContract), storageSlot, bytes32(RENTAL_REQUEST_NUMBER_OF_DEPOSITS));

        vm.warp(53 weeks);

        vm.prank(user);

        // Act
        coreContract.completeRental(0);

        // Assert
        uint256 balance = coreContract.balances(mockAddress);

        assertEq(balance, expectedBalance);
    }

    function testCompleteRentalCleansTheRentalData(address user) external {
        // Arrange
        _setUpOwnerOfMockCall(user);

        // Equivalent to setting rentals[0].status to RentalStatus.Approved
        bytes32 storageSlot = bytes32(uint256(keccak256(abi.encode(uint256(0), uint256(6)))) + 4);
        vm.store(address(coreContract), storageSlot, bytes32(uint256(2)));

        // Equivalent to setting rentals[0].tenant to mockAddress
        storageSlot = bytes32(uint256(keccak256(abi.encode(uint256(0), uint256(6)))) + 1);
        vm.store(address(coreContract), storageSlot, bytes32(uint256(uint160(mockAddress))));

        vm.warp(53 weeks);

        vm.prank(user);

        // Act
        coreContract.completeRental(0);

        // Assert
        (
            uint256 rentPrice,
            address tenant,
            uint256 availableDeposits,
            uint256 paymentDate,
            Core.RentalStatus status,
            uint256 createdAt
        ) = coreContract.rentals(0);

        assertEq(rentPrice, 0);
        assertEq(tenant, address(0));
        assertEq(availableDeposits, 0);
        assertEq(paymentDate, 0);
        assertEq(uint8(status), uint8(0));
        assertEq(createdAt, 0);
    }

    // withdraw()
    function testCannotWithdrawIfUserBalanceIs0(address user) external {
        // Arrange
        vm.prank(user);

        // Assert
        vm.expectRevert(Errors.InsufficientBalance.selector);

        // Act
        coreContract.withdraw();
    }

    function testThrowsFailedToWithdrawIfTranferFails(address user) external {
        // Arrange
        vm.mockCall(user, abi.encode(""), abi.encode());

        // Equivalent to setting rentals[user] to expectedBalance
        bytes32 storageSlot = bytes32(uint256(keccak256(abi.encode(uint256(uint160(user)), uint256(7)))));
        vm.store(address(coreContract), storageSlot, bytes32(uint256(1)));

        vm.prank(user);

        // Assert
        vm.expectRevert(Errors.FailedToWithdraw.selector);

        // Act
        coreContract.withdraw();
    }

    function testWithdrawTransfersFundsToTheUser(uint64 expectedBalance) external {
        // Arrange
        vm.assume(expectedBalance != 0);
        vm.deal(address(coreContract), expectedBalance);

        // Equivalent to setting rentals[mockAddress] to expectedBalance
        bytes32 storageSlot = bytes32(uint256(keccak256(abi.encode(uint256(uint160(mockAddress)), uint256(7)))));
        vm.store(address(coreContract), storageSlot, bytes32(uint256(expectedBalance)));

        vm.prank(mockAddress);

        // Act
        coreContract.withdraw();

        // Assert
        assertEq(mockAddress.balance, uint256(expectedBalance));
    }

    function testWithdrawDecreasesTheContractBalance(uint64 transferAmount) external {
        // Arrange
        vm.assume(transferAmount != 0);
        vm.deal(address(coreContract), 100000 ether);

        // Equivalent to setting rentals[mockAddress] to expectedBalance
        bytes32 storageSlot = bytes32(uint256(keccak256(abi.encode(uint256(uint160(mockAddress)), uint256(7)))));
        vm.store(address(coreContract), storageSlot, bytes32(uint256(transferAmount)));

        uint256 expectedBalance = address(coreContract).balance - uint256(transferAmount);
        vm.prank(mockAddress);

        // Act
        coreContract.withdraw();

        // Assert
        assertEq(address(coreContract).balance, expectedBalance);
    }
}
