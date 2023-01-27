// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

import "@contracts/interfaces/IReputation.sol";
import "@contracts/interfaces/IProperty.sol";
import "@contracts/libraries/Errors.sol";
import "@contracts/libraries/Constants.sol";

contract Reputation is IReputation, Ownable {
    IProperty propertyInstance;

    struct ScoreCounter {
        uint256 totalScore;
        uint256 voteCount;
    }

    mapping(address => ScoreCounter) private _userScores;
    mapping(address => ScoreCounter) private _userPaymentPerformanceScores;
    mapping(uint256 => ScoreCounter) private _propertyScores;

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

    modifier scoreInRange(uint256 score) {
        if (score < Constants.MIN_SCORE || score > Constants.MAX_SCORE) {
            revert Errors.ScoreValueOutOfRange(Constants.MIN_SCORE, Constants.MAX_SCORE);
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
        return _computeScore(_userScores[user]);
    }

    /**
     * @dev see {IReputation-getPropertyScore}.
     */
    function getPropertyScore(uint256 property) external view propertyExist(property) returns (uint256) {
        return _computeScore(_propertyScores[property]);
    }

    /**
     * @dev see {IReputation-getUserPaymentPerformanceScore}.
     */
    function getUserPaymentPerformanceScore(address user) external view not0Address(user) returns (uint256) {
        return _computeScore(_userPaymentPerformanceScores[user]);
    }

    /**
     * @dev Computes the average score.
     */
    function _computeScore(ScoreCounter memory scores) internal pure returns (uint256) {
        if (scores.voteCount == 0) {
            return Constants.MAX_SCORE * Constants.SCORE_MULTIPLIER;
        }

        return (scores.totalScore * Constants.SCORE_MULTIPLIER) / scores.voteCount;
    }

    /**
     * @dev see {IReputation-scoreProperty}.
     */
    function scoreProperty(uint256 property, uint256 score)
        external
        onlyOwner
        propertyExist(property)
        scoreInRange(score)
    {
        _propertyScores[property].totalScore += score;
        _propertyScores[property].voteCount += 1;

        emit PropertyScored(property, score);
    }

    /**
     * @dev see {IReputation-scoreUser}.
     */
    function scoreUser(address user, uint256 score) external onlyOwner not0Address(user) scoreInRange(score) {
        _userScores[user].totalScore += score;
        _userScores[user].voteCount += 1;

        emit UserScored(user, score);
    }

    /**
     * @dev see {IReputation-scoreUserPaymentPerformance}.
     */
    function scoreUserPaymentPerformance(address user, bool paidOnTime) external onlyOwner not0Address(user) {
        uint256 score = paidOnTime ? Constants.MAX_SCORE : Constants.MIN_SCORE;

        _userPaymentPerformanceScores[user].totalScore += score;
        _userPaymentPerformanceScores[user].voteCount += 1;

        emit UserPaymentPerformanceScored(user, score);
    }
}
