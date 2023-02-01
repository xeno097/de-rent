// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/BaseTest.sol";

import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import {IDiamond} from "@diamonds/interfaces/IDiamond.sol";
import {Diamond, DiamondArgs} from "@diamonds/Diamond.sol";
import {DiamondInit} from "@diamonds/upgradeInitializers/DiamondInit.sol";

import "@contracts/facets/CoreFacet.sol";
import "@contracts/libraries/Errors.sol";
import "@contracts/libraries/Constants.sol";
import "@contracts/libraries/DataTypes.sol";
import "@contracts/libraries/Events.sol";

contract CoreFacetTest is BaseTest {
    using ScoreCounters for ScoreCounters.ScoreCounter;

    CoreFacet coreContract;

    function setUp() public {
        CoreFacet coreContractInstance = new CoreFacet();
        DiamondInit initer = new DiamondInit();

        bytes4[] memory selectors = new bytes4[](11);

        selectors[0] = ICoreFacet.approveRentalRequest.selector;
        selectors[1] = ICoreFacet.rejectRentalRequest.selector;
        selectors[2] = ICoreFacet.requestRental.selector;
        selectors[3] = ICoreFacet.payRent.selector;
        selectors[4] = ICoreFacet.signalMissedPayment.selector;
        selectors[5] = ICoreFacet.reviewRental.selector;
        selectors[6] = ICoreFacet.completeRental.selector;
        selectors[7] = ICoreFacet.withdraw.selector;
        selectors[8] = ICoreFacet.balanceOf.selector;
        selectors[9] = IERC1155Receiver.onERC1155Received.selector;
        selectors[10] = IERC1155Receiver.onERC1155BatchReceived.selector;

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
        coreContract = CoreFacet(address(diamondProxy));

        _setUpOnERC1155ReceivedMockCall(address(coreContractInstance));
    }

    // requestRental()
    function testCannotRequestRentalForNonExistantProperty(address user, uint128 id) external {
        // Arrange
        vm.prank(user);

        // Assert
        vm.expectRevert(Errors.CannotRentNonExistantProperty.selector);

        // Act
        coreContract.requestRental(id);
    }

    function testCannotRequestRentalForOwnProperty(address user, uint128 id) external {
        // Arrange
        vm.assume(user != address(0));
        _setTokenOwner(address(coreContract), id, user);
        vm.prank(user);

        // Assert
        vm.expectRevert(Errors.CannotRentOwnProperty.selector);

        // Act
        coreContract.requestRental(id);
    }

    function testCannotRequestRentalIfPropertyIsAlreadyRented(address user, uint128 id) external {
        // Arrange
        vm.assume(user != mockAddress);
        _setTokenOwner(address(coreContract), id, mockAddress);

        DataTypes.Rental memory rentalMock = DataTypes.Rental({
            rentPrice: Constants.MIN_RENT_PRICE,
            tenant: mockAddress,
            availableDeposits: Constants.RENTAL_REQUEST_NUMBER_OF_DEPOSITS,
            paymentDate: block.timestamp,
            status: DataTypes.RentalStatus.Free,
            createdAt: block.timestamp
        });

        _createRental(address(coreContract), id, rentalMock);

        vm.prank(user);

        // Assert
        vm.expectRevert(Errors.CannotRentAlreadyRentedProperty.selector);

        // Act
        coreContract.requestRental(id);
    }

    function testCannotRequestRentalIfPropertyIsHidden(address user, uint128 id) external {
        // Arrange
        vm.assume(user != mockAddress);
        _setTokenOwner(address(coreContract), id, mockAddress);

        vm.prank(user);

        // Assert
        vm.expectRevert(Errors.CannotRentHiddenProperty.selector);

        // Act
        coreContract.requestRental(id);
    }

    function testCannotRequestRentalWithInvalidDeposit(address user, uint256 id) external {
        // Arrange
        vm.assume(user != mockAddress);
        _setTokenOwner(address(coreContract), id, mockAddress);

        DataTypes.Property memory mockProperty =
            DataTypes.Property({rentPrice: Constants.MIN_RENT_PRICE, published: true});

        _createProperty(address(coreContract), id, mockProperty);

        // Assert
        vm.expectRevert(Errors.IncorrectDeposit.selector);

        // Act
        coreContract.requestRental(id);
    }

    function _setupSuccessRequestRentalTests(address user, uint128 id) internal returns (uint256) {
        vm.assume(user != mockAddress);
        vm.assume(id < type(uint128).max);
        _setTokenOwner(address(coreContract), id, mockAddress);
        _setPropertyCount(address(coreContract), id + 1);

        DataTypes.Property memory mockProperty =
            DataTypes.Property({rentPrice: Constants.MIN_RENT_PRICE, published: true});

        _createProperty(address(coreContract), id, mockProperty);

        uint256 deposit = Constants.MIN_RENT_PRICE * Constants.RENTAL_REQUEST_NUMBER_OF_DEPOSITS;
        hoax(user, deposit);

        return deposit;
    }

    function testRequestRental(address user, uint128 id) external {
        // Arrange
        uint256 deposit = _setupSuccessRequestRentalTests(user, id);

        // Act
        coreContract.requestRental{value: deposit}(id);

        // Assert
        DataTypes.Rental memory rental = _readRental(address(coreContract), id);
        assertEq(rental.tenant, user);
    }

    function testRequestRentalIncreasesTheERC1155TokenContractBalance(address user, uint128 id) external {
        // Arrange
        uint256 deposit = _setupSuccessRequestRentalTests(user, id);

        // Act
        coreContract.requestRental{value: deposit}(id);

        // Assert
        uint256 contractBalance = coreContract.balanceOf(address(coreContract));
        assertEq(contractBalance, deposit);
    }

    function testRequestRentalEmitsRentalRequested(address user, uint128 id) external {
        // Arrange
        uint256 deposit = _setupSuccessRequestRentalTests(user, id);

        // Assert
        vm.expectEmit(true, false, false, true);

        emit Events.RentalRequested(id);

        // Act
        coreContract.requestRental{value: deposit}(id);
    }

    // approveRentalRequest()
    function testCannotApproveRentalRequestIfNotPropertyOwner(address user, uint128 id) external {
        // Arrange
        vm.assume(user != mockAddress);
        _setTokenOwner(address(coreContract), id, mockAddress);

        vm.prank(user);

        // Assert
        vm.expectRevert(Errors.NotPropertyOwner.selector);

        // Act
        coreContract.approveRentalRequest(id);
    }

    function testCannotApproveRentalRequestForNotPendingRequest(address user, uint256 id) external {
        // Arrange
        _setTokenOwner(address(coreContract), id, user);

        DataTypes.Rental memory rentalMock = DataTypes.Rental({
            rentPrice: Constants.MIN_RENT_PRICE,
            tenant: mockAddress,
            availableDeposits: Constants.RENTAL_REQUEST_NUMBER_OF_DEPOSITS,
            paymentDate: block.timestamp,
            status: DataTypes.RentalStatus.Free,
            createdAt: block.timestamp
        });

        _createRental(address(coreContract), id, rentalMock);

        vm.prank(user);

        // Assert
        vm.expectRevert(Errors.CannotApproveNotPendingRentalRequest.selector);

        // Act
        coreContract.approveRentalRequest(id);
    }

    function _setupSuccessApproveRentalRequest(address user, uint128 id) internal {
        vm.assume(id < type(uint128).max);
        _setTokenOwner(address(coreContract), id, user);
        _setPropertyCount(address(coreContract), id + 1);

        DataTypes.Rental memory rentalMock = DataTypes.Rental({
            rentPrice: Constants.MIN_RENT_PRICE,
            tenant: mockAddress,
            availableDeposits: Constants.RENTAL_REQUEST_NUMBER_OF_DEPOSITS,
            paymentDate: block.timestamp,
            status: DataTypes.RentalStatus.Pending,
            createdAt: block.timestamp
        });

        _createRental(address(coreContract), id, rentalMock);

        vm.prank(user);
    }

    function testApproveRentalRequest(address user, uint128 id) external {
        // Arrange
        _setupSuccessApproveRentalRequest(user, id);

        // Act
        coreContract.approveRentalRequest(id);

        // Assert
        DataTypes.Rental memory rental = _readRental(address(coreContract), id);
        assertEq(uint8(rental.status), uint8(DataTypes.RentalStatus.Approved));
        assertGe(rental.createdAt, uint256(0));
        assertEq(rental.paymentDate, rental.createdAt + Constants.MONTH);
    }

    function testApproveRentalRequestEmitsRentalRequestApproved(address user, uint128 id) external {
        // Arrange
        _setupSuccessApproveRentalRequest(user, id);

        // Assert
        vm.expectEmit(true, false, false, true);

        emit Events.RentalRequestApproved(id);

        // Act
        coreContract.approveRentalRequest(id);
    }

    // rejectRentalRequest()
    function testCannotRejectRentalRequestIfNotPropertyOwner(address user, uint128 id) external {
        // Arrange
        vm.assume(user != mockAddress);
        _setTokenOwner(address(coreContract), id, mockAddress);

        vm.prank(user);

        // Assert
        vm.expectRevert(Errors.NotPropertyOwner.selector);

        // Act
        coreContract.rejectRentalRequest(id);
    }

    function testCannotRejectRentalRequestForNotPendingRequest(address user, uint256 id) external {
        // Arrange
        _setTokenOwner(address(coreContract), id, user);

        DataTypes.Rental memory rentalMock = DataTypes.Rental({
            rentPrice: Constants.MIN_RENT_PRICE,
            tenant: mockAddress,
            availableDeposits: Constants.RENTAL_REQUEST_NUMBER_OF_DEPOSITS,
            paymentDate: block.timestamp,
            status: DataTypes.RentalStatus.Free,
            createdAt: block.timestamp
        });

        _createRental(address(coreContract), id, rentalMock);

        vm.prank(user);

        // Assert
        vm.expectRevert(Errors.CannotApproveNotPendingRentalRequest.selector);

        // Act
        coreContract.rejectRentalRequest(id);
    }

    function _setupSuccessRejectRentalRequestTests(address user, uint128 id) internal {
        vm.assume(id < type(uint128).max);
        _setTokenOwner(address(coreContract), id, user);
        _setPropertyCount(address(coreContract), id + 1);
        _createTokenBalance(
            address(coreContract),
            Constants.DE_RENT_USER_BALANCES_TOKEN_ID,
            address(coreContract),
            Constants.RENTAL_REQUEST_NUMBER_OF_DEPOSITS * Constants.MIN_RENT_PRICE
        );

        DataTypes.Rental memory rentalMock = DataTypes.Rental({
            rentPrice: Constants.MIN_RENT_PRICE,
            tenant: mockAddress,
            availableDeposits: Constants.RENTAL_REQUEST_NUMBER_OF_DEPOSITS,
            paymentDate: block.timestamp,
            status: DataTypes.RentalStatus.Pending,
            createdAt: block.timestamp
        });

        _createRental(address(coreContract), id, rentalMock);

        vm.prank(user);
    }

    function testRejectRentalRequest(address user, uint128 id) external {
        // Arrange
        _setupSuccessRejectRentalRequestTests(user, id);

        // Act
        coreContract.rejectRentalRequest(id);

        // Assert
        DataTypes.Rental memory rental = _readRental(address(coreContract), id);

        assertEq(rental.rentPrice, 0);
        assertEq(rental.tenant, address(0));
        assertEq(rental.availableDeposits, 0);
        assertEq(rental.paymentDate, 0);
        assertEq(uint8(rental.status), uint8(DataTypes.RentalStatus.Free));
        assertEq(rental.createdAt, 0);
    }

    function testRejectRentalRequestIncreasesTenantBalance(address user, uint128 id) external {
        // Arrange
        _setupSuccessRejectRentalRequestTests(user, id);

        uint256 expectedBalance = Constants.MIN_RENT_PRICE * Constants.RENTAL_REQUEST_NUMBER_OF_DEPOSITS;

        // Act
        coreContract.rejectRentalRequest(id);

        // Assert
        uint256 balance = coreContract.balanceOf(mockAddress);
        assertEq(balance, expectedBalance);
    }

    function testRejectRentalRequestEmitsRentalRequestApproved(address user, uint128 id) external {
        // Arrange
        _setupSuccessRejectRentalRequestTests(user, id);

        // Assert
        vm.expectEmit(true, false, false, true);

        emit Events.RentalRequestRejected(id);

        // Act
        coreContract.rejectRentalRequest(id);
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

    function testCannotPayRentIfRentalIsNotApproved(address user, uint256 id) external {
        // Arrange
        DataTypes.Rental memory rentalMock = DataTypes.Rental({
            rentPrice: Constants.MIN_RENT_PRICE,
            tenant: user,
            availableDeposits: Constants.RENTAL_REQUEST_NUMBER_OF_DEPOSITS,
            paymentDate: block.timestamp,
            status: DataTypes.RentalStatus.Pending,
            createdAt: block.timestamp
        });

        _createRental(address(coreContract), id, rentalMock);

        vm.prank(user);

        // Assert
        vm.expectRevert(Errors.RentalNotApproved.selector);

        // Act
        coreContract.payRent(id);
    }

    function testCannotPayRentIfContractExpired(address user, uint256 id) external {
        // Arrange
        DataTypes.Rental memory rentalMock = DataTypes.Rental({
            rentPrice: Constants.MIN_RENT_PRICE,
            tenant: user,
            availableDeposits: Constants.RENTAL_REQUEST_NUMBER_OF_DEPOSITS,
            paymentDate: block.timestamp,
            status: DataTypes.RentalStatus.Approved,
            createdAt: block.timestamp
        });

        _createRental(address(coreContract), id, rentalMock);

        vm.warp(53 weeks);
        vm.prank(user);

        // Assert
        vm.expectRevert(Errors.RentContractExpiryDateReached.selector);

        // Act
        coreContract.payRent(id);
    }

    function testCannotPayRentBeforePaymentDate(address user, uint256 id) external {
        // Arrange
        DataTypes.Rental memory rentalMock = DataTypes.Rental({
            rentPrice: 0,
            tenant: user,
            availableDeposits: Constants.RENTAL_REQUEST_NUMBER_OF_DEPOSITS,
            paymentDate: block.timestamp + 7 days,
            status: DataTypes.RentalStatus.Approved,
            createdAt: block.timestamp
        });

        _createRental(address(coreContract), id, rentalMock);

        vm.prank(user);

        // Assert
        vm.expectRevert(Errors.RentPaymentDateNotReached.selector);

        // Act
        coreContract.payRent(id);
    }

    function testRentLatePaymentDeadlineReached(address user, uint256 id) external {
        // Arrange
        DataTypes.Rental memory rentalMock = DataTypes.Rental({
            rentPrice: 0,
            tenant: user,
            availableDeposits: Constants.RENTAL_REQUEST_NUMBER_OF_DEPOSITS,
            paymentDate: block.timestamp,
            status: DataTypes.RentalStatus.Approved,
            createdAt: block.timestamp
        });

        _createRental(address(coreContract), id, rentalMock);

        vm.warp(7 days);

        vm.prank(user);

        // Assert
        vm.expectRevert(Errors.RentLatePaymentDeadlineReached.selector);

        // Act
        coreContract.payRent(id);
    }

    function testCannotPayRentWithAnIncorrectDeposit(address user, uint256 id, uint256 invalidDeposit) external {
        // Arrange
        vm.warp(7 days);

        vm.assume(0 <= invalidDeposit && invalidDeposit < Constants.MIN_RENT_PRICE);

        DataTypes.Rental memory rentalMock = DataTypes.Rental({
            rentPrice: Constants.MIN_RENT_PRICE,
            tenant: user,
            availableDeposits: Constants.RENTAL_REQUEST_NUMBER_OF_DEPOSITS,
            paymentDate: block.timestamp - 1,
            status: DataTypes.RentalStatus.Approved,
            createdAt: block.timestamp
        });

        _createRental(address(coreContract), id, rentalMock);

        hoax(user, invalidDeposit);

        // Assert
        vm.expectRevert(Errors.IncorrectDeposit.selector);

        // Act
        coreContract.payRent{value: invalidDeposit}(id);
    }

    function _setupSuccessPayRentTests(address user, uint128 id) internal {
        vm.assume(id < type(uint128).max);
        _setTokenOwner(address(coreContract), id, mockAddress);
        _setPropertyCount(address(coreContract), id + 1);

        DataTypes.Rental memory rentalMock = DataTypes.Rental({
            rentPrice: Constants.MIN_RENT_PRICE,
            tenant: user,
            availableDeposits: Constants.RENTAL_REQUEST_NUMBER_OF_DEPOSITS,
            paymentDate: block.timestamp,
            status: DataTypes.RentalStatus.Approved,
            createdAt: block.timestamp
        });

        _createRental(address(coreContract), id, rentalMock);

        hoax(user, Constants.MIN_RENT_PRICE);
    }

    function testPayRentIncreasesTheOwnerBalance(address user, uint128 id) external {
        // Arrange
        _setupSuccessPayRentTests(user, id);

        // Act
        coreContract.payRent{value: Constants.MIN_RENT_PRICE}(id);

        // Assert
        uint256 balance = coreContract.balanceOf(mockAddress);
        assertEq(balance, Constants.MIN_RENT_PRICE);
    }

    function testPayRentUpdatesThePayDateForTheRental(address user, uint128 id) external {
        // Arrange
        _setupSuccessPayRentTests(user, id);

        uint256 currentPayDate = block.timestamp;

        // Act
        coreContract.payRent{value: Constants.MIN_RENT_PRICE}(id);

        // Assert
        DataTypes.Rental memory rental = _readRental(address(coreContract), id);

        assertEq(rental.paymentDate, currentPayDate + Constants.MONTH);
    }

    function testPayRentUpdatesTheTenantPaymentPerformanceScore(address user, uint128 id) external {
        // Arrange
        _setupSuccessPayRentTests(user, id);

        uint256 baseVoteCount = 3;
        uint256 baseTotalScore = 11;
        _createUserPaymentPerformanceScore(address(coreContract), user, baseTotalScore, baseVoteCount);

        // Act
        coreContract.payRent{value: Constants.MIN_RENT_PRICE}(id);

        // Assert
        ScoreCounters.ScoreCounter memory userScore = _readUserPaymentPerformanceScore(address(coreContract), user);

        assertEq(userScore._totalScore, baseTotalScore + Constants.MAX_SCORE);
        assertEq(userScore._voteCount, baseVoteCount + 1);
    }

    function testPayRentEmitsUserPaymentPerformanceScored(address user, uint128 id) external {
        // Arrange
        _setupSuccessPayRentTests(user, id);

        // Assert
        vm.expectEmit(true, true, false, true);

        emit Events.UserPaymentPerformanceScored(user, Constants.MAX_SCORE);

        // Act
        coreContract.payRent{value: Constants.MIN_RENT_PRICE}(id);
    }

    // signalMissedPayment()
    function testCannotSignalMissedPaymentIfNotPropertyOwner(address user, uint128 id) external {
        // Arrange
        vm.assume(user != mockAddress);
        _setTokenOwner(address(coreContract), id, mockAddress);

        vm.prank(user);

        // Assert
        vm.expectRevert(Errors.NotPropertyOwner.selector);

        // Act
        coreContract.signalMissedPayment(id);
    }

    function testCannotSignalMissedPaymentIfRentalIsNotApproved(address user, uint128 id) external {
        // Arrange
        _setTokenOwner(address(coreContract), id, user);

        vm.prank(user);

        // Assert
        vm.expectRevert(Errors.RentalNotApproved.selector);

        // Act
        coreContract.signalMissedPayment(id);
    }

    function testCannotSignalMissedPaymentBeforeLatePaymentDeadline(address user, uint256 id) external {
        // Arrange
        _setTokenOwner(address(coreContract), id, user);

        DataTypes.Rental memory rentalMock = DataTypes.Rental({
            rentPrice: Constants.MIN_RENT_PRICE,
            tenant: user,
            availableDeposits: Constants.RENTAL_REQUEST_NUMBER_OF_DEPOSITS,
            paymentDate: block.timestamp,
            status: DataTypes.RentalStatus.Approved,
            createdAt: block.timestamp
        });

        _createRental(address(coreContract), id, rentalMock);

        vm.prank(user);

        // Assert
        vm.expectRevert(Errors.RentLatePaymentDeadlineNotReached.selector);

        // Act
        coreContract.signalMissedPayment(id);
    }

    function _setupSuccessSignalMissedPaymentTests(address user, uint128 id) internal {
        vm.assume(user != address(0) && user != 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        vm.assume(id < type(uint128).max);
        _setPropertyCount(address(coreContract), id + 1);
        _setTokenOwner(address(coreContract), id, user);
        _setUpOnERC1155ReceivedMockCall(address(user));

        _createTokenBalance(
            address(coreContract),
            Constants.DE_RENT_USER_BALANCES_TOKEN_ID,
            address(coreContract),
            Constants.MIN_RENT_PRICE * Constants.RENTAL_REQUEST_NUMBER_OF_DEPOSITS
        );

        DataTypes.Rental memory rentalMock = DataTypes.Rental({
            rentPrice: Constants.MIN_RENT_PRICE,
            tenant: mockAddress,
            availableDeposits: Constants.RENTAL_REQUEST_NUMBER_OF_DEPOSITS,
            paymentDate: block.timestamp,
            status: DataTypes.RentalStatus.Approved,
            createdAt: block.timestamp
        });

        _createRental(address(coreContract), id, rentalMock);

        vm.warp(37 days);

        vm.prank(user);
    }

    function testSignalMissedPaymentIncreasesTheOwnerBalanceIfAvailableDepositIsGreaterThan0(address user, uint128 id)
        external
    {
        // Arrange
        _setupSuccessSignalMissedPaymentTests(user, id);

        // Act
        coreContract.signalMissedPayment(id);

        // Assert
        uint256 balance = coreContract.balanceOf(user);
        assertEq(balance, Constants.MIN_RENT_PRICE);
    }

    function testSignalMissedPaymentDecreasesTheNumberOfAvailableDepositsIfAvailableDepositIsGreaterThan0(
        address user,
        uint128 id
    ) external {
        // Arrange
        _setupSuccessSignalMissedPaymentTests(user, id);

        uint256 expectedNumberOfDeposits = Constants.RENTAL_REQUEST_NUMBER_OF_DEPOSITS - 1;

        // Act
        coreContract.signalMissedPayment(id);

        // Assert
        DataTypes.Rental memory rental = _readRental(address(coreContract), id);
        assertEq(rental.availableDeposits, expectedNumberOfDeposits);
    }

    function testSignalMissedPaymentUpdatesTheTenantPaymentPerformanceScore(address user, uint128 id) external {
        // Arrange
        _setupSuccessSignalMissedPaymentTests(user, id);

        uint256 baseVoteCount = 3;
        uint256 baseTotalScore = 11;
        _createUserPaymentPerformanceScore(address(coreContract), mockAddress, baseTotalScore, baseVoteCount);

        // Act
        coreContract.signalMissedPayment(id);

        // Assert
        ScoreCounters.ScoreCounter memory userScore =
            _readUserPaymentPerformanceScore(address(coreContract), mockAddress);

        assertEq(userScore._totalScore, baseTotalScore + Constants.MIN_SCORE);
        assertEq(userScore._voteCount, baseVoteCount + 1);
    }

    function testSignalMissedPaymentEmitsUserPaymentPerformanceScored(address user, uint128 id) external {
        // Arrange
        _setupSuccessSignalMissedPaymentTests(user, id);

        // Assert
        vm.expectEmit(true, true, false, true);

        emit Events.UserPaymentPerformanceScored(mockAddress, Constants.MIN_SCORE);

        // Act
        coreContract.signalMissedPayment(id);
    }

    // reviewRental
    function testCannotReviewRentalIfNotPropertyTenant(address user) external {
        // Arrange
        vm.assume(user != address(0));
        vm.prank(user);

        // Assert
        vm.expectRevert(Errors.NotPropertyTenant.selector);

        // Act
        coreContract.reviewRental(0, 1, 1);
    }

    function testCannotReviewRentalIfRentalRequestHasNotBeenApproved(address user, uint256 id) external {
        // Arrange
        vm.prank(user);

        DataTypes.Rental memory rentalMock = DataTypes.Rental({
            rentPrice: Constants.MIN_RENT_PRICE,
            tenant: user,
            availableDeposits: Constants.RENTAL_REQUEST_NUMBER_OF_DEPOSITS,
            paymentDate: block.timestamp,
            status: DataTypes.RentalStatus.Pending,
            createdAt: block.timestamp
        });

        _createRental(address(coreContract), id, rentalMock);

        // Assert
        vm.expectRevert(Errors.RentalNotApproved.selector);

        // Act
        coreContract.reviewRental(id, 1, 1);
    }

    function testCannotReviewRentalBeforeContractExpiry(address user, uint256 id) external {
        // Arrange
        vm.prank(user);

        DataTypes.Rental memory rentalMock = DataTypes.Rental({
            rentPrice: Constants.MIN_RENT_PRICE,
            tenant: user,
            availableDeposits: Constants.RENTAL_REQUEST_NUMBER_OF_DEPOSITS,
            paymentDate: block.timestamp,
            status: DataTypes.RentalStatus.Approved,
            createdAt: block.timestamp
        });

        _createRental(address(coreContract), id, rentalMock);

        // Assert
        vm.expectRevert(Errors.RentalCompletionDateNotReached.selector);

        // Act
        coreContract.reviewRental(id, 1, 1);
    }

    function testCannotReviewRentalAfterRentalReviewDate(address user, uint256 id) external {
        // Arrange
        vm.prank(user);

        DataTypes.Rental memory rentalMock = DataTypes.Rental({
            rentPrice: Constants.MIN_RENT_PRICE,
            tenant: user,
            availableDeposits: Constants.RENTAL_REQUEST_NUMBER_OF_DEPOSITS,
            paymentDate: block.timestamp,
            status: DataTypes.RentalStatus.Approved,
            createdAt: block.timestamp
        });

        _createRental(address(coreContract), id, rentalMock);

        vm.warp(Constants.CONTRACT_DURATION + 3 days);

        // Assert
        vm.expectRevert(Errors.RentalReviewDeadlineReached.selector);

        // Act
        coreContract.reviewRental(id, 1, 1);
    }

    function _setupSuccessReviewRentalTests(address user, uint128 id) internal {
        vm.assume(user != address(0));
        vm.assume(id < type(uint128).max);

        vm.prank(user);

        _setPropertyCount(address(coreContract), id + 1);
        _setTokenOwner(address(coreContract), id, mockAddress);

        DataTypes.Rental memory rentalMock = DataTypes.Rental({
            rentPrice: Constants.MIN_RENT_PRICE,
            tenant: user,
            availableDeposits: Constants.RENTAL_REQUEST_NUMBER_OF_DEPOSITS,
            paymentDate: block.timestamp,
            status: DataTypes.RentalStatus.Approved,
            createdAt: block.timestamp
        });

        _createRental(address(coreContract), id, rentalMock);

        vm.warp(Constants.CONTRACT_DURATION + 1 days);
    }

    function testReviewRental(address user, uint128 id) external {
        // Arrange
        _setupSuccessReviewRentalTests(user, id);

        // Act
        coreContract.reviewRental(id, 1, 1);

        // Assert
        DataTypes.Rental memory rental = _readRental(address(coreContract), id);

        assertEq(uint8(rental.status), uint8(DataTypes.RentalStatus.Completed));
    }

    function testReviewRentalUpdatesTheOwnerScore(address user, uint128 id) external {
        // Arrange
        _setupSuccessReviewRentalTests(user, id);

        uint256 baseVoteCount = 3;
        uint256 baseTotalScore = 11;
        _createUserScore(address(coreContract), mockAddress, baseTotalScore, baseVoteCount);

        uint256 userVote = 3;

        // Act
        coreContract.reviewRental(id, 1, userVote);

        // Assert
        ScoreCounters.ScoreCounter memory userScore = _readUserScore(address(coreContract), mockAddress);

        assertEq(userScore._totalScore, baseTotalScore + userVote);
        assertEq(userScore._voteCount, baseVoteCount + 1);
    }

    function testReviewRentalEmitsUserScored(address user, uint128 id) external {
        // Arrange
        _setupSuccessReviewRentalTests(user, id);

        uint256 expectedUserVote = 3;

        // Assert
        vm.expectEmit(true, true, false, true);

        emit Events.UserScored(mockAddress, expectedUserVote);

        // Act
        coreContract.reviewRental(id, 1, expectedUserVote);
    }

    function testReviewRentalUpdatesThePropertyScore(address user, uint128 id) external {
        // Arrange
        _setupSuccessReviewRentalTests(user, id);

        uint256 propertyVote = 3;

        // Act
        coreContract.reviewRental(id, propertyVote, 1);

        // Assert
        ScoreCounters.ScoreCounter memory userScore = _readRentalScore(address(coreContract), id);

        assertEq(userScore._totalScore, propertyVote);
        assertEq(userScore._voteCount, 1);
    }

    function testReviewRentalEmitsPropertyScored(address user, uint128 id) external {
        // Arrange
        _setupSuccessReviewRentalTests(user, id);

        uint256 expectedPropertyVote = 3;

        // Assert
        vm.expectEmit(true, true, false, true);

        emit Events.PropertyScored(id, expectedPropertyVote);

        // Act
        coreContract.reviewRental(id, expectedPropertyVote, 1);
    }

    // completeRental()
    function testCannotCompleteRentalIfNotPropertyOwner(address user, uint128 id) external {
        // Arrange
        vm.assume(user != mockAddress);
        _setTokenOwner(address(coreContract), id, mockAddress);

        vm.prank(user);

        // Assert
        vm.expectRevert(Errors.NotPropertyOwner.selector);

        // Act
        coreContract.completeRental(id, 1);
    }

    function testCannotCompleteRentalIfRentalCompletionDateIsNotReached(address user, uint256 id) external {
        // Arrange
        _setTokenOwner(address(coreContract), id, user);

        DataTypes.Rental memory rentalMock = DataTypes.Rental({
            rentPrice: Constants.MIN_RENT_PRICE,
            tenant: mockAddress,
            availableDeposits: Constants.RENTAL_REQUEST_NUMBER_OF_DEPOSITS,
            paymentDate: block.timestamp,
            status: DataTypes.RentalStatus.Approved,
            createdAt: block.timestamp
        });

        _createRental(address(coreContract), id, rentalMock);

        vm.prank(user);

        // Assert
        vm.expectRevert(Errors.RentalCompletionDateNotReached.selector);

        // Act
        coreContract.completeRental(id, 1);
    }

    function testCannotCompleteRentalIfRentalIsNotCompleted(address user, uint128 id) external {
        // Arrange
        _setTokenOwner(address(coreContract), id, user);

        vm.prank(user);

        vm.warp(Constants.CONTRACT_DURATION + 1 days);

        // Assert
        vm.expectRevert(Errors.RentalReviewDeadlineNotReached.selector);

        // Act
        coreContract.completeRental(id, 1);
    }

    function testCannotCompleteRentalIfRentalReviewDealineIsNotReached(address user, uint256 id) external {
        // Arrange
        _setTokenOwner(address(coreContract), id, user);

        DataTypes.Rental memory rentalMock = DataTypes.Rental({
            rentPrice: Constants.MIN_RENT_PRICE,
            tenant: mockAddress,
            availableDeposits: Constants.RENTAL_REQUEST_NUMBER_OF_DEPOSITS,
            paymentDate: block.timestamp,
            status: DataTypes.RentalStatus.Approved,
            createdAt: block.timestamp
        });

        _createRental(address(coreContract), id, rentalMock);

        vm.prank(user);

        vm.warp(Constants.CONTRACT_DURATION + 1 days);

        // Assert
        vm.expectRevert(Errors.RentalReviewDeadlineNotReached.selector);

        // Act
        coreContract.completeRental(id, 1);
    }

    function _setupSuccessCompleteRentalTests(address user, uint128 id) internal {
        vm.assume(user != address(0));
        vm.assume(id < type(uint128).max);

        _setPropertyCount(address(coreContract), id + 1);
        _setTokenOwner(address(coreContract), id, user);
        _createTokenBalance(
            address(coreContract),
            Constants.DE_RENT_USER_BALANCES_TOKEN_ID,
            address(coreContract),
            Constants.MIN_RENT_PRICE * Constants.RENTAL_REQUEST_NUMBER_OF_DEPOSITS
        );

        DataTypes.Rental memory rentalMock = DataTypes.Rental({
            rentPrice: Constants.MIN_RENT_PRICE,
            tenant: mockAddress,
            availableDeposits: Constants.RENTAL_REQUEST_NUMBER_OF_DEPOSITS,
            paymentDate: block.timestamp,
            status: DataTypes.RentalStatus.Approved,
            createdAt: block.timestamp
        });

        _createRental(address(coreContract), id, rentalMock);

        vm.warp(53 weeks);

        vm.prank(user);
    }

    function testCompleteRentalIncrementsTenantBalance(address user, uint128 id) external {
        // Arrange
        _setupSuccessCompleteRentalTests(user, id);

        uint256 expectedBalance = Constants.MIN_RENT_PRICE * Constants.RENTAL_REQUEST_NUMBER_OF_DEPOSITS;

        // Act
        coreContract.completeRental(id, 1);

        // Assert
        uint256 balance = coreContract.balanceOf(mockAddress);
        assertEq(balance, expectedBalance);
    }

    function testCompleteRentalUpdatesTheTentantScore(address user, uint128 id) external {
        // Arrange
        _setupSuccessCompleteRentalTests(user, id);

        uint256 expectedUserVote = 1;

        // Act
        coreContract.completeRental(id, expectedUserVote);

        // Assert
        ScoreCounters.ScoreCounter memory userScore = _readUserScore(address(coreContract), mockAddress);

        assertEq(userScore._totalScore, expectedUserVote);
        assertEq(userScore._voteCount, 1);
    }

    function testCompleteRentalEmitsUserScored(address user, uint128 id) external {
        // Arrange
        _setupSuccessCompleteRentalTests(user, id);

        uint256 expectedUserVote = 3;

        // Assert
        vm.expectEmit(true, true, false, true);

        emit Events.UserScored(mockAddress, expectedUserVote);

        // Act
        coreContract.completeRental(id, expectedUserVote);
    }

    // withdraw()
    function testCannotWithdrawIfUserBalanceIs0(address user) external {
        // Arrange
        vm.assume(user != address(0));
        vm.prank(user);

        // Assert
        vm.expectRevert(Errors.InsufficientBalance.selector);

        // Act
        coreContract.withdraw();
    }

    function testWithdrawRevertsWithFailedToWithdrawIfTranferFails(address user, uint256 balance) external {
        // Arrange
        vm.assume(balance != 0);
        vm.assume(user != address(0));
        vm.mockCall(user, abi.encode(""), abi.encode());

        _createTokenBalance(address(coreContract), Constants.DE_RENT_USER_BALANCES_TOKEN_ID, user, balance);

        vm.prank(user);

        // Assert
        vm.expectRevert(Errors.FailedToWithdraw.selector);

        // Act
        coreContract.withdraw();
    }

    function _setupSuccessWithdrawTests(uint64 expectedBalance, address user) internal {
        vm.assume(expectedBalance != 0);
        vm.deal(address(coreContract), 100000 ether);

        _createTokenBalance(address(coreContract), Constants.DE_RENT_USER_BALANCES_TOKEN_ID, user, expectedBalance);

        vm.prank(user);
    }

    function testWithdrawTransfersFundsToTheUser(uint64 expectedBalance) external {
        // Arrange
        _setupSuccessWithdrawTests(expectedBalance, mockAddress);

        // Act
        coreContract.withdraw();

        // Assert
        assertEq(mockAddress.balance, uint256(expectedBalance));
    }

    function testWithdrawSetsTheUserBalanceTo0(uint64 expectedBalance) external {
        // Arrange
        _setupSuccessWithdrawTests(expectedBalance, mockAddress);

        // Act
        coreContract.withdraw();

        // Assert
        uint256 balance = coreContract.balanceOf(mockAddress);
        assertEq(balance, 0);
    }

    function testWithdrawDecreasesTheContractBalance(uint64 transferAmount) external {
        // Arrange
        _setupSuccessWithdrawTests(transferAmount, mockAddress);

        uint256 expectedBalance = address(coreContract).balance - uint256(transferAmount);

        // Act
        coreContract.withdraw();

        // Assert
        assertEq(address(coreContract).balance, expectedBalance);
    }
}
