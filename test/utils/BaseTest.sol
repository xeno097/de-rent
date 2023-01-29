// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";

import "@contracts/interfaces/IProperty.sol";
import "@contracts/libraries/DataTypes.sol";
import "@contracts/libraries/ScoreCounters.sol";

abstract contract BaseTest is Test {
    address constant mockAddress = address(97);
    string constant ozOwnableContractError = "Ownable: caller is not the owner";

    // Mocks
    function _setUpExistsMockCall(uint256 property, bool returnValue) internal {
        vm.mockCall(mockAddress, abi.encodeWithSelector(IProperty.exists.selector, property), abi.encode(returnValue));
    }

    function _setUpMintMockCall() internal {
        vm.mockCall(mockAddress, abi.encodeWithSelector(IProperty.mint.selector), abi.encode(0));
    }

    function _setUpOwnerOfMockCall(address returnData) internal {
        vm.mockCall(mockAddress, abi.encodeWithSelector(IERC721.ownerOf.selector), abi.encode(returnData));
    }

    // Storage
    function _writeToStorage(address target, bytes32 sslot, bytes32 value, uint256 offset) internal {
        bytes32 storageSlot = bytes32(uint256(sslot) + offset);
        vm.store(target, storageSlot, value);
    }

    function _writeToStorage(address target, bytes32 sslot, bytes32 value) internal {
        _writeToStorage(target, sslot, value, 0);
    }

    function _createUserScore(address target, address user, uint256 totalCount, uint256 voteCount) internal {
        bytes32 sslot = keccak256(abi.encode(uint256(uint160(user)), uint256(3)));

        _storeScore(target, sslot, totalCount, voteCount);
    }

    function _createUserPaymentPerfomanceScore(address target, address user, uint256 totalCount, uint256 voteCount)
        internal
    {
        bytes32 sslot = keccak256(abi.encode(uint256(uint160(user)), uint256(4)));

        _storeScore(target, sslot, totalCount, voteCount);
    }

    function _readUserScore(address target, address user) internal view returns (ScoreCounters.ScoreCounter memory) {
        bytes32 sslot = keccak256(abi.encode(uint256(uint160(user)), uint256(3)));

        return ScoreCounters.ScoreCounter({
            _totalScore: uint256(vm.load(target, sslot)),
            _voteCount: uint256(vm.load(target, bytes32(uint256(sslot) + 1)))
        });
    }

    function _readPropertyScore(address target, uint256 property)
        internal
        view
        returns (ScoreCounters.ScoreCounter memory)
    {
        bytes32 sslot = keccak256(abi.encode(property, uint256(5)));

        return ScoreCounters.ScoreCounter({
            _totalScore: uint256(vm.load(target, sslot)),
            _voteCount: uint256(vm.load(target, bytes32(uint256(sslot) + 1)))
        });
    }

    function _readUserPaymentPerfomanceScore(address target, address user)
        internal
        view
        returns (ScoreCounters.ScoreCounter memory)
    {
        bytes32 sslot = keccak256(abi.encode(uint256(uint160(user)), uint256(4)));

        return ScoreCounters.ScoreCounter({
            _totalScore: uint256(vm.load(target, sslot)),
            _voteCount: uint256(vm.load(target, bytes32(uint256(sslot) + 1)))
        });
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
        _writeToStorage(target, sslot, bytes32(totalCount));
        _writeToStorage(target, sslot, bytes32(voteCount), 1);
    }

    function _createProperty(address target, uint256 id, DataTypes.Property memory property) internal {
        bytes32 sslot = keccak256(abi.encode(id, uint256(0)));

        _storeProperty(target, sslot, property);
    }

    function _storeProperty(address target, bytes32 sslot, DataTypes.Property memory property) internal {
        _writeToStorage(target, sslot, bytes32(property.rentPrice));
        _writeToStorage(target, sslot, bytes32(uint256(property.published ? 1 : 0)), 1);
    }

    function _createRental(address target, uint256 id, DataTypes.Rental memory rental) internal {
        bytes32 sslot = keccak256(abi.encode(id, uint256(1)));

        _storeRental(target, sslot, rental);
    }

    function _storeRental(address target, bytes32 sslot, DataTypes.Rental memory rental) internal {
        _writeToStorage(target, sslot, bytes32(rental.rentPrice));
        _writeToStorage(target, sslot, bytes32(uint256(uint160(rental.tenant))), 1);
        _writeToStorage(target, sslot, bytes32(rental.availableDeposits), 2);
        _writeToStorage(target, sslot, bytes32(rental.paymentDate), 3);
        _writeToStorage(target, sslot, bytes32(uint256(rental.status)), 4);
        _writeToStorage(target, sslot, bytes32(rental.createdAt), 5);
    }

    function _createUserBalance(address target, address user, uint256 balance) internal {
        bytes32 sslot = keccak256(abi.encode(user, uint256(2)));

        _writeToStorage(target, sslot, bytes32(balance));
    }

    function _readUserBalance(address target, address user) internal view returns (uint256) {
        bytes32 sslot = keccak256(abi.encode(user, uint256(2)));

        return uint256(vm.load(target, sslot));
    }
}
