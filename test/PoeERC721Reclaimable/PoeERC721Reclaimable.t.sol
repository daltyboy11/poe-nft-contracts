// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";

import {PoeERC721Reclaimable} from "../../src/PoeERC721Reclaimable.sol";

contract PoeERC721ReclaimableTest is Test {

    PoeERC721Reclaimable public poeNft;

    address public whitelistAddress = 0xAe42B13CF992FeB85eEEf0c8B91FDDbFe721C02c;
    uint256 mintFee = 0.01 ether;
    uint256 maxSupply = 5;

    function setUp() public {
        address[] memory whitelist = new address[](1);
        whitelist[0] = whitelistAddress;
        poeNft = new PoeERC721Reclaimable({
            _whitelist: whitelist,
            _mintFee: mintFee,
            _maxSupply: maxSupply,
            ___baseUri: "https://daltyboy11.github.io/poe-nft"
        });
    }

    function test_whitelistedAddressFirstMint_doesntPayMintFee() public {
        vm.prank(whitelistAddress);
        poeNft.mint(0);
        assertEq(poeNft.ownerOf(0), whitelistAddress);
    }

    function test_whitelistedAddressSecondMint_mustPayMintFee() public {
        vm.startPrank(whitelistAddress)        ;
        poeNft.mint(0);
        assertEq(poeNft.ownerOf(0), whitelistAddress);
        vm.expectRevert(
            abi.encodeWithSelector(PoeERC721Reclaimable.InsufficientMintFee.selector)
        );
        poeNft.mint(1);
    }

    function test_nonWhitelistedAddress_mustPayMintFee(
        uint256 insufficientMintFee,
        uint256 sufficientMintFee
    ) public {
        insufficientMintFee = bound(insufficientMintFee, 0, poeNft.mintFee() - 1);

        address minter = address(1345843);
        vm.deal(minter, insufficientMintFee);
        vm.startPrank(minter);
        vm.expectRevert(
            abi.encodeWithSelector(PoeERC721Reclaimable.InsufficientMintFee.selector)
        );
        poeNft.mint{value: insufficientMintFee}(0);

        // Can mint if they pay at least the mint fee
        sufficientMintFee = bound(sufficientMintFee, poeNft.mintFee(), type(uint256).max);
        vm.deal(minter, sufficientMintFee);
        poeNft.mint{value: sufficientMintFee}(0);
        assertEq(poeNft.ownerOf(0), minter);
    }

    function test_mintAlreadyMintedToken_reverts() public {
        vm.deal(address(this), 2 * mintFee);
        poeNft.mint{value: mintFee}(0);
        assertEq(poeNft.ownerOf(0), address(this));
        vm.expectRevert();
        poeNft.mint{value: mintFee}(0);
    }

    function test_mintBeyondTotalSupply_reverts() public {
        vm.deal(address(this), mintFee);
        vm.expectRevert(
            abi.encodeWithSelector(PoeERC721Reclaimable.InvalidTokenId.selector, maxSupply)
        );
        poeNft.mint{value: mintFee}(maxSupply);
    }
}