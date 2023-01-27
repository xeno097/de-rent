// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "@contracts/Reputation.sol";
import "@contracts/libraries/Errors.sol";
import "@contracts/interfaces/IProperty.sol";

contract ReputationTest is Test {
    Reputation reputationContract;
    address constant mockAddress = address(97);

    string constant ozOwnableContractError = "Ownable: caller is not the owner";

    event UserScored(address indexed user, uint256 score);
    event PropertyScored(uint256 indexed property, uint256 score);
    event UserPaymentPerformanceScored(address indexed user, uint256 score);

    function setUp() public {
        reputationContract = new Reputation(mockAddress,mockAddress);
    }

    function _setUpExistsMockCall(uint256 property, bool returnValue) private {
        vm.mockCall(mockAddress, abi.encodeWithSelector(IProperty.exists.selector, property), abi.encode(returnValue));
    }

    // decimals()
    function testDecimalReturns9() external {
        // Arrange
        uint256 expectedResult = 9;

        // Act
        uint256 res = Constants.DECIMALS;

        //
        assertEq(res, expectedResult);
    }

    // scoreUser()
    function testCannotScoreUserIfNotFromCoreContractAddress() external {
        // Arrange
        uint256 validScore = 4;

        // Assert
        vm.expectRevert(bytes(ozOwnableContractError));

        // Act
        reputationContract.scoreUser(mockAddress, validScore);
    }

    function testCannotScoreUserWith0Address() external {
        // Arrange
        address expectedAddress = address(0);
        uint256 validScore = 4;

        vm.prank(mockAddress);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidAddress.selector, expectedAddress));

        // Act
        reputationContract.scoreUser(expectedAddress, validScore);
    }

    function testCannotScoreUserWithScoreOutsideOfMinScoreMaxScore(address user, uint256 score) external {
        // Arrange

        vm.assume(user != address(0));
        vm.assume(score < Constants.MIN_SCORE || score > Constants.MAX_SCORE);

        vm.prank(mockAddress);

        // Assert
        vm.expectRevert(
            abi.encodeWithSelector(Errors.ScoreValueOutOfRange.selector, Constants.MIN_SCORE, Constants.MAX_SCORE)
        );

        // Act
        reputationContract.scoreUser(user, score);
    }

    function testScoreUser(address user, uint256 score) external {
        // Arrange

        vm.assume(user != address(0));
        vm.assume(Constants.MIN_SCORE <= score && score <= Constants.MAX_SCORE);

        vm.prank(mockAddress);

        // Act
        reputationContract.scoreUser(user, score);
    }

    function testScoreUserEmitsUserScoredEvent(address user, uint256 score) external {
        // Arrange

        vm.assume(user != address(0));
        vm.assume(Constants.MIN_SCORE <= score && score <= Constants.MAX_SCORE);

        vm.prank(mockAddress);

        // Assert
        vm.expectEmit(true, true, false, true);

        emit UserScored(user, score);

        // Act
        reputationContract.scoreUser(user, score);
    }

    // scoreProperty()
    function testCannotScorePropertyIfNotFromCoreContractAddress(uint256 property) external {
        // Arrange
        _setUpExistsMockCall(property, true);
        uint256 validScore = 4;

        // Assert
        vm.expectRevert(bytes(ozOwnableContractError));

        // Act
        reputationContract.scoreUser(mockAddress, validScore);
    }

    function testCannotScorePropertyIfNotExists(uint256 property) external {
        // Arrange
        _setUpExistsMockCall(property, false);
        uint256 validScore = 4;

        vm.prank(mockAddress);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.PropertyNotFound.selector));

        // Act
        reputationContract.scoreProperty(property, validScore);
    }

    function testCannotScorePropertyWithScoreOutsideOfMinScoreMaxScore(uint256 property, uint256 score) external {
        // Arrange
        _setUpExistsMockCall(property, true);

        vm.assume(score < Constants.MIN_SCORE || score > Constants.MAX_SCORE);

        vm.prank(mockAddress);

        // Assert
        vm.expectRevert(
            abi.encodeWithSelector(Errors.ScoreValueOutOfRange.selector, Constants.MIN_SCORE, Constants.MAX_SCORE)
        );

        // Act
        reputationContract.scoreProperty(property, score);
    }

    function testScoreProperty(uint256 property, uint256 score) external {
        // Arrange
        _setUpExistsMockCall(property, true);

        vm.assume(Constants.MIN_SCORE <= score && score <= Constants.MAX_SCORE);

        vm.prank(mockAddress);

        // Act
        reputationContract.scoreProperty(property, score);
    }

    function testScorePropertyEmitsPropertyScored(uint256 property, uint256 score) external {
        // Arrange
        _setUpExistsMockCall(property, true);

        vm.assume(Constants.MIN_SCORE <= score && score <= Constants.MAX_SCORE);

        vm.prank(mockAddress);

        // Assert
        vm.expectEmit(true, true, false, true);

        emit PropertyScored(property, score);

        // Act
        reputationContract.scoreProperty(property, score);
    }

    // scoreUserPaymentPerformance()
    function testCannotScoreUserPaymentPerformanceIfNotFromCoreContractAddress() external {
        // Assert
        vm.expectRevert(bytes(ozOwnableContractError));

        // Act
        reputationContract.scoreUserPaymentPerformance(mockAddress, true);
    }

    function testCannotScoreUserPaymentPerformanceWith0Address() external {
        // Arrange
        address expectedAddress = address(0);

        vm.prank(mockAddress);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidAddress.selector, expectedAddress));

        // Act
        reputationContract.scoreUserPaymentPerformance(expectedAddress, true);
    }

    function testScoreUserPaymentPerformance(address user, bool paidOnTime) external {
        // Arrange
        vm.assume(user != address(0));

        vm.prank(mockAddress);

        // Act
        reputationContract.scoreUserPaymentPerformance(user, paidOnTime);
    }

    function testScoreUserPaymentPerformanceEmitsUserPaymentPerformanceScoredEvent(address user, bool paidOnTime)
        external
    {
        // Arrange
        vm.assume(user != address(0));

        uint256 score = paidOnTime ? Constants.MAX_SCORE : Constants.MIN_SCORE;

        vm.prank(mockAddress);

        // Assert
        vm.expectEmit(true, true, false, true);

        emit UserPaymentPerformanceScored(user, score);

        // Act
        reputationContract.scoreUserPaymentPerformance(user, paidOnTime);
    }

    // getUserScore()
    function testCannotGetUserScoreFor0Address() external {
        // Arrange
        address expectedAddress = address(0);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidAddress.selector, expectedAddress));

        // Act
        reputationContract.getUserScore(expectedAddress);
    }

    function testGetUserScoreReturnsTheMaximumScoreIfUserHas0RegisteredScores(address user) external {
        // Arrange
        vm.assume(user != address(0));
        uint256 expectedResult = Constants.MAX_SCORE * (10 ** Constants.DECIMALS);

        // Act
        uint256 res = reputationContract.getUserScore(user);

        // Assert
        assertEq(res, expectedResult);
    }

    function testGetUserScore(address user) external {
        // Arrange
        vm.assume(user != address(0));

        uint256[3] memory scores = [uint256(4), uint256(3), uint256(5)];
        uint256 expectedResult = ((scores[0] + scores[1] + scores[2]) * (10 ** Constants.DECIMALS)) / scores.length;

        for (uint256 i = 0; i < scores.length; i++) {
            vm.prank(mockAddress);
            reputationContract.scoreUser(user, scores[i]);
        }

        // Act
        uint256 res = reputationContract.getUserScore(user);

        // Assert
        assertEq(res, expectedResult);
    }

    // getPropertyScore()
    function testCannotGetPropertyScoreForNonExistantProperty() external {
        // Arrange
        uint256 expectedId = 0;
        _setUpExistsMockCall(expectedId, false);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.PropertyNotFound.selector));

        // Act
        reputationContract.getPropertyScore(expectedId);
    }

    function testGetPropertyScoreReturnsTheMaximumScoreIfPropertyHas0RegisteredScores(uint256 property) external {
        // Arrange
        _setUpExistsMockCall(property, true);
        uint256 expectedResult = Constants.MAX_SCORE * (10 ** Constants.DECIMALS);

        // Act
        uint256 res = reputationContract.getPropertyScore(property);

        // Assert
        assertEq(res, expectedResult);
    }

    function testGetPropertyScore(uint256 property) external {
        // Arrange
        _setUpExistsMockCall(property, true);
        uint256[3] memory scores = [uint256(4), uint256(3), uint256(5)];
        uint256 expectedResult = ((scores[0] + scores[1] + scores[2]) * (10 ** Constants.DECIMALS)) / scores.length;

        for (uint256 i = 0; i < scores.length; i++) {
            vm.prank(mockAddress);
            reputationContract.scoreProperty(property, scores[i]);
        }

        // Act
        uint256 res = reputationContract.getPropertyScore(property);

        // Assert
        assertEq(res, expectedResult);
    }

    // getUserPaymentPerformanceScore()
    function testCannotGetUserPaymentPerformanceScoreFor0Address() external {
        // Arrange
        address expectedAddress = address(0);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidAddress.selector, expectedAddress));

        // Act
        reputationContract.getUserPaymentPerformanceScore(expectedAddress);
    }

    function testGetUserPaymentPerformanceScoreReturnsTheMaximumScoreIfUserHas0RegisteredScores(address user)
        external
    {
        // Arrange
        vm.assume(user != address(0));
        uint256 expectedResult = Constants.MAX_SCORE * (10 ** Constants.DECIMALS);

        // Act
        uint256 res = reputationContract.getUserPaymentPerformanceScore(user);

        // Assert
        assertEq(res, expectedResult);
    }

    function testGetUserPaymentPerformanceScore(address user) external {
        // Arrange
        vm.assume(user != address(0));

        bool[3] memory scores = [true, false, true];
        uint256 expectedResult = (
            (Constants.MAX_SCORE + Constants.MIN_SCORE + Constants.MAX_SCORE) * (10 ** Constants.DECIMALS)
        ) / scores.length;

        for (uint256 i = 0; i < scores.length; i++) {
            vm.prank(mockAddress);
            reputationContract.scoreUserPaymentPerformance(user, scores[i]);
        }

        // Act
        uint256 res = reputationContract.getUserPaymentPerformanceScore(user);

        // Assert
        assertEq(res, expectedResult);
    }
}
