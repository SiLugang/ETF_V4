import { etfAbi } from "../abis/etf";
import { erc20Abi } from "../abis/erc20";
import { etfAddress, eptAddress } from "./Constants";
import { useAccount, useReadContract, useWriteContract } from "wagmi";
import { useEffect, useState } from "react";

export const RewardPanel = () => {
  const { address } = useAccount();

  const [balance, setBalance] = useState<string>("0");
  const [claimable, setClaimable] = useState<string>("0");
  const [canClaim, setCanClaim] = useState<boolean>(false);

  const { data: balanceData, refetch: refetchBalance } = useReadContract({
    abi: erc20Abi,
    address: eptAddress,
    functionName: "balanceOf",
    args: [address || "0x0"],
  });

  useEffect(() => {
    if (address && balanceData && typeof balanceData === "bigint") {
      const eptBalance = balanceData
        ? (Number(balanceData) / Math.pow(10, 18)).toFixed(2) // 修改为带小数的格式
        : "0";
      setBalance(eptBalance);
    } else {
      setBalance("0");
    }
  }, [balanceData, address]);

  const { data: claimableData, refetch: refetchClaimable } = useReadContract({
    abi: etfAbi,
    address: etfAddress,
    functionName: "getClaimableReward",
    args: [address || "0x0"],
  });

  useEffect(() => {
    if (address && claimableData && typeof claimableData === "bigint") {
      const eptClaimable = (Number(claimableData) / Math.pow(10, 18)).toFixed(
        2
      );
      setClaimable(eptClaimable);
      setCanClaim(claimableData > 0);
    } else {
      setClaimable("0");
      setCanClaim(false);
    }
  }, [claimableData, address]);

  useEffect(() => {
    const interval = setInterval(() => {
      refetchClaimable();
    }, 5000); // 每 5 秒执行一次

    return () => clearInterval(interval); // 清理定时器
  }, [address, refetchClaimable]);

  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const { writeContract, isSuccess, error } = useWriteContract();
  const handleClaim = () => {
    writeContract({
      abi: etfAbi,
      address: etfAddress,
      functionName: "claimReward",
    });
    setErrorMessage(null); // 清除错误信息
  };
  useEffect(() => {
    if (isSuccess) {
      refetchBalance();
      refetchClaimable();
    } else if (error) {
      setErrorMessage("Invest failed, check your available or your gas.");
    }
  }, [error, isSuccess, refetchBalance, refetchClaimable]);

  return (
    <div className="card">
      <h2>My EPT</h2>
      <div className="about-section">
        <div className="about-content">
          <div className="info-item">
            <p className="value">{balance}</p>
            <p className="label">Balance</p>
          </div>
          <div className="info-item">
            <p className="value">{claimable}</p>
            <p className="label">Claimable</p>
          </div>
        </div>
      </div>
      {/* 显示错误信息 */}
      {errorMessage && <div className="error-message">{errorMessage}</div>}
      <button
        className={`button ${!canClaim ? "disabled" : ""}`}
        disabled={!canClaim}
        onClick={handleClaim}
      >
        Claim EPT
      </button>
    </div>
  );
};
