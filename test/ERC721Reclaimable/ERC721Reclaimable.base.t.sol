// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {IERC721Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {ERC721ReclaimableMintable} from "../ERC721ReclaimableMintable.sol";

contract ERC721ReclaimableBaseTest is Test, IERC721Errors {
    ERC721ReclaimableMintable internal nft;
    address constant TITLE_FEE_RECIPIENT = address(9248093483458);

    function setUp() public {
        nft = new ERC721ReclaimableMintable({
            name: "ReclaimableTestNft",
            symbol: "RTN",
            titleTransferFee: 1 ether,
            titleFeeRecipient: TITLE_FEE_RECIPIENT,
            minter: address(this),
            mintAmount: 10
        });
    }
}