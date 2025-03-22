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

    function claimReward() external {//申请奖励函数
        _updateMiningIndex();//更新miningindex
        _updateSupplierIndex(msg.sender);//更新用户index

        uint256 claimable = supplierRewardAccrued[msg.sender];//msg.sender的可申请奖励？
        if (claimable == 0) revert NothingClaimable();//如果可申请等于0，返回报错

        supplierRewardAccrued[msg.sender] = 0;//不为0的时候，首先置为0，因为所有的奖励都要转给用户，一次性提取出来
        IERC20(miningToken).safeTransfer(msg.sender, claimable);//奖励转移给用户
        emit RewardClaimed(msg.sender, claimable);//抛出事件，msg sender和可申请的数量
    }

    function getClaimableReward(//到当前为止可领取的奖励
        address supplier//用户地址？-----
    ) external view returns (uint256) {//返回uint256类型的，外部veiw的数值；计算出从上一次到这一次的累计的可领取reward
        uint256 claimable = supplierRewardAccrued[msg.sender];

        // 计算最新的全局指数
        uint256 globalLastIndex = miningLastIndex;//因为不需要更新miningLastIndex变量，所以用一个临时变量
        uint256 totalSupply = totalSupply();//总供应量
        uint256 deltaTime = block.timestamp - lastIndexUpdateTime;//时间差
        if (totalSupply > 0 && deltaTime > 0 && miningSpeedPerSecond > 0) {//判断，如果三个变量大于0
            uint256 deltaReward = miningSpeedPerSecond * deltaTime;//奖励=每秒mining速度*时间差
            uint256 deltaIndex = deltaReward.mulDiv(INDEX_SCALE, totalSupply);//差分指数=奖励差*精度/总供应量
            globalLastIndex += deltaIndex;//差分index加到临时变量globalLastIndex里面
        }

        // 计算用户可累加的奖励
        uint256 supplierIndex = supplierLastIndex[supplier];//用户index赋值
        uint256 supplierSupply = balanceOf(supplier);//余额
        uint256 supplierDeltaIndex;//用户差分index
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

    function _updateMiningIndex() internal {//updateminingindex的实现
        if (miningLastIndex == 0) {//如果为0
            miningLastIndex = INDEX_SCALE;//初始化为INDEX_SCALE
            lastIndexUpdateTime = block.timestamp;//更新时间
        } else {//不等于0的时候开始计算，
            uint256 totalSupply = totalSupply();//总供应
            uint256 deltaTime = block.timestamp - lastIndexUpdateTime;//时间差
            if (totalSupply > 0 && deltaTime > 0 && miningSpeedPerSecond > 0) {//判断，三个参数都大于0的情况下：
                uint256 deltaReward = miningSpeedPerSecond * deltaTime;//每秒挖矿速率*时间差=这段时间给出的奖励数
                uint256 deltaIndex = deltaReward.mulDiv(//指数等于，奖励差*index精度（1e36）/totalsupply，分给总supply
                    INDEX_SCALE,
                    totalSupply
                );
                miningLastIndex += deltaIndex;//1e36+deltaindex=最新的指数
                lastIndexUpdateTime = block.timestamp;//更新时间戳
            } else if (deltaTime > 0) {//其他的两个等于0，delta大于0时
                lastIndexUpdateTime = block.timestamp;//更新update时间戳
            }
        }
    }

    function _updateSupplierIndex(address supplier) internal {//用户级别的index逻辑
        uint256 lastIndex = supplierLastIndex[supplier];//上次的index，supplier（用户？）级别的？
        uint256 supply = balanceOf(supplier);//用户级别的supply
        uint256 deltaIndex;//deltaindex，
        if (lastIndex > 0 && supply > 0) {//指数和supply都大于0时
            deltaIndex = miningLastIndex - lastIndex;//deltaindex等于上一个miningindex减去上次index
            uint256 deltaReward = supply.mulDiv(deltaIndex, INDEX_SCALE);//supply*index差，再除以index标尺（1e36）
            supplierRewardAccrued[supplier] += deltaReward;//累加到用户的奖励中
        }
        supplierLastIndex[supplier] = miningLastIndex;//更新用户奖励的index
        emit SupplierIndexUpdated(supplier, deltaIndex, miningLastIndex);
    }

    // override ERC20 _update function
    function _update(//重写erc20的Update函数---mint，burn，transfer的时候都会用到
        address from,
        address to,
        uint256 value
    ) internal override {
        _updateMiningIndex();//更新全局的什么指数？
        if (from != address(0)) _updateSupplierIndex(from);//from地址不为0的话，更新给用户级别的index
        if (to != address(0)) _updateSupplierIndex(to);//to也会更新，to的index？------
        super._update(from, to, value);
    }
}
