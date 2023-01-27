// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library DataTypes {
    enum RentalStatus {
        Free,
        Pending,
        Approved,
        Completed
    }

    struct Property {
        uint256 rentPrice;
        bool published;
    }

    struct Rental {
        uint256 rentPrice;
        address tenant;
        uint256 availableDeposits;
        uint256 paymentDate;
        RentalStatus status;
        uint256 createdAt;
    }

    struct ListingProperty {
        uint256 id;
        uint256 rentPrice;
        address owner;
        bool published;
        string uri;
        RentalStatus status;
    }
}
