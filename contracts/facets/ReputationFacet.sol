// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

import "@contracts/interfaces/IReputation.sol";
import "@contracts/interfaces/IProperty.sol";
import "@contracts/libraries/Errors.sol";
import "@contracts/libraries/Constants.sol";
import "@contracts/libraries/ScoreCounters.sol";
import "@contracts/libraries/AppStorage.sol";

contract ReputationFacet is IReputationReader {
    using ScoreCounters for ScoreCounters.ScoreCounter;

    AppStorage internal s;

    modifier propertyExist(uint256 property) {
        if (!s.propertyInstance.exists(property)) {
            revert Errors.PropertyNotFound();
        }
        _;
    }

    modifier not0Address(address user) {
        if (user == address(0)) {
            revert Errors.InvalidAddress(user);
        }
        _;
    }

    /**
     * @dev see {IReputationReader-decimals}.
     */
    function decimals() external pure returns (uint256) {
        return Constants.DECIMALS;
    }

    /**
     * @dev see {IReputationReader-getUserScore}.
     */
    function getUserScore(address user) external view not0Address(user) returns (uint256) {
        return s.userScores[user].current();
    }

    /**
     * @dev see {IReputationReader-getPropertyScore}.
     */
    function getPropertyScore(uint256 property) external view propertyExist(property) returns (uint256) {
        return s.propertyScores[property].current();
    }

    /**
     * @dev see {IReputationReader-getUserPaymentPerformanceScore}.
     */
    function getUserPaymentPerformanceScore(address user) external view not0Address(user) returns (uint256) {
        return s.userPaymentPerformanceScores[user].current();
    }
}
