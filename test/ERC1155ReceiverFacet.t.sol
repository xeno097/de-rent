// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/BaseTest.sol";

import {IDiamond} from "@diamonds/interfaces/IDiamond.sol";
import {Diamond, DiamondArgs} from "@diamonds/Diamond.sol";
import {DiamondInit} from "@diamonds/upgradeInitializers/DiamondInit.sol";

import "@contracts/facets/ERC1155TokenReceiverFacet.sol";

contract ListingTest is BaseTest {
    ERC1155TokenReceiverFacet listingContract;

    function setUp() public {
        ERC1155TokenReceiverFacet coreContractInstance = new ERC1155TokenReceiverFacet();
        DiamondInit initer = new DiamondInit();

        bytes4[] memory selectors = new bytes4[](2);

        selectors[0] = (IERC1155TokenReceiver.onERC1155Received.selector);
        selectors[1] = (IERC1155TokenReceiver.onERC1155BatchReceived.selector);

        IDiamond.FacetCut[] memory diamondCut = new IDiamond.FacetCut[](1);

        diamondCut[0] = IDiamond.FacetCut({
            facetAddress: address(coreContractInstance),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: selectors
        });

        DiamondArgs memory args = DiamondArgs({
            owner: address(this),
            init: address(initer),
            initCalldata: abi.encodeWithSelector(DiamondInit.init.selector, abi.encode())
        });

        Diamond diamondProxy = new Diamond(diamondCut, args);
        listingContract = ERC1155TokenReceiverFacet(address(diamondProxy));
    }
    // onERC1155Received()
    function testOnERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data)
        external
    {
        // Act
        bytes4 res = listingContract.onERC1155Received(operator, from, id, value, data);

        // Assert
        assertEq(uint32(res), uint32(0xf23a6e61));
    }

    // onERC1155BatchReceived()
    function testGetPropertyById(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external {
        // Act
        bytes4 res = listingContract.onERC1155BatchReceived(operator, from, ids, values, data);

        // Assert
        assertEq(uint32(res), uint32(0xbc197c81));
    }
}
