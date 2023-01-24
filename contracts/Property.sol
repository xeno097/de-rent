// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

import "@contracts/interfaces/IERC4906.sol";
import "@contracts/interfaces/IProperty.sol";
import "@contracts/libraries/Errors.sol";

contract Property is IProperty, ERC721URIStorage, IERC4906, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenCounter;

    constructor(address _coreAddress) ERC721("DeRentProperties", "DRP") {
        _transferOwnership(_coreAddress);
    }

    /**
     * @dev see {IProperty-mint}.
     */
    function mint(address user, string memory uri) external onlyOwner {
        uint256 newTokenId = _tokenCounter.current();
        _tokenCounter.increment();

        _safeMint(user, newTokenId);
        _setTokenURI(newTokenId, uri);
    }

    /**
     * @dev see {IProperty-exists}.
     */
    function exists(uint256 property) public view returns (bool) {
        return _exists(property);
    }

    /**
     * @dev see {IProperty-updateMetadata}.
     */
    function updateMetadata(uint256 property, string memory uri) external onlyOwner {
        _setTokenURI(property, uri);

        emit MetadataUpdate(property);
    }

    // Overrides
    /// @dev see {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == bytes4(0x49064906) || super.supportsInterface(interfaceId);
    }
}
