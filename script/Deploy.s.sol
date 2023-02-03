// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import {DiamondCutFacet, IDiamondCut} from "@diamonds/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet, IDiamondLoupe} from "@diamonds/facets/DiamondLoupeFacet.sol";
import {OwnershipFacet, IERC173} from "@diamonds/facets/OwnershipFacet.sol";
import {DiamondInit} from "@diamonds/upgradeInitializers/DiamondInit.sol";
import {Diamond, DiamondArgs} from "@diamonds/Diamond.sol";
import {IDiamond} from "@diamonds/interfaces/IDiamond.sol";
import "@diamonds/interfaces/IERC165.sol";

import "@contracts/facets/CoreFacet.sol";
import "@contracts/facets/ERC1155Facet.sol";
import "@contracts/facets/ERC1155TokenReceiverFacet.sol";
import "@contracts/facets/ListingFacet.sol";
import "@contracts/facets/PropertyFacet.sol";
import "@contracts/facets/ReputationFacet.sol";

contract DeployDiamond is Script {
    function run() external {
        // Setup
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);
        
        vm.startBroadcast(deployerPrivateKey);

        // Start
        IDiamond.FacetCut[] memory diamondCut = new IDiamond.FacetCut[](9);

        // Core Facet
        {
            CoreFacet coreContractInstance = new CoreFacet();

            bytes4[] memory coreFacetSelectors = new bytes4[](9);

            coreFacetSelectors[0] = ICoreFacet.approveRentalRequest.selector;
            coreFacetSelectors[1] = ICoreFacet.rejectRentalRequest.selector;
            coreFacetSelectors[2] = ICoreFacet.requestRental.selector;
            coreFacetSelectors[3] = ICoreFacet.payRent.selector;
            coreFacetSelectors[4] = ICoreFacet.signalMissedPayment.selector;
            coreFacetSelectors[5] = ICoreFacet.reviewRental.selector;
            coreFacetSelectors[6] = ICoreFacet.completeRental.selector;
            coreFacetSelectors[7] = ICoreFacet.withdraw.selector;
            coreFacetSelectors[8] = ICoreFacet.balanceOf.selector;

            diamondCut[0] = IDiamond.FacetCut({
                facetAddress: address(coreContractInstance),
                action: IDiamond.FacetCutAction.Add,
                functionSelectors: coreFacetSelectors
            });
        }

        // ERC1155Facet
        {
            ERC1155Facet eRC1155ContractInstance = new ERC1155Facet();

            bytes4[] memory eRC1155FacetSelectors = new bytes4[](7);

            eRC1155FacetSelectors[0] = (IERC1155.safeTransferFrom.selector);
            eRC1155FacetSelectors[1] = (IERC1155.safeBatchTransferFrom.selector);
            eRC1155FacetSelectors[2] = (IERC1155.balanceOf.selector);
            eRC1155FacetSelectors[3] = (IERC1155.balanceOfBatch.selector);
            eRC1155FacetSelectors[4] = (IERC1155.setApprovalForAll.selector);
            eRC1155FacetSelectors[5] = (IERC1155.isApprovedForAll.selector);
            eRC1155FacetSelectors[6] = (ERC1155Metadata_URI.uri.selector);

            diamondCut[1] = IDiamond.FacetCut({
                facetAddress: address(eRC1155ContractInstance),
                action: IDiamond.FacetCutAction.Add,
                functionSelectors: eRC1155FacetSelectors
            });
        }

        // ERC1155TokenReceiverFacet
        {
            ERC1155TokenReceiverFacet eRC1155ReceiverContractInstance = new ERC1155TokenReceiverFacet();

            bytes4[] memory ERC1155TokenReceiverFacetSelectors = new bytes4[](2);

            ERC1155TokenReceiverFacetSelectors[0] = (IERC1155TokenReceiver.onERC1155Received.selector);
            ERC1155TokenReceiverFacetSelectors[1] = (IERC1155TokenReceiver.onERC1155BatchReceived.selector);

            diamondCut[2] = IDiamond.FacetCut({
                facetAddress: address(eRC1155ReceiverContractInstance),
                action: IDiamond.FacetCutAction.Add,
                functionSelectors: ERC1155TokenReceiverFacetSelectors
            });
        }

        // ListingFacet
        {
            ListingFacet listingContractInstance = new ListingFacet();

            bytes4[] memory listingFacetSelectors = new bytes4[](4);

            listingFacetSelectors[0] = (IListingFacet.getSelfProperties.selector);
            listingFacetSelectors[1] = (IListingFacet.getPublishedProperties.selector);
            listingFacetSelectors[2] = (IListingFacet.getProperties.selector);
            listingFacetSelectors[3] = (IListingFacet.getPropertyById.selector);

            diamondCut[3] = IDiamond.FacetCut({
                facetAddress: address(listingContractInstance),
                action: IDiamond.FacetCutAction.Add,
                functionSelectors: listingFacetSelectors
            });
        }

        // PropertyFacet
        {
            PropertyFacet propertyContractInstance = new PropertyFacet();

            bytes4[] memory PropertyFacetContractSelectors = new bytes4[](4);

            PropertyFacetContractSelectors[0] = IPropertyFacet.getTotalPropertyCount.selector;
            PropertyFacetContractSelectors[1] = IPropertyFacet.setPropertyVisibility.selector;
            PropertyFacetContractSelectors[2] = IPropertyFacet.createProperty.selector;
            PropertyFacetContractSelectors[3] = IPropertyFacet.updateProperty.selector;

            diamondCut[4] = IDiamond.FacetCut({
                facetAddress: address(propertyContractInstance),
                action: IDiamond.FacetCutAction.Add,
                functionSelectors: PropertyFacetContractSelectors
            });
        }

        // ReputationFacet
        {
            ReputationFacet reputationContractInstance = new ReputationFacet();

            bytes4[] memory ReputationFacetselectors = new bytes4[](4);

            ReputationFacetselectors[0] = (IReputationReader.decimals.selector);
            ReputationFacetselectors[1] = (IReputationReader.getUserScore.selector);
            ReputationFacetselectors[2] = (IReputationReader.getPropertyScore.selector);
            ReputationFacetselectors[3] = (IReputationReader.getUserPaymentPerformanceScore.selector);

            diamondCut[5] = IDiamond.FacetCut({
                facetAddress: address(reputationContractInstance),
                action: IDiamond.FacetCutAction.Add,
                functionSelectors: ReputationFacetselectors
            });
        }

        // DiamondCutFacet
        {
            DiamondCutFacet diamondCutContractInstance = new DiamondCutFacet();

            bytes4[] memory diamondCutFacetSelectors = new bytes4[](1);

            diamondCutFacetSelectors[0] = (IDiamondCut.diamondCut.selector);

            diamondCut[6] = IDiamond.FacetCut({
                facetAddress: address(diamondCutContractInstance),
                action: IDiamond.FacetCutAction.Add,
                functionSelectors: diamondCutFacetSelectors
            });
        }

        // DiamondLoupeFacet
        {
            DiamondLoupeFacet diamondLoupeContractInstance = new DiamondLoupeFacet();

            bytes4[] memory diamondLoupeFacetSelectors = new bytes4[](4);

            diamondLoupeFacetSelectors[0] = (IDiamondLoupe.facets.selector);
            diamondLoupeFacetSelectors[1] = (IDiamondLoupe.facetFunctionSelectors.selector);
            diamondLoupeFacetSelectors[2] = (IDiamondLoupe.facetAddress.selector);
            diamondLoupeFacetSelectors[3] = (IERC165.supportsInterface.selector);

            diamondCut[7] = IDiamond.FacetCut({
                facetAddress: address(diamondLoupeContractInstance),
                action: IDiamond.FacetCutAction.Add,
                functionSelectors: diamondLoupeFacetSelectors
            });
        }

        // OwnershipFacet
        {
            OwnershipFacet ownershipContractInstance = new OwnershipFacet();

            bytes4[] memory ownershipFacetSelectors = new bytes4[](2);

            ownershipFacetSelectors[0] = (IERC173.owner.selector);
            ownershipFacetSelectors[1] = (IERC173.transferOwnership.selector);

            diamondCut[8] = IDiamond.FacetCut({
                facetAddress: address(ownershipContractInstance),
                action: IDiamond.FacetCutAction.Add,
                functionSelectors: ownershipFacetSelectors
            });
        }

        // Deploy
        DiamondInit initer = new DiamondInit();

        DiamondArgs memory args = DiamondArgs({
            owner: address(deployerAddress),
            init: address(initer),
            initCalldata: abi.encodeWithSelector(DiamondInit.init.selector, abi.encode())
        });

        new Diamond(diamondCut, args);

        // Clean up
        vm.stopBroadcast();
    }
}
