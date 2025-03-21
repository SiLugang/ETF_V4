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

    function updateMiningSpeedPerSecond(uint256 speed) external;

    function claimReward() external;

    function miningToken() external view returns (address);

    function INDEX_SCALE() external view returns (uint256);

    function miningSpeedPerSecond() external view returns (uint256);

    function miningLastIndex() external view returns (uint256);

    function lastIndexUpdateTime() external view returns (uint256);

    function supplierLastIndex(
        address supplier
    ) external view returns (uint256);

    function supplierRewardAccrued(
        address supplier
    ) external view returns (uint256);

    function getClaimableReward(
        address supplier
    ) external view returns (uint256);
}
