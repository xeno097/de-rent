// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@contracts/libraries/AppStorage.sol";
import "@contracts/libraries/ERC1155NftCounter.sol";

contract Modifiers {
    using ERC1155NftCounter for ERC1155NftCounter.Counter;

    AppStorage internal s;

    modifier not0Address(address user) {
        if (user == address(0)) {
            revert Errors.InvalidAddress(user);
        }
        _;
    }

    // Properties
    modifier requirePropertyExists(uint256 property) {
        if (property >= s.tokenCounter.current()) {
            revert Errors.PropertyNotFound();
        }
        _;
    }

    modifier requirePropertyOwner(uint256 property) {
        if (s.owners[property] != msg.sender) {
            revert Errors.NotPropertyOwner();
        }
        _;
    }

    // Rentals
    modifier onlyPropertyTenant(uint256 property) {
        if (s.rentals[property].tenant != msg.sender) {
            revert Errors.NotPropertyTenant();
        }
        _;
    }

    modifier onlyPendingRentalRequest(uint256 request) {
        if (s.rentals[request].status != DataTypes.RentalStatus.Pending) {
            revert Errors.CannotApproveNotPendingRentalRequest();
        }
        _;
    }

    modifier requireApprovedRentalRequest(uint256 request) {
        if (s.rentals[request].status != DataTypes.RentalStatus.Approved) {
            revert Errors.RentalNotApproved();
        }
        _;
    }

    modifier requireRentalCompletionDateReached(uint256 request) {
        if (block.timestamp <= s.rentals[request].createdAt + Constants.CONTRACT_DURATION) {
            revert Errors.RentalCompletionDateNotReached();
        }
        _;
    }
}
