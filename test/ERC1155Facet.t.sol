// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/BaseTest.sol";

import {IDiamond} from "@diamonds/interfaces/IDiamond.sol";
import {Diamond, DiamondArgs} from "@diamonds/Diamond.sol";
import {DiamondInit} from "@diamonds/upgradeInitializers/DiamondInit.sol";

import "@contracts/facets/ERC1155Facet.sol";

contract ERC1155FacetTest is BaseTest {
    ERC1155Facet erc1155Contract;

    function setUp() public {
        ERC1155Facet coreContractInstance = new ERC1155Facet();
        DiamondInit initer = new DiamondInit();

        bytes4[] memory selectors = new bytes4[](7);

        selectors[0] = (IERC1155.safeTransferFrom.selector);
        selectors[1] = (IERC1155.safeBatchTransferFrom.selector);
        selectors[2] = (IERC1155.balanceOf.selector);
        selectors[3] = (IERC1155.balanceOfBatch.selector);
        selectors[4] = (IERC1155.setApprovalForAll.selector);
        selectors[5] = (IERC1155.isApprovedForAll.selector);
        selectors[6] = (ERC1155Metadata_URI.uri.selector);

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
        erc1155Contract = ERC1155Facet(address(diamondProxy));
    }

    // safeTransferFrom()
    function testCannotCallSafeTransferFrom(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external {
        // Assert
        vm.expectRevert(Errors.ForbiddenOperation.selector);

        // Act
        erc1155Contract.safeTransferFrom(operator, from, id, value, data);
    }

    // safeBatchTransferFrom()
    function testCannotCallSafeBatchTransferFrom(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external {
        // Assert
        vm.expectRevert(Errors.ForbiddenOperation.selector);

        // Act
        erc1155Contract.safeBatchTransferFrom(operator, from, ids, values, data);
    }

    // balanceOf()
    function testBalanceOf(address owner, uint256 id, uint256 expectedBalance) external {
        // Arrange
        vm.assume(owner != address(0));

        _createTokenBalance(address(erc1155Contract), id, owner, expectedBalance);

        // Act
        uint256 res = erc1155Contract.balanceOf(owner, id);

        // Assert
        assertEq(res, expectedBalance);
    }

    // balanceOfBatch()
    function testBalanceOfBatch(uint256[5] calldata _ids, uint256[5] calldata _balances) external {
        // Arrange
        uint256 len = 5;
        address[] memory owners = new address[](len);

        owners[0] = address(53);
        owners[1] = address(97);
        owners[2] = address(123);
        owners[3] = address(173);
        owners[4] = address(151);

        uint256[] memory ids = new uint256[](len);
        uint256[] memory balances = new uint256[](len);

        for (uint256 i = 0; i < len; i++) {
            ids[i] = _ids[i];
            balances[i] = _balances[i];
            _createTokenBalance(address(erc1155Contract), ids[i], owners[i], balances[i]);
        }

        // Act
        uint256[] memory res = erc1155Contract.balanceOfBatch(owners, ids);

        // Assert
        for (uint256 i = 0; i < len; i++) {
            assertEq(res[i], balances[i]);
        }
    }

    // setApprovalForAll()
    function testCannotCallSetApprovalForAll(address owner, bool approved) external {
        // Assert
        vm.expectRevert(Errors.ForbiddenOperation.selector);

        // Act
        erc1155Contract.setApprovalForAll(owner, approved);
    }

    // isApprovedForAll()
    function testIsApprovedForAll(address owner, address operator) external {
        // Act
        bool res = erc1155Contract.isApprovedForAll(owner, operator);

        // Assert
        assertFalse(res);
    }
}
