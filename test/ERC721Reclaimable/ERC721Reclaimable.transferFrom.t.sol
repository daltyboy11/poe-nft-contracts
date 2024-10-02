// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {ERC721ReclaimableBaseTest} from "./ERC721Reclaimable.base.t.sol";
import {IERC721Reclaimable} from "../../src/interfaces/IERC721Reclaimable.sol";

contract ERC721ReclaimableTransferFromTest is ERC721ReclaimableBaseTest {  
    function testTransferFromNotCallableByTitleOwnerIfTheyDontOwnIt() public {
        nft.transferFrom(address(this), address(3), 1);
        vm.expectRevert(abi.encodeWithSelector(ERC721InsufficientApproval.selector, 0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496, 1));
        nft.transferFrom(address(3), address(this), 1);
    }

    function testTransferFromDoesNotChangeTitleOwnership(address owner) public {
        vm.assume(owner != address(this) && owner != address(0));
        nft.transferFrom(address(this), address(owner), 1);
        assertEq(nft.ownerOf(1), owner);
        assertEq(nft.titleOwnerOf(1), address(this));
    }

    function testTitleTransferFromDoesNotChangeTitleBalance(address owner) public {
        vm.assume(owner != address(this) && owner != address(0));
        uint256 titleBalanceBefore = nft.titleBalanceOf(address(this));
        nft.transferFrom(address(this), address(owner), 1);
        assertEq(nft.titleBalanceOf(address(this)), titleBalanceBefore);
    }
}