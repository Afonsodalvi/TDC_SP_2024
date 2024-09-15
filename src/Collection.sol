// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity 0.8.27;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";

contract Collection is ERC1155URIStorage, AccessControl {
    //ids dos NFTs
    uint256 public constant PELE = 0;
    uint256 public constant GARRINCHA = 1;
    uint256 public constant NEYMAR = 2;

    //controle de totais emitidos de cada id
    mapping(uint256 quantity => uint256 id) private s_totalSupply;

    uint256 maxPele = 50;
    uint256 maxGarrincha = 100;
    uint256 maxNeymar = 10000;

    error MaxSupplyReached(uint256 supply); //erro caso ultrapasse o maximo permitido de cada id
    error tokenIdNotExist(uint256 id); //erro caso tente mintar um token id nao existente nessa colecao

    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(address defaultAdmin, address minter, address defaultURIsetter) ERC1155("https://metadado") {
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(URI_SETTER_ROLE, defaultURIsetter);
        _grantRole(MINTER_ROLE, minter);

        //logo que deployarmos ja inserimos os metadados:
        setURI(PELE,"https://metadado/pele");
        setURI(GARRINCHA,"https://metadado/garrincha");
        setURI(NEYMAR,"https://metadado/neymar");
    }

    // função interna de controle de mint
    function _checkMint(uint256 tokenId, uint256 value) internal view virtual {
        if (tokenId >= 3) revert tokenIdNotExist(tokenId);
        if (tokenId == PELE) {
            if (s_totalSupply[tokenId] + value > maxPele) {
                revert MaxSupplyReached(maxPele);
            }
        } else if (tokenId == GARRINCHA) {
            if (s_totalSupply[tokenId] + value > maxGarrincha) {
                revert MaxSupplyReached(maxGarrincha);
            }
        } else if (tokenId == NEYMAR) {
            if (s_totalSupply[tokenId] + value > maxNeymar) {
                revert MaxSupplyReached(maxNeymar);
            }
        }
    }

    // função interna de controle de mint em batch
    function _checkMintBatch(uint256[] memory tokenIds, uint256[] memory values) internal view virtual {
        require(tokenIds.length == values.length, "Ids e valores devem ter o mesmo comprimento");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (tokenIds[i] == PELE) {
                if (s_totalSupply[tokenIds[i]] + values[i] > maxPele) {
                    revert MaxSupplyReached(maxPele);
                }
            } else if (tokenIds[i] == GARRINCHA) {
                if (s_totalSupply[tokenIds[i]] + values[i] > maxGarrincha) {
                    revert MaxSupplyReached(maxGarrincha);
                }
            } else if (tokenIds[i] == NEYMAR) {
                if (s_totalSupply[tokenIds[i]] + values[i] > maxNeymar) {
                    revert MaxSupplyReached(maxNeymar);
                }
            } else if (tokenIds[i] >= 3) {
                revert tokenIdNotExist(tokenIds[i]);
            }
        }
    }

    function setURI(uint _tokenId, string memory newuri) public onlyRole(URI_SETTER_ROLE) {
        _setURI(_tokenId, newuri);
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data) public onlyRole(MINTER_ROLE) {
        //faz o check do mint
        _checkMint(id, amount);
        //soma a quantidade ao total emitido do Id
        s_totalSupply[id] += amount;
        _mint(account, id, amount, data);
    }

    function mintPublic(address account, uint256 id, uint256 amount, bytes memory data) public {
        //faz o check do mint
        _checkMint(id, amount);
        //soma a quantidade ao total emitido do Id
        s_totalSupply[id] += amount;
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public {
        //faz o check do mint
        _checkMintBatch(ids, amounts);
        for (uint256 i = 0; i < ids.length; i++) {
            s_totalSupply[ids[i]] += amounts[i];
        }
        _mintBatch(to, ids, amounts, data);
    }

    function setRoleMinter(address user) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(MINTER_ROLE, user);
    }

    function setRoleURI(address user) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(URI_SETTER_ROLE, user);
    }

    // The following functions are overrides required by Solidity.

    function _update(address from, address to, uint256[] memory ids, uint256[] memory values)
        internal
        override(ERC1155)
    {
        super._update(from, to, ids, values);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
