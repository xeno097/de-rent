// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "@contracts/Core.sol";
import "@contracts/libraries/Errors.sol";
import "@contracts/libraries/Constants.sol";

contract CoreTest is Test {
    Core coreContract;
    address constant mockAddress = address(97);

    string constant ozOwnableContractError = "Ownable: caller is not the owner";
    bytes32 constant RENTALS_MAPPING_BASE_STORAGE_SLOT = keccak256(abi.encode(uint256(0), uint256(6)));
    bytes32 constant PROPERTIES_MAPPING_BASE_STORAGE_SLOT = keccak256(abi.encode(uint256(0), uint256(5)));

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

    function _writeToStorage(address target, bytes32 sslot, bytes32 value, uint256 offset) internal {
        bytes32 storageSlot = bytes32(uint256(sslot) + offset);
        vm.store(target, storageSlot, value);
    }

    function _writeToStorage(address target, bytes32 sslot, bytes32 value) internal {
        _writeToStorage(target, sslot, value, 0);
    }

    // createProperty()
    function testCannotCreatePropertyWithRentLowerThanMintRentPrice(uint256 expectedRentPrice) external {
        // Arrange
        vm.assume(expectedRentPrice < Constants.MIN_RENT_PRICE);

        // Assert
        vm.expectRevert(Errors.IncorrectRentPrice.selector);

        // Act
        coreContract.createProperty("", expectedRentPrice);
    }

    function testCreateProperty(uint256 expectedRentPrice) external {
        // Arrange
        vm.assume(expectedRentPrice >= Constants.MIN_RENT_PRICE);
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

        coreContract.createProperty("", Constants.MIN_RENT_PRICE);

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

        coreContract.createProperty("", Constants.MIN_RENT_PRICE);

        vm.prank(user);

        // Act
        coreContract.updateProperty(0, uri);
    }

    // setPropertyVisibility()
    function testCannotSetPropertyVisibilityIfNotPropertyOwner(address user) external {
        // Arrange
        vm.assume(user != address(this));

        _setUpMintMockCall();
        _setUpOwnerOfMockCall(user);

        coreContract.createProperty("", Constants.MIN_RENT_PRICE);

        // Assert
        vm.expectRevert(Errors.NotPropertyOwner.selector);

        // Act
        coreContract.setPropertyVisibility(0, true);
    }

    function testSetPropertyVisibility(bool expectedVisibility) external {
        // Arrange
        _setUpMintMockCall();
        _setUpOwnerOfMockCall(address(this));

        coreContract.createProperty("", Constants.MIN_RENT_PRICE);

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

        // rentals[0].tenant = mockAddress
        _writeToStorage(address(coreContract), RENTALS_MAPPING_BASE_STORAGE_SLOT, bytes32(uint256(uint160(mockAddress))),1);

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

        // properties[0].published = true
        _writeToStorage(address(coreContract), PROPERTIES_MAPPING_BASE_STORAGE_SLOT, bytes32(uint256(1)),1);

        // properties[0].rentPrice = Constants.MIN_RENT_PRICE
        _writeToStorage(address(coreContract), PROPERTIES_MAPPING_BASE_STORAGE_SLOT, bytes32(Constants.MIN_RENT_PRICE));

        // Assert
        vm.expectRevert(Errors.IncorrectDeposit.selector);

        // Act
        coreContract.requestRental(0);
    }

    function _setupSuccessRequestRentalTests(address user) internal returns (uint256) {
        vm.assume(user != mockAddress);
        _setUpOwnerOfMockCall(mockAddress);

        // properties[0].published = true
        _writeToStorage(address(coreContract), PROPERTIES_MAPPING_BASE_STORAGE_SLOT, bytes32(uint256(1)),1);

        // properties[0].rentPrice = Constants.MIN_RENT_PRICE
        _writeToStorage(address(coreContract), PROPERTIES_MAPPING_BASE_STORAGE_SLOT, bytes32(Constants.MIN_RENT_PRICE));

        uint256 deposit = Constants.MIN_RENT_PRICE * Constants.RENTAL_REQUEST_NUMBER_OF_DEPOSITS;
        hoax(user, deposit);

        return deposit;
    }

    function testRequestRental(address user) external {
        // Arrange
        uint256 deposit = _setupSuccessRequestRentalTests(user);

        // Act
        coreContract.requestRental{value: deposit}(0);

        // Assert
        (, address tenant,,,,) = coreContract.rentals(0);
        assertEq(tenant, user);
    }

    function testRequestRentalEmitsRentalRequested(address user) external {
        // Arrange
        uint256 deposit = _setupSuccessRequestRentalTests(user);

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

        // rentals[0].status = RentalStatus.Free
        _writeToStorage(address(coreContract), RENTALS_MAPPING_BASE_STORAGE_SLOT, bytes32(uint256(0)), 4);

        vm.prank(user);

        // Assert
        vm.expectRevert(Errors.CannotApproveNotPendingRentalRequest.selector);

        // Act
        coreContract.approveRentalRequest(0);
    }

    function _setupSuccessApproveRentalRequest(address user) internal {
        _setUpOwnerOfMockCall(user);

        // rentals[0].status = RentalStatus.Pending
        _writeToStorage(address(coreContract), RENTALS_MAPPING_BASE_STORAGE_SLOT, bytes32(uint256(1)), 4);

        vm.prank(user);
    }

    function testApproveRentalRequest(address user) external {
        // Arrange
        _setupSuccessApproveRentalRequest(user);

        // Act
        coreContract.approveRentalRequest(0);

        // Assert
        (,,, uint256 paymentDate, Core.RentalStatus status, uint256 createdAt) = coreContract.rentals(0);
        assertEq(uint8(status), uint8(Core.RentalStatus.Approved));
        assertGe(createdAt, uint256(0));
        assertEq(paymentDate, createdAt + Constants.MONTH);
    }

    function testApproveRentalRequestEmitsRentalRequestApproved(address user) external {
        // Arrange
        _setupSuccessApproveRentalRequest(user);

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

        // rentals[0].status = RentalStatus.Free
        _writeToStorage(address(coreContract), RENTALS_MAPPING_BASE_STORAGE_SLOT, bytes32(uint256(0)), 4);

        vm.prank(user);

        // Assert
        vm.expectRevert(Errors.CannotApproveNotPendingRentalRequest.selector);

        // Act
        coreContract.rejectRentalRequest(0);
    }

    function _setupSuccessRejectRentalRequestTests(address user) internal {
        _setUpOwnerOfMockCall(user);

        // rentals[0].status = RentalStatus.Pending
        _writeToStorage(address(coreContract), RENTALS_MAPPING_BASE_STORAGE_SLOT, bytes32(uint256(1)), 4);

        // rentals[0].rentPrice = Constants.MIN_RENT_PRICE
        _writeToStorage(address(coreContract), RENTALS_MAPPING_BASE_STORAGE_SLOT, bytes32(uint256(Constants.MIN_RENT_PRICE)));

        // rentals[0].availableDeposits = Constants.RENTAL_REQUEST_NUMBER_OF_DEPOSITS
        _writeToStorage(address(coreContract), RENTALS_MAPPING_BASE_STORAGE_SLOT, bytes32(Constants.RENTAL_REQUEST_NUMBER_OF_DEPOSITS),2);

        // Equivalent to setting rentals[0].tenant to mockAddress
        _writeToStorage(address(coreContract), RENTALS_MAPPING_BASE_STORAGE_SLOT, bytes32(uint256(uint160(mockAddress))),1);


        vm.prank(user);
    }

    function testRejectRentalRequest(address user) external {
        // Arrange
        _setupSuccessRejectRentalRequestTests(user);

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
        _setupSuccessRejectRentalRequestTests(user);

        uint256 expectedBalance = Constants.MIN_RENT_PRICE * Constants.RENTAL_REQUEST_NUMBER_OF_DEPOSITS;

        // Act
        coreContract.rejectRentalRequest(0);

        // Assert
        uint256 balance = coreContract.balances(mockAddress);
        assertEq(balance, expectedBalance);
    }

    function testRejectRentalRequestEmitsRentalRequestApproved(address user) external {
        // Arrange
        _setupSuccessRejectRentalRequestTests(user);

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

        // rentals[0].tenant = user
        _writeToStorage(address(coreContract), RENTALS_MAPPING_BASE_STORAGE_SLOT, bytes32(uint256(uint160(user))), 1);

        vm.prank(user);

        // Assert
        vm.expectRevert(Errors.RentalNotApproved.selector);

        // Act
        coreContract.payRent(0);
    }

    function testCannotPayRentIfContractExpired(address user) external {
        // Arrange

        // rentals[0].tenant = user
        _writeToStorage(address(coreContract), RENTALS_MAPPING_BASE_STORAGE_SLOT, bytes32(uint256(uint160(user))), 1);

        // rentals[0].status = RentalStatus.Approved
        _writeToStorage(address(coreContract), RENTALS_MAPPING_BASE_STORAGE_SLOT, bytes32(uint256(2)), 4);

        vm.warp(53 weeks);
        vm.prank(user);

        // Assert
        vm.expectRevert(Errors.CannotPayRentAfterContractExpiry.selector);

        // Act
        coreContract.payRent(0);
    }

    function testCannotPayRentBeforePaymentDate(address user) external {
        // Arrange

        // rentals[0].tenant = user
        _writeToStorage(address(coreContract), RENTALS_MAPPING_BASE_STORAGE_SLOT, bytes32(uint256(uint160(user))), 1);

        // rentals[0].paymentDate = block.timestamp + 7 days
        _writeToStorage(address(coreContract), RENTALS_MAPPING_BASE_STORAGE_SLOT, bytes32(block.timestamp + 7 days), 3);

        // rentals[0].status = RentalStatus.Approved
        _writeToStorage(address(coreContract), RENTALS_MAPPING_BASE_STORAGE_SLOT, bytes32(uint256(2)), 4);

        vm.prank(user);

        // Assert
        vm.expectRevert(Errors.PayRentDateNotReached.selector);

        // Act
        coreContract.payRent(0);
    }

    function testCannotPayRentAfterLatePaymentDeadline(address user) external {
        // Arrange

        // rentals[0].tenant = user
        _writeToStorage(address(coreContract), RENTALS_MAPPING_BASE_STORAGE_SLOT, bytes32(uint256(uint160(user))), 1);

        // rentals[0].paymentDate = block.timestamp
        _writeToStorage(address(coreContract), RENTALS_MAPPING_BASE_STORAGE_SLOT, bytes32(block.timestamp), 3);

        // rentals[0].status = RentalStatus.Approved
        _writeToStorage(address(coreContract), RENTALS_MAPPING_BASE_STORAGE_SLOT, bytes32(uint256(2)), 4);

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

        vm.assume(0 <= invalidDeposit && invalidDeposit < Constants.MIN_RENT_PRICE);

        // rentals[0].tenant = user
        _writeToStorage(address(coreContract), RENTALS_MAPPING_BASE_STORAGE_SLOT, bytes32(uint256(uint160(user))), 1);

        // rentals[0].paymentDate = block.timestamp - 1 days
        _writeToStorage(address(coreContract), RENTALS_MAPPING_BASE_STORAGE_SLOT, bytes32(block.timestamp - 1), 3);

        // rentals[0].rentPrice = Constants.MIN_RENT_PRICE
        _writeToStorage(address(coreContract), RENTALS_MAPPING_BASE_STORAGE_SLOT, bytes32(Constants.MIN_RENT_PRICE));

        // rentals[0].status = RentalStatus.Approved
        _writeToStorage(address(coreContract), RENTALS_MAPPING_BASE_STORAGE_SLOT, bytes32(uint256(2)), 4);

        hoax(user, invalidDeposit);

        // Assert
        vm.expectRevert(Errors.IncorrectDeposit.selector);

        // Act
        coreContract.payRent{value: invalidDeposit}(0);
    }

    function _setupSuccessPayRentTests(address user) internal {
        _setUpOwnerOfMockCall(mockAddress);

        // rentals[0].tenant = user
        _writeToStorage(address(coreContract), RENTALS_MAPPING_BASE_STORAGE_SLOT, bytes32(uint256(uint160(user))), 1);

        // rentals[0].paymentDate = block.timestamp
        _writeToStorage(address(coreContract), RENTALS_MAPPING_BASE_STORAGE_SLOT, bytes32(block.timestamp), 3);

        // rentals[0].rentPrice = Constants.MIN_RENT_PRICE
        _writeToStorage(address(coreContract), RENTALS_MAPPING_BASE_STORAGE_SLOT, bytes32(Constants.MIN_RENT_PRICE));

        // rentals[0].status = RentalStatus.Approved
        _writeToStorage(address(coreContract), RENTALS_MAPPING_BASE_STORAGE_SLOT, bytes32(uint256(2)), 4);

        hoax(user, Constants.MIN_RENT_PRICE);
    }

    function testPayRentIncreasesTheOwnerBalance(address user) external {
        // Arrange
        _setupSuccessPayRentTests(user);

        // Act
        coreContract.payRent{value: Constants.MIN_RENT_PRICE}(0);

        // Assert
        uint256 balance = coreContract.balances(mockAddress);

        assertEq(balance, Constants.MIN_RENT_PRICE);
    }

    function testPayRentUpdatesThePayDateForTheRental(address user) external {
        // Arrange
        _setupSuccessPayRentTests(user);

        uint256 currentPayDate = block.timestamp;

        // Act
        coreContract.payRent{value: Constants.MIN_RENT_PRICE}(0);

        // Assert
        (,,, uint256 paymentDate,,) = coreContract.rentals(0);

        assertEq(paymentDate, currentPayDate + Constants.MONTH);
    }

    // signalMissedPayment()
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

        // rentals[0].status = RentalStatus.Approved
        _writeToStorage(address(coreContract), RENTALS_MAPPING_BASE_STORAGE_SLOT, bytes32(uint256(2)), 4);

        vm.prank(user);

        // Assert
        vm.expectRevert(Errors.RentLatePaymentDeadlineNotReached.selector);

        // Act
        coreContract.signalMissedPayment(0);
    }

    function _setupSuccessSignalMissedPaymentTests(address user) internal {
        _setUpOwnerOfMockCall(user);

        // rentals[0].status = RentalStatus.Approved
        _writeToStorage(address(coreContract), RENTALS_MAPPING_BASE_STORAGE_SLOT, bytes32(uint256(2)), 4);

        // rentals[0].rentPrice = Constants.MIN_RENT_PRICE
        _writeToStorage(address(coreContract), RENTALS_MAPPING_BASE_STORAGE_SLOT, bytes32(Constants.MIN_RENT_PRICE));

        // rentals[0].availableDeposits = Constants.RENTAL_REQUEST_NUMBER_OF_DEPOSITS
        _writeToStorage(
            address(coreContract),
            RENTALS_MAPPING_BASE_STORAGE_SLOT,
            bytes32(Constants.RENTAL_REQUEST_NUMBER_OF_DEPOSITS),
            2
        );

        vm.warp(37 days);

        vm.prank(user);
    }

    function testSignalMissedPaymentIncreasesTheOwnerBalanceIfAvailableDepositIsGreaterThan0(address user) external {
        // Arrange
        _setupSuccessSignalMissedPaymentTests(user);

        // Act
        coreContract.signalMissedPayment(0);

        // Assert
        uint256 balance = coreContract.balances(user);
        assertEq(balance, Constants.MIN_RENT_PRICE);
    }

    function testSignalMissedPaymentDecreasesTheNumberOfAvailableDepositsIfAvailableDepositIsGreaterThan0(address user)
        external
    {
        // Arrange
        _setupSuccessSignalMissedPaymentTests(user);

        uint256 expectedNumberOfDeposits = Constants.RENTAL_REQUEST_NUMBER_OF_DEPOSITS - 1;

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

        // rentals[0].status = RentalStatus.Approved
        _writeToStorage(address(coreContract), RENTALS_MAPPING_BASE_STORAGE_SLOT, bytes32(uint256(2)), 4);

        vm.prank(user);

        // Assert
        vm.expectRevert(Errors.RentalCompletionDateNotReached.selector);

        // Act
        coreContract.completeRental(0);
    }

    function _setupSuccessCompleteRentalTests(address user) internal {
        _setUpOwnerOfMockCall(user);

        // rentals[0].status = RentalStatus.Approved
        _writeToStorage(address(coreContract), RENTALS_MAPPING_BASE_STORAGE_SLOT, bytes32(uint256(2)), 4);

        // rentals[0].tenant = mockAddress
        _writeToStorage(
            address(coreContract), RENTALS_MAPPING_BASE_STORAGE_SLOT, bytes32(uint256(uint160(mockAddress))), 1
        );

        // rentals[0].rentPrice = Constants.MIN_RENT_PRICE
        _writeToStorage(address(coreContract), RENTALS_MAPPING_BASE_STORAGE_SLOT, bytes32(Constants.MIN_RENT_PRICE));

        // rentals[0].availableDeposits = Constants.RENTAL_REQUEST_NUMBER_OF_DEPOSITS
        _writeToStorage(
            address(coreContract),
            RENTALS_MAPPING_BASE_STORAGE_SLOT,
            bytes32(Constants.RENTAL_REQUEST_NUMBER_OF_DEPOSITS),
            2
        );

        vm.warp(53 weeks);

        vm.prank(user);
    }

    function testCompleteRentalIncrementsTenantBalance(address user) external {
        // Arrange
        _setupSuccessCompleteRentalTests(user);

        uint256 expectedBalance = Constants.MIN_RENT_PRICE * Constants.RENTAL_REQUEST_NUMBER_OF_DEPOSITS;

        // Act
        coreContract.completeRental(0);

        // Assert
        uint256 balance = coreContract.balances(mockAddress);

        assertEq(balance, expectedBalance);
    }

    function testCompleteRentalCleansTheRentalData(address user) external {
        // Arrange
        _setupSuccessCompleteRentalTests(user);

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

    function testWithdrawRevertsWithFailedToWithdrawIfTranferFails(address user) external {
        // Arrange
        vm.mockCall(user, abi.encode(""), abi.encode());

        // balances[user] = expectedBalance
        _writeToStorage(
            address(coreContract), keccak256(abi.encode(uint256(uint160(user)), uint256(7))), bytes32(uint256(1))
        );

        vm.prank(user);

        // Assert
        vm.expectRevert(Errors.FailedToWithdraw.selector);

        // Act
        coreContract.withdraw();
    }

    function _setupSuccessWithdrawTests(uint64 expectedBalance) internal {
        vm.assume(expectedBalance != 0);
        vm.deal(address(coreContract), 100000 ether);

        // balances[mockAddress] = expectedBalance
        _writeToStorage(
            address(coreContract),
            keccak256(abi.encode(uint256(uint160(mockAddress)), uint256(7))),
            bytes32(uint256(expectedBalance))
        );

        vm.prank(mockAddress);
    }

    function testWithdrawTransfersFundsToTheUser(uint64 expectedBalance) external {
        // Arrange
        _setupSuccessWithdrawTests(expectedBalance);

        // Act
        coreContract.withdraw();

        // Assert
        assertEq(mockAddress.balance, uint256(expectedBalance));
    }

    function testWithdrawDecreasesTheContractBalance(uint64 transferAmount) external {
        // Arrange
        _setupSuccessWithdrawTests(transferAmount);

        uint256 expectedBalance = address(coreContract).balance - uint256(transferAmount);

        // Act
        coreContract.withdraw();

        // Assert
        assertEq(address(coreContract).balance, expectedBalance);
    }
}
