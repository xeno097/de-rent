// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "@contracts/facets/ReputationFacet.sol";
import "./utils/BaseTest.sol";
import "@contracts/libraries/Errors.sol";
import "@contracts/interfaces/IProperty.sol";
import {IDiamond} from "@diamonds/interfaces/IDiamond.sol";
import {Diamond, DiamondArgs} from "@diamonds/Diamond.sol";
import {DiamondInit} from "@diamonds/upgradeInitializers/DiamondInit.sol";

contract ReputationTest is BaseTest {
    ReputationFacet reputationContract;
    Diamond diamondProxy;

    function setUp() public {
        ReputationFacet reputationContractInstance = new ReputationFacet();
        DiamondInit initer = new DiamondInit();

        bytes4[] memory selectors = new bytes4[](4);

        selectors[0] = (IReputationReader.decimals.selector);
        selectors[1] = (IReputationReader.getUserScore.selector);
        selectors[2] = (IReputationReader.getPropertyScore.selector);
        selectors[3] = (IReputationReader.getUserPaymentPerformanceScore.selector);

        IDiamond.FacetCut[] memory diamondCut = new IDiamond.FacetCut[](1);

        diamondCut[0] = IDiamond.FacetCut({
            facetAddress: address(reputationContractInstance),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: selectors
        });

        DiamondArgs memory args = DiamondArgs({
            owner: address(this),
            init: address(initer),
            initCalldata: abi.encodeWithSelector(DiamondInit.init.selector, address(mockAddress))
        });

        diamondProxy = new Diamond(diamondCut, args);
        reputationContract = ReputationFacet(address(diamondProxy));
    }

    // decimals()
    function testDecimalReturns9() external {
        // Arrange
        uint256 expectedResult = 9;

        // Act
        uint256 res = reputationContract.decimals();

        // Act
        assertEq(res, expectedResult);
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

        _createUserScore(address(reputationContract), user, scores[0] + scores[1] + scores[2], 3);

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

        _createPropertyScore(address(reputationContract), property, scores[0] + scores[1] + scores[2], 3);

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

        _createUserPaymentPerformanceScore(
            address(reputationContract), user, Constants.MAX_SCORE + Constants.MIN_SCORE + Constants.MAX_SCORE, 3
        );

        // Act
        uint256 res = reputationContract.getUserPaymentPerformanceScore(user);

        // Assert
        assertEq(res, expectedResult);
    }
}
