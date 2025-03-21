// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ETFv3} from "./ETFv3.sol";
import {IETFv4} from "./interfaces/IETFv4.sol";
import {IERC20} from "@openzeppelin/contracts@5.1.0/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts@5.1.0/token/ERC20/utils/SafeERC20.sol";
import {FullMath} from "./libraries/FullMath.sol";

contract ETFv4 is IETFv4, ETFv3 {
    using SafeERC20 for IERC20;
    using FullMath for uint256;

    uint256 public constant INDEX_SCALE = 1e36;

    address public miningToken;
    uint256 public miningSpeedPerSecond;
    uint256 public miningLastIndex;
    uint256 public lastIndexUpdateTime;

    mapping(address => uint256) public supplierLastIndex;
    mapping(address => uint256) public supplierRewardAccrued;

    constructor(
        string memory name_,
        string memory symbol_,
        address[] memory tokens_,
        uint256[] memory initTokenAmountPerShare_,
        uint256 minMintAmount_,
        address swapRouter_,
        address weth_,
        address etfQuoter_,
        address miningToken_
    )
        ETFv3(
            name_,
            symbol_,
            tokens_,
            initTokenAmountPerShare_,
            minMintAmount_,
            swapRouter_,
            weth_,
            etfQuoter_
        )
    {
        miningToken = miningToken_;
        miningLastIndex = 1e36;
    }

    function updateMiningSpeedPerSecond(uint256 speed) external onlyOwner {
        _updateMiningIndex();
        miningSpeedPerSecond = speed;
    }

    function withdrawMiningToken(
        address to,
        uint256 amount
    ) external onlyOwner {
        IERC20(miningToken).safeTransfer(to, amount);
    }

    function claimReward() external {
        _updateMiningIndex();
        _updateSupplierIndex(msg.sender);

        uint256 claimable = supplierRewardAccrued[msg.sender];
        if (claimable == 0) revert NothingClaimable();

        supplierRewardAccrued[msg.sender] = 0;
        IERC20(miningToken).safeTransfer(msg.sender, claimable);
        emit RewardClaimed(msg.sender, claimable);
    }

    function getClaimableReward(
        address supplier
    ) external view returns (uint256) {
        uint256 claimable = supplierRewardAccrued[msg.sender];

        // 计算最新的全局指数
        uint256 globalLastIndex = miningLastIndex;
        uint256 totalSupply = totalSupply();
        uint256 deltaTime = block.timestamp - lastIndexUpdateTime;
        if (totalSupply > 0 && deltaTime > 0 && miningSpeedPerSecond > 0) {
            uint256 deltaReward = miningSpeedPerSecond * deltaTime;
            uint256 deltaIndex = deltaReward.mulDiv(INDEX_SCALE, totalSupply);
            globalLastIndex += deltaIndex;
        }

        // 计算用户可累加的奖励
        uint256 supplierIndex = supplierLastIndex[supplier];
        uint256 supplierSupply = balanceOf(supplier);
        uint256 supplierDeltaIndex;
        if (supplierIndex > 0 && supplierSupply > 0) {
            supplierDeltaIndex = globalLastIndex - supplierIndex;
            uint256 supplierDeltaReward = supplierSupply.mulDiv(
                supplierDeltaIndex,
                INDEX_SCALE
            );
            claimable += supplierDeltaReward;
        }

        return claimable;
    }

    function _updateMiningIndex() internal {
        if (miningLastIndex == 0) {
            miningLastIndex = INDEX_SCALE;
            lastIndexUpdateTime = block.timestamp;
        } else {
            uint256 totalSupply = totalSupply();
            uint256 deltaTime = block.timestamp - lastIndexUpdateTime;
            if (totalSupply > 0 && deltaTime > 0 && miningSpeedPerSecond > 0) {
                uint256 deltaReward = miningSpeedPerSecond * deltaTime;
                uint256 deltaIndex = deltaReward.mulDiv(
                    INDEX_SCALE,
                    totalSupply
                );
                miningLastIndex += deltaIndex;
                lastIndexUpdateTime = block.timestamp;
            } else if (deltaTime > 0) {
                lastIndexUpdateTime = block.timestamp;
            }
        }
    }

    function _updateSupplierIndex(address supplier) internal {
        uint256 lastIndex = supplierLastIndex[supplier];
        uint256 supply = balanceOf(supplier);
        uint256 deltaIndex;
        if (lastIndex > 0 && supply > 0) {
            deltaIndex = miningLastIndex - lastIndex;
            uint256 deltaReward = supply.mulDiv(deltaIndex, INDEX_SCALE);
            supplierRewardAccrued[supplier] += deltaReward;
        }
        supplierLastIndex[supplier] = miningLastIndex;
        emit SupplierIndexUpdated(supplier, deltaIndex, miningLastIndex);
    }

    // override ERC20 _update function
    function _update(
        address from,
        address to,
        uint256 value
    ) internal override {
        _updateMiningIndex();
        if (from != address(0)) _updateSupplierIndex(from);
        if (to != address(0)) _updateSupplierIndex(to);
        super._update(from, to, value);
    }
}
