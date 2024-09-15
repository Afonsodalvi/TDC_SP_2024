// SPDX-License-Identifier: MIT
/*solhint-disable compiler-version */
pragma solidity ^0.8.20;

/// -----------------------------------------------------------------------
/// Imports
/// -----------------------------------------------------------------------

import {Test, console} from "forge-std/Test.sol";
import {HelperConfig} from "../../../script/HelperConfig.s.sol";
import {Collection} from "../src/Collection.sol";

contract FanTokenTest is Test {
    Collection public collection;

    //gerando enderecos para interagir
    address public minter = makeAddr("minter");
    address public uriUser = makeAddr("uriUser");
    address public user = makeAddr("user");

    address public owner = makeAddr("owner");

    address public invalidAddr = makeAddr("invalidAddr");

    function setUp() public {
        //Managemet do contrato de claimIssuer identidades deve ser o mesmo
        vm.startBroadcast(owner);

        collection = new Collection(owner, minter, owner);

        vm.stopBroadcast();
    }

    function testContractSucess() public {
        //variaveis
        uint256 amountMinter = 10;
        uint256 id1 = 1;
        string memory PELE = "https://metadado/pele";
        string memory GARRINCHA = "https://metadado/garrincha";
        string memory NEYMAR = "https://metadado/neymar";

        uint256[] memory ids = new uint256[](10);
        ids[0] = 0;
        ids[1] = 1;
        ids[2] = 2;

        uint256[] memory amounts = new uint256[](10);
        amounts[0] = 10;
        amounts[1] = 5;
        amounts[2] = 4;

        string memory uri = "metadado";

        vm.prank(minter);
        collection.mint(minter, id1, amountMinter, "0x00");

        vm.prank(user);
        collection.mintBatch(owner, ids, amounts, "0x00");

        //o owner sendo o admin ele pode dar permissao
        vm.prank(owner);
        collection.setRoleURI(uriUser);

        string memory id0metadado = collection.uri(0);
        assertEq(id0metadado, PELE);

        string memory id1metadado = collection.uri(1);
        assertEq(id1metadado, GARRINCHA);

        string memory id2metadado = collection.uri(2);
        assertEq(id2metadado, NEYMAR);

        vm.prank(uriUser); //usuario que tem permissao pode setar o novo metadado
        collection.setURI(id1,uri);


    }

    function testContractFail() external {
        //Como testar se a funcao vai falhar ou nao:

        uint256[] memory ids = new uint256[](10);
        ids[0] = 0;
        ids[1] = 1;
        ids[2] = 2;

        uint256[] memory amounts = new uint256[](10);
        amounts[0] = 10;
        amounts[1] = 5;
        amounts[2] = 4;

        uint256[] memory amountsRevert = new uint256[](10);
        amountsRevert[0] = 41;
        amountsRevert[1] = 5;
        amountsRevert[2] = 4;

        vm.prank(user);
        collection.mintBatch(owner, ids, amounts, "0x00");

        vm.prank(owner);
        vm.expectRevert(); //esperamos que reverta pq passou do numero limite
        collection.mintBatch(owner, ids, amountsRevert, "0x00");

        vm.prank(user);
        vm.expectRevert(); //esperamos que reverta pq somente o owner pode setar permissoes
        collection.setRoleMinter(user);
    }
}
