// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {ERC721ReclaimableBaseTest} from "./ERC721Reclaimable.base.t.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract ERC721ReclaimableEnumerableTest is ERC721ReclaimableBaseTest {
    function testTokenOfTitleOwnerByIndex_inBounds_returnsTokenIndex() public {
        uint256 titleBalance = nft.titleBalanceOf(address(this));
        for (uint i = 0; i < titleBalance; ++i) {
            uint256 tokenId = nft.tokenOfTitleOwnerByIndex(address(this), i);
            assertEq(tokenId, i);
        }

        // Execute a tranfer for token 5
        address receiver = address(1234);
        nft.titleTransferFrom{ value: nft.titleTransferFee() }(address(this), receiver, 5);

        // Now enumerate again. The token at position 5 should be token 9. All else should be
        // the same
        titleBalance = nft.titleBalanceOf(address(this));
        for (uint i = 0; i < titleBalance; ++i) {
            uint256 tokenId = nft.tokenOfTitleOwnerByIndex(address(this), i);
            if (i == 5) {
                assertEq(tokenId, 9);
            } else {
                assertEq(tokenId, i);
            }
        }

        // Check the receiver
        assertEq(nft.titleBalanceOf(receiver), 1);
        assertEq(nft.tokenOfTitleOwnerByIndex(receiver, 0), 5);
    }

    function testTokenOfTitleOwnerByindex_outOfBounds_reverts() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                ERC721Enumerable.ERC721OutOfBoundsIndex.selector,
                address(this),
                10
            )
        );
        nft.tokenOfTitleOwnerByIndex(address(this), 10);
    }
}