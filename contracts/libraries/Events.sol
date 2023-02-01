// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library Events {
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
     * @dev Emitted when `request` gets approved.
     */
    event RentalRequestApproved(uint256 indexed request);

    /**
     * @dev Emitted when `request` gets rejected.
     */
    event RentalRequestRejected(uint256 indexed request);

    /**
     * @dev Emitted when `request` gets created.
     */
    event RentalRequested(uint256 indexed request);
}
