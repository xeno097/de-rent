// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@contracts/libraries/DataTypes.sol";
import "@contracts/libraries/ScoreCounters.sol";
import "@contracts/libraries/ERC1155NftCounter.sol";
import "@contracts/interfaces/IProperty.sol";

struct AppStorage {
    // Core
    mapping(uint256 => DataTypes.Property) properties;
    mapping(uint256 => DataTypes.Rental) rentals;
    // Reputation
    mapping(address => ScoreCounters.ScoreCounter) userScores;
    mapping(address => ScoreCounters.ScoreCounter) userPaymentPerformanceScores;
    mapping(uint256 => ScoreCounters.ScoreCounter) propertyScores;
    // ERC1155
    mapping(uint256 => mapping(address => uint256)) tokenBalances;
    mapping(address => mapping(address => bool)) approvals;
    // ERC1155URIStorage
    string baseUri;
    mapping(uint256 => string) tokenUris;
    ERC1155NftCounter.Counter tokenCounter;
    mapping(uint256 => address) owners;
}
