// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {IERC721Reclaimable} from "./interfaces/IERC721Reclaimable.sol";

contract ERC721Reclaimable is IERC721Reclaimable, ERC721Enumerable {
    mapping(uint256 tokenId => address titleOwner) private _titleOwners;
    mapping(address titleOwner => mapping(uint256 index => uint256 tokenId)) _ownedTitles;
    mapping(uint256 tokenId => uint256 index) _ownedTitlesIndex;
    mapping(address titleOwner => uint256 titleBalance) private _titleBalances;
    mapping(uint256 tokenId => address operator) private _tokenTitleApprovals;
    mapping(address titleOwner => mapping(address titleOperator => bool canOperate)) private _titleOperatorApprovals;
    uint256 private immutable _titleTransferFee;
    address private immutable _titleFeeRecipient;

    constructor(
        string memory name,
        string memory symbol,
        uint256 __titleTransferFee,
        address __titleFeeRecipient
    ) ERC721(name, symbol) {
        _titleTransferFee = __titleTransferFee;
        _titleFeeRecipient = __titleFeeRecipient;
    }

    /// @inheritdoc IERC721Reclaimable
    function titleTransferFee() external override view returns (uint256) {
        return _titleTransferFee;
    }

    /// @inheritdoc IERC721Reclaimable
    function titleTransferFeeRecipient() external override view returns (address) {
        return _titleFeeRecipient;
    }

    /// @inheritdoc IERC721Reclaimable
    function claimOwnership(uint256 _tokenId)
        public
        payable
        override
        onlyTitleOwnerOrOperatorOrApproved(_tokenId)
    {
        address titleOwner = _titleOwners[_tokenId];
        address assetOwner = this.ownerOf(_tokenId);
        _transfer(assetOwner, titleOwner, _tokenId);
        emit OwnershipClaim(titleOwner, assetOwner, _tokenId);
    }

    /// @inheritdoc IERC721Reclaimable
    function titleTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public override payable onlyTitleOwnerOrOperatorOrApproved(_tokenId) {
        require(_titleOwners[_tokenId] == _from, NotTitleOwner(_from));
        require(msg.value >= _titleTransferFee, InsufficientTitleTransferFee(_from, _to, _tokenId, msg.value));

        _titleOwners[_tokenId] = _to;
        _titleBalances[_to] += 1;
        _titleBalances[_from] -= 1;

        // Clear approval
        delete _tokenTitleApprovals[_tokenId];

        // Remove title from sender's enumeration
        _removeTokenFromTitleOwnerEnumeration(_from, _tokenId);
        _addTokenToTitleOwnerEnumeration(_to, _tokenId);

        // Transfer the title transfer fee to the receiver
        (bool success, ) = _titleFeeRecipient.call{value: msg.value}("");
        require(success, "Transfer failed");

        emit TitleTransfer(_from, _to, _tokenId);
    }

    /// @inheritdoc IERC721Reclaimable
    function titleOwnerOf(uint256 _tokenId) public view override returns (address) {
        return _titleOwners[_tokenId];
    }

    /// @inheritdoc IERC721Reclaimable
    function titleApprove(address _to, uint256 _tokenId) public payable override {
        _tokenTitleApprovals[_tokenId] = _to;
        emit TitleApproval(msg.sender, _to, _tokenId);
    }

    /// @inheritdoc IERC721Reclaimable
    function getTitleApproved(uint256 _tokenId) public view override returns (address) {
        return _tokenTitleApprovals[_tokenId];
    }

    /// @inheritdoc IERC721Reclaimable
    function setTitleApprovalForAll(address _operator, bool _approved) public override {
        _titleOperatorApprovals[msg.sender][_operator] = _approved;
        emit TitleApprovalForAll(msg.sender, _operator, _approved);
    }

    /// @inheritdoc IERC721Reclaimable
    function isTitleApprovedForAll(address _titleOwner, address _titleOperator) public view override returns (bool) {
        return _titleOperatorApprovals[_titleOwner][_titleOperator];
    }

    /// @inheritdoc IERC721Reclaimable
    function titleBalanceOf(address _titleOwner) public view override returns (uint256) {
        return _titleBalances[_titleOwner];
    }

    function mint(address to, uint256 tokenId) internal {
        _mint(to, tokenId);
        _titleMint(to, tokenId);
    }

    function tokenOfTitleOwnerByIndex(address titleOwner, uint256 index) public view returns (uint256) {
        if (index >= titleBalanceOf(titleOwner)) {
            revert ERC721OutOfBoundsIndex(titleOwner, index);
        }
        return _ownedTitles[titleOwner][index];
    }

    function _titleMint(address _to, uint256 _tokenId) internal {
        require(_to != address(0), "Cannot mint to 0 address");
        require(_titleOwners[_tokenId] == address(0), "Title already minted");
        _titleOwners[_tokenId] = _to;
        _titleBalances[_to] += 1;
        _addTokenToTitleOwnerEnumeration(_to, _tokenId);
        emit TitleTransfer(address(0), _to, _tokenId);
    }

    function _addTokenToTitleOwnerEnumeration(address titleOwner, uint256 token) private {
        uint256 index = titleBalanceOf(titleOwner) - 1;
        _ownedTitles[titleOwner][index] = token;
        _ownedTitlesIndex[token] = index;
    }

    function _removeTokenFromTitleOwnerEnumeration(address titleOwner, uint256 token) private {
        uint256 indexOfTokenToRemove = _ownedTitlesIndex[token];
        // no need for - 1 because by the time this is called the decrement in balance has already happeend
        uint256 lastIndex = titleBalanceOf(titleOwner); 

        if (indexOfTokenToRemove != lastIndex) {
            uint256 tokenAtLastIndex = _ownedTitles[titleOwner][lastIndex];
            _ownedTitles[titleOwner][indexOfTokenToRemove] = tokenAtLastIndex;
            _ownedTitlesIndex[tokenAtLastIndex] = indexOfTokenToRemove;
        }

        delete _ownedTitles[titleOwner][lastIndex];
        delete _ownedTitlesIndex[token];
    }

    modifier onlyTitleOwnerOrOperator(uint256 tokenId) {
        address titleOwner = _titleOwners[tokenId];
        bool isTitleOwner = titleOwner == msg.sender;
        bool isApprovedForAll = this.isTitleApprovedForAll(titleOwner, msg.sender);
        require(isTitleOwner || isApprovedForAll, InvalidTitleApprover(msg.sender));
        _;
    }

    modifier onlyTitleOwnerOrOperatorOrApproved(uint256 tokenId) {
        address titleOwner = _titleOwners[tokenId];
        bool isTitleOwner = titleOwner == msg.sender;
        bool isApproved = this.getTitleApproved(tokenId) == msg.sender;
        bool isApprovedForAll = this.isTitleApprovedForAll(titleOwner, msg.sender);
        require(
            isApproved || isTitleOwner || isApprovedForAll,
            NotTitleOwnerOrApprovedOrOperator(tokenId, msg.sender)
        );
        _;
    }

    error NotTitleOwner(address _address);
    error NotTitleOwnerOrApprovedOrOperator(uint256 _tokenId, address _address);
    error InvalidTitleApprover(address _address);
    error TitleTransferFromInvalidTitleOwner(address _from, address _to, uint256 _tokenId);
    error InsufficientTitleTransferFee(address _from, address _to, uint256 _tokenId, uint256 _amount);
}
