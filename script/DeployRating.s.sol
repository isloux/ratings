// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.23;

import {Script} from "forge-std/Script.sol";
import {Rating} from "../src/ratings.sol";

contract DeployRating is Script {
    function run() external returns(Rating) {
        vm.startBroadcast();
        Rating rating = new Rating();
        vm.stopBroadcast();
        return rating;
    }
}
