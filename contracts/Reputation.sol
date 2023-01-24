// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

import "@contracts/interfaces/IReputation.sol";
import "@contracts/interfaces/IProperty.sol";
import "@contracts/libraries/Errors.sol";

contract Reputation is IReputation, Ownable {
    IProperty propertyInstance;

    uint256 private constant DECIMALS = 9;
    uint256 private constant SCORE_MULTIPLIER = 10 ** DECIMALS;
    uint256 public constant MAX_SCORE = 5;
    uint256 public constant MIN_SCORE = 1;

    mapping(address => uint256[]) private _userScores;
    mapping(address => uint256[]) private _userPaymentPerformanceScores;
    mapping(uint256 => uint256[]) private _propertyScores;

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
        if (score < MIN_SCORE || score > MAX_SCORE) {
            revert Errors.ScoreValueOutOfRange(MIN_SCORE, MAX_SCORE);
        }
        _;
    }

    /**
     * @dev see {IReputation-decimals}.
     */
    function decimals() external pure returns (uint256) {
        return DECIMALS;
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
     * @dev Computes the average score.
     */
    function _computeScore(uint256[] memory scores) internal pure returns (uint256) {
        uint256 len = scores.length;

        if (len == 0) {
            return MAX_SCORE * SCORE_MULTIPLIER;
        }

        uint256 total = 0;
        for (uint256 i = 0; i < len; i++) {
            total += scores[i];
        }

        return (total * SCORE_MULTIPLIER) / len;
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
        _propertyScores[property].push(score);

        emit PropertyScored(property, score);
    }

    /**
     * @dev see {IReputation-scoreUser}.
     */
    function scoreUser(address user, uint256 score) external onlyOwner not0Address(user) scoreInRange(score) {
        _userScores[user].push(score);

        emit UserScored(user, score);
    }

    /**
     * @dev see {IReputation-scoreUserPaymentPerformance}.
     */
    function scoreUserPaymentPerformance(address user, bool paidOnTime) external onlyOwner not0Address(user) {

    }
}
