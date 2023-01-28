// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "@contracts/interfaces/IProperty.sol";

abstract contract BaseTest is Test {
    address constant mockAddress = address(97);
    string constant ozOwnableContractError = "Ownable: caller is not the owner";

    function _setUpExistsMockCall(uint256 property, bool returnValue) internal {
        vm.mockCall(mockAddress, abi.encodeWithSelector(IProperty.exists.selector, property), abi.encode(returnValue));
    }

    function _createUserScore(address target, address user, uint256 totalCount, uint256 voteCount) internal {
        bytes32 sslot = keccak256(abi.encode(uint256(uint160(user)), uint256(3)));

        _storeScore(target, sslot, totalCount, voteCount);
    }

    function _createPropertyScore(address target, uint256 property, uint256 totalCount, uint256 voteCount) internal {
        bytes32 sslot = keccak256(abi.encode(property, uint256(5)));

        _storeScore(target, sslot, totalCount, voteCount);
    }

    function _createUserPaymentPerformanceScore(address target, address user, uint256 totalCount, uint256 voteCount)
        internal
    {
        bytes32 sslot = keccak256(abi.encode(uint256(uint160(user)), uint256(4)));

        _storeScore(target, sslot, totalCount, voteCount);
    }

    function _storeScore(address target, bytes32 sslot, uint256 totalCount, uint256 voteCount) internal {
        vm.store(address(target), bytes32(uint256(sslot)), bytes32(totalCount));
        vm.store(address(target), bytes32(uint256(sslot) + 1), bytes32(uint256(voteCount)));
    }
}
