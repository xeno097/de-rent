// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

import "@contracts/interfaces/IReputation.sol";
import "@contracts/interfaces/IProperty.sol";
import "@contracts/libraries/Errors.sol";
import "@contracts/libraries/Constants.sol";
import "@contracts/libraries/ScoreCounters.sol";

contract Reputation is IReputation, Ownable {
    using ScoreCounters for ScoreCounters.ScoreCounter;

    IProperty propertyInstance;

    mapping(address => ScoreCounters.ScoreCounter) private _userScores;
    mapping(address => ScoreCounters.ScoreCounter) private _userPaymentPerformanceScores;
    mapping(uint256 => ScoreCounters.ScoreCounter) private _propertyScores;

    constructor(address _coreAddress, address _propertyInstanceAddress) {
        _transferOwnership(_coreAddress);
        propertyInstance = IProperty(_propertyInstanceAddress);
    }

    modifier propertyExist(uint256 property) {
        if (!propertyInstance.exists(property)) {
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
     * @dev see {IReputation-decimals}.
     */
    function decimals() external pure returns (uint256) {
        return Constants.DECIMALS;
    }

    /**
     * @dev see {IReputation-getUserScore}.
     */
    function getUserScore(address user) external view not0Address(user) returns (uint256) {
        return _userScores[user].current();
    }

    /**
     * @dev see {IReputation-getPropertyScore}.
     */
    function getPropertyScore(uint256 property) external view propertyExist(property) returns (uint256) {
        return _propertyScores[property].current();
    }

    /**
     * @dev see {IReputation-getUserPaymentPerformanceScore}.
     */
    function getUserPaymentPerformanceScore(address user) external view not0Address(user) returns (uint256) {
        return _userPaymentPerformanceScores[user].current();
    }

    /**
     * @dev see {IReputation-scoreProperty}.
     */
    function scoreProperty(uint256 property, uint256 score) external onlyOwner propertyExist(property) {
        _propertyScores[property].add(score);

        emit PropertyScored(property, score);
    }

    /**
     * @dev see {IReputation-scoreUser}.
     */
    function scoreUser(address user, uint256 score) external onlyOwner not0Address(user) {
        _userScores[user].add(score);

        emit UserScored(user, score);
    }

    /**
     * @dev see {IReputation-scoreUserPaymentPerformance}.
     */
    function scoreUserPaymentPerformance(address user, bool paidOnTime) external onlyOwner not0Address(user) {
        uint256 score = paidOnTime ? Constants.MAX_SCORE : Constants.MIN_SCORE;

        _userPaymentPerformanceScores[user].add(score);

        emit UserPaymentPerformanceScored(user, score);
    }
}
