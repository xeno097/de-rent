// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";

import "@contracts/interfaces/IProperty.sol";
import "@contracts/libraries/DataTypes.sol";
import "@contracts/libraries/ScoreCounters.sol";

abstract contract BaseTest is Test {
    address constant mockAddress = address(97);
    address constant alternativeMockAddress = address(53);
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

    function _setUpTokenUriMockCall(uint256 property, string memory returnValue) internal {
        vm.mockCall(
            mockAddress, abi.encodeWithSelector(IERC721Metadata.tokenURI.selector, property), abi.encode(returnValue)
        );
    }

    function _setUpOwnerOfMockCall(uint256 property, address returnData) internal {
        vm.mockCall(mockAddress, abi.encodeWithSelector(IERC721.ownerOf.selector, property), abi.encode(returnData));
    }

    function _setUpGetTotalPropertyCountMockCall(uint256 returnValue) internal {
        vm.mockCall(
            mockAddress, abi.encodeWithSelector(IProperty.getTotalPropertyCount.selector), abi.encode(returnValue)
        );
    }

    // Storage
    function _writeToStorage(address target, bytes32 sslot, bytes32 value, uint256 offset) internal {
        bytes32 storageSlot = bytes32(uint256(sslot) + offset);
        vm.store(target, storageSlot, value);
    }

    function _writeToStorage(address target, bytes32 sslot, bytes32 value) internal {
        _writeToStorage(target, sslot, value, 0);
    }

    function _readFromStorage(address target, bytes32 sslot, uint256 offset) internal view returns (bytes32) {
        return vm.load(target, bytes32(uint256(sslot) + offset));
    }

    function _readFromStorage(address target, bytes32 sslot) internal view returns (bytes32) {
        return _readFromStorage(target, sslot, 0);
    }

    function _getUserScoreStorageSlot(address user) internal pure returns (bytes32) {
        return keccak256(abi.encode(uint256(uint160(user)), uint256(3)));
    }

    function _createUserScore(address target, address user, uint256 totalCount, uint256 voteCount) internal {
        bytes32 sslot = _getUserScoreStorageSlot(user);

        _storeScore(target, sslot, totalCount, voteCount);
    }

    function _readUserScore(address target, address user) internal view returns (ScoreCounters.ScoreCounter memory) {
        bytes32 sslot = _getUserScoreStorageSlot(user);

        return ScoreCounters.ScoreCounter({
            _totalScore: uint256(_readFromStorage(target, sslot)),
            _voteCount: uint256(_readFromStorage(target, sslot, 1))
        });
    }

    function _getUserPaymentPerformanceScoreStorageSlot(address user) internal pure returns (bytes32) {
        return keccak256(abi.encode(uint256(uint160(user)), uint256(4)));
    }

    function _createUserPaymentPerformanceScore(address target, address user, uint256 totalCount, uint256 voteCount)
        internal
    {
        bytes32 sslot = _getUserPaymentPerformanceScoreStorageSlot(user);

        _storeScore(target, sslot, totalCount, voteCount);
    }

    function _readUserPaymentPerformanceScore(address target, address user)
        internal
        view
        returns (ScoreCounters.ScoreCounter memory)
    {
        bytes32 sslot = _getUserPaymentPerformanceScoreStorageSlot(user);

        return ScoreCounters.ScoreCounter({
            _totalScore: uint256(_readFromStorage(target, sslot)),
            _voteCount: uint256(_readFromStorage(target, sslot, 1))
        });
    }

    function _getPropertyScoreStorageSlot(uint256 property) internal pure returns (bytes32) {
        return keccak256(abi.encode(property, uint256(5)));
    }

    function _createPropertyScore(address target, uint256 property, uint256 totalCount, uint256 voteCount) internal {
        bytes32 sslot = _getPropertyScoreStorageSlot(property);

        _storeScore(target, sslot, totalCount, voteCount);
    }

    function _readPropertyScore(address target, uint256 property)
        internal
        view
        returns (ScoreCounters.ScoreCounter memory)
    {
        bytes32 sslot = _getPropertyScoreStorageSlot(property);

        return ScoreCounters.ScoreCounter({
            _totalScore: uint256(_readFromStorage(target, sslot)),
            _voteCount: uint256(_readFromStorage(target, sslot, 1))
        });
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

    function _getUserBalanceStorageSlot(address user) internal pure returns (bytes32) {
        return keccak256(abi.encode(user, uint256(2)));
    }

    function _createUserBalance(address target, address user, uint256 balance) internal {
        bytes32 sslot = _getUserBalanceStorageSlot(user);

        _writeToStorage(target, sslot, bytes32(balance));
    }

    function _readUserBalance(address target, address user) internal view returns (uint256) {
        bytes32 sslot = _getUserBalanceStorageSlot(user);

        return uint256(vm.load(target, sslot));
    }
}
