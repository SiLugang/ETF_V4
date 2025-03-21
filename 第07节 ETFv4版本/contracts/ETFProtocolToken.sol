// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity 0.8.24;

import {ERC20} from "@openzeppelin/contracts@5.1.0/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts@5.1.0/token/ERC20/extensions/ERC20Burnable.sol";
import {AccessControl} from "@openzeppelin/contracts@5.1.0/access/AccessControl.sol";
import {ERC20Permit} from "@openzeppelin/contracts@5.1.0/token/ERC20/extensions/ERC20Permit.sol";
import {ERC20Votes} from "@openzeppelin/contracts@5.1.0/token/ERC20/extensions/ERC20Votes.sol";
import {Nonces} from "@openzeppelin/contracts@5.1.0/utils/Nonces.sol";

contract ETFProtocolToken is//ETF的token继承
    ERC20,
    ERC20Burnable,
    AccessControl,
    ERC20Permit,
    ERC20Votes
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");//初始化
    uint256 public constant INIT_TOTAL_SUPPLY = 1_000_000e18; // 1 million------初始化总供应量

    constructor(
        address defaultAdmin,
        address minter
    )
        ERC20("BlockETF Protocol Token", "EPT")
        ERC20Permit("BlockETF Protocol Token")
    {
        _mint(msg.sender, INIT_TOTAL_SUPPLY);//给msg.sender mint了这么多
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);//区分两个ROLE？为什么怎么分的这些role
        _grantRole(MINTER_ROLE, minter);
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {//mint函数
        _mint(to, amount);
    }

    // Overrides IERC6372 functions to make the token & governor timestamp-based

    function clock() public view override returns (uint48) {//和治理有关----出块时间固定用block number；不固定用TimeStamp
        return uint48(block.timestamp);
    }

    // solhint-disable-next-line func-name-mixedcase
    function CLOCK_MODE() public pure override returns (string memory) {//和治理有关
        return "mode=timestamp";
    }

    // The following functions are overrides required by Solidity.

    function _update(
        address from,
        address to,
        uint256 value
    ) internal override(ERC20, ERC20Votes) {
        super._update(from, to, value);
    }

    function nonces(
        address owner
    ) public view override(ERC20Permit, Nonces) returns (uint256) {
        return super.nonces(owner);
    }
}
