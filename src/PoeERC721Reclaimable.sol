// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {ERC721Reclaimable} from "./ERC721Reclaimable.sol";

contract PoeERC721Reclaimable is ERC721Reclaimable {
    uint256 public immutable maxSupply;
    uint256 public mintFee;

    mapping(address => bool) public whitelisted;
    mapping(address => bool) didMint;

    string private __baseUri;

    constructor(
        address[] memory _whitelist,
        uint256 _mintFee,
        uint256 _maxSupply,
        string memory ___baseUri
    ) 
        ERC721Reclaimable(
            "Poe Token",
            "PNFT",
            0.0003 ether,
            0xAe42B13CF992FeB85eEEf0c8B91FDDbFe721C02c
        ) 
    {
        for (uint i = 0; i < _whitelist.length; ++i) {
            whitelisted[_whitelist[i]] = true;
        }
        mintFee = _mintFee;
        maxSupply = _maxSupply;
        __baseUri = ___baseUri;
    }

    function mint(uint256 tokenId) public payable {
        require(tokenId < maxSupply, InvalidTokenId(tokenId));
        
        bool alreadyMinted = didMint[msg.sender];
        // If you are on the whitelist and it's your first mint then you're exempt from the fee
        require((whitelisted[msg.sender] && !alreadyMinted) || msg.value >= mintFee, InsufficientMintFee());

        didMint[msg.sender] = true;

        mint(msg.sender, tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return __baseUri;
    }

    error InsufficientMintFee();
    error InvalidTokenId(uint256 tokenId);
}
