// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

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
