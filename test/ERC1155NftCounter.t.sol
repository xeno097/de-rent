// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/BaseTest.sol";

import "@contracts/libraries/ERC1155NftCounter.sol";

contract ERC1155NftCounterTest is BaseTest {
    using ERC1155NftCounter for ERC1155NftCounter.Counter;

    ERC1155NftCounter.Counter counter;

    function setUp() public {
        counter = ERC1155NftCounter.Counter(0);
    }

    // current()
    function testCurrentReturnsTheCurrentValue(uint128 expectedValue) external {
        // Arrange
        counter = ERC1155NftCounter.Counter(expectedValue);

        // Assert
        uint256 value = counter.current();

        // Act
        assertEq(value, expectedValue);
    }

    // increment()
    function testCannotIncrementIfCounterValueIsMaxValue() external {
        // Arrange
        counter = ERC1155NftCounter.Counter(type(uint128).max);

        // Assert
        vm.expectRevert(ERC1155NftCounter.MaxNFTCapacityReached.selector);

        // Act
        counter.increment();
    }

    function testIncrementUpdatesTheInnerValue(uint128 baseNumber) external {
        // Arrange
        vm.assume(baseNumber < type(uint128).max);

        counter = ERC1155NftCounter.Counter(baseNumber);
        uint128 expectedNumber = baseNumber + 1;

        // Act
        counter.increment();

        // Assert
        assertEq(counter.current(), expectedNumber);
    }
}
