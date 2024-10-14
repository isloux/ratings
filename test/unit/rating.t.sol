// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.23;

import {BaseSetup, console} from "./baseSetup.t.sol";
import {Rating} from "../../src/ratings.sol";
import {DeployRating} from "../../script/DeployRating.s.sol";

library GetCode {
    function getBytecode(address _addr) public pure returns (bytes memory) {
        return type(Rating).creationCode;
    }
}

contract RatingTest is BaseSetup {
    Rating rating;
    uint8 constant FIRSTRATING = 4;
    uint8 constant SECONDRATING = 2;
    uint8 constant THIRDRATING = 5;
    uint8 constant FOURTHRATING = 5;
    using GetCode for address;

    function setUp() external {
        DeployRating deployRating = new DeployRating();
        rating = deployRating.run();
    }

    function testShowByteCode() public view {
        console.logBytes(address(rating).getBytecode());
    }

    function testRating() public {
        vm.prank(msg.sender);
        rating.rateAddress(alice, FIRSTRATING);
        (uint48 aliceRating, uint48 ratingCount) = rating.getRating(alice);
        assert(aliceRating == 4000);
        assert(ratingCount == 1);
        vm.prank(mallory);
        rating.rateAddress(alice, SECONDRATING);
        (aliceRating, ratingCount) = rating.getRating(alice);
        assert(aliceRating == 3000);
        assert(ratingCount == 2);
        vm.prank(bob);
        rating.rateAddress(alice, THIRDRATING);
        uint256 to = rating.getTimeOut(msg.sender);
        console.log(to);
        rating.rateAddress(alice, FOURTHRATING);
        (aliceRating, ratingCount) = rating.getRating(alice);
        assert(aliceRating == 4000);
        assert(ratingCount == 4);
        vm.prank(mallory);
        rating.rateAddress(bob, FOURTHRATING);
        (uint48 bobRating, ) = rating.getRating(bob);
        assert(bobRating == 5000);
    }

    function testComment() public {
        string memory comment = "Ce portefeuille est formidable.";
        vm.prank(bob);
        rating.addComment(comment);
        assertEq(rating.getNumberOfComments(), 1);
        string[] memory comments = rating.getComments();
        assertEq(comments[0], comment);
    }
}
