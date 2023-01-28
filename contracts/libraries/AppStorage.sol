// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@contracts/libraries/DataTypes.sol";
import "@contracts/libraries/ScoreCounters.sol";
import "@contracts/interfaces/IProperty.sol";

struct AppStorage {
    // Core
    mapping(uint256 => DataTypes.Property) properties;
    mapping(uint256 => DataTypes.Rental) rentals;
    mapping(address => uint256) balances;
    // Reputation
    mapping(address => ScoreCounters.ScoreCounter) userScores;
    mapping(address => ScoreCounters.ScoreCounter) userPaymentPerformanceScores;
    mapping(uint256 => ScoreCounters.ScoreCounter) propertyScores;
    // TODO: remove this after complete porting
    IProperty propertyInstance;
}
