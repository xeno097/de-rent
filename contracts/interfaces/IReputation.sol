// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IReputation {
    /**
     * @dev Emitted when the `user` receives a new score after a rental agreement has been completed.
     */
    event UserScored(address indexed user, uint256 score);

    /**
     * @dev Emitted when the `property` receives a new score after a rental agreement has been completed.
     */
    event PropertyScored(uint256 indexed property, uint256 score);

    /**
     * @dev Emitted when the `user` payment performance score gets updated.
     */
    event UserPaymentPerformanceScored(address indexed user, uint256 score);

    /**
     * @dev Returns the number of decimals used to get the scores user representation.
     */
    function decimals() external view returns (uint256);

    /**
     * @dev Returns `user` score if exists.
     *
     * Requirements:
     * - `user` cannot be the 0 address.
     *
     */
    function getUserScore(address user) external view returns (uint256);

    /**
     * @dev Returns `property` score if exists.
     *
     * Requirements:
     * - `property` must exist.
     */
    function getPropertyScore(uint256 property) external view returns (uint256);

    /**
     * @dev Returns `user` payment score if exists.
     *
     * Requirements:
     * - `user` cannot be the 0 address.
     *
     */
    function getUserPaymentPerformanceScore(address user) external view returns (uint256);

    /**
     * @dev Adds `score` to `property` if the sender rented it and but not voted it.
     *
     * Requirements:
     * - `property` must exist.
     * - `score` must be a number between 1 and 5.
     *
     *  Emits a {PropertyScored} event.
     */
    function scoreProperty(uint256 property, uint256 score) external;

    /**
     * @dev Adds `score` to `user` if the sender had a rental aggreement with him/her but didn't cast a vote yet.
     *
     * Requirements:
     * - `user` cannot be the 0 address.
     * - `score` must be a number between 1 and 5.
     *
     *  Emits a {UserScored} event.
     */
    function scoreUser(address user, uint256 score) external;

    /**
     * @dev Updates `user` payment performance score.
     *
     * Requirements:
     * - `user` cannot be the 0 address.
     *
     *  Emits a {UserPaymentPerformanceScored} event.
     */
    function scoreUserPaymentPerformance(address user, bool paidOnTime) external;
}

interface IReputationReader {
    /**
     * @dev Returns the number of decimals used to get the scores user representation.
     */
    function decimals() external view returns (uint256);

    /**
     * @dev Returns `user` score if exists.
     *
     * Requirements:
     * - `user` cannot be the 0 address.
     *
     */
    function getUserScore(address user) external view returns (uint256);

    /**
     * @dev Returns `property` score if exists.
     *
     * Requirements:
     * - `property` must exist.
     */
    function getPropertyScore(uint256 property) external view returns (uint256);

    /**
     * @dev Returns `user` payment score if exists.
     *
     * Requirements:
     * - `user` cannot be the 0 address.
     *
     */
    function getUserPaymentPerformanceScore(address user) external view returns (uint256);
}
