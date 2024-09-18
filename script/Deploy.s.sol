// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {FanToken} from "../src/FanToken.sol";
import {Collection} from "../src/Collection.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract CounterScript is Script {
    FanToken public fanToken;
    Collection public collection;
    HelperConfig public config;

    function setUp() public {}

    function run() public {
        config = new HelperConfig();
        (uint256 key) = config.activeNetworkConfig();

        vm.startBroadcast(vm.rememberKey(key));

        fanToken = new FanToken(vm.addr(key));
        collection = new Collection(vm.addr(key), vm.addr(key), vm.addr(key));

        vm.stopBroadcast();
        console.log("address FanToken:", address(fanToken));
        console.log("address Collection:", address(collection));

    }
}
