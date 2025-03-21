// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IETFv3} from "./IETFv3.sol";

interface IETFv4 is IETFv3 {
    error NothingClaimable();

    event SupplierIndexUpdated(
        address indexed supplier,
        uint256 deltaIndex,
        uint256 lastIndex
    );
    event RewardClaimed(address indexed supplier, uint256 claimedAmount);

    function updateMiningSpeedPerSecond(uint256 speed) external;//外部可见，更新挖矿速率

    function claimReward() external;//

    function miningToken() external view returns (address);

    function INDEX_SCALE() external view returns (uint256);

    function miningSpeedPerSecond() external view returns (uint256);//挖矿的速率

    function miningLastIndex() external view returns (uint256);//挖矿的全局级别的指数----从开始到当前累计的，奖励；每单位的ETF代币可分得的一个相关的指数

    function lastIndexUpdateTime() external view returns (uint256);//上面的指数的最近的一次更新时间

    function supplierLastIndex(//用户级别的指数
        address supplier//每个用户会更新一个指数index
    ) external view returns (uint256);

    function supplierRewardAccrued(//每个用户累计的奖励，到上市交互为止累计下来的奖励，未领取的奖励？
        address supplier
    ) external view returns (uint256);

    function getClaimableReward(//可以查询当前为止，的可领取的奖励---每次查询会有不同的变化
        address supplier
    ) external view returns (uint256);
}
