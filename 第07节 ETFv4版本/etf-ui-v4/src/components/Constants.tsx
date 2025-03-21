import { getAddress } from "viem";

const etfAddress = getAddress("0x66a7108F00B9564Fa61F368229feB1B853306fBf");
const usdcAddress = getAddress("0x22e18Fc2C061f2A500B193E5dBABA175be7cdD7f");
const wethAddress = getAddress("0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14");
const etfQuoterAddress = getAddress(
  "0xF6Fd1703cF0C71221e71Fc08163Da1a38bB777a7"
);
const eptAddress = getAddress("0x5A50Dbba1cCb2C644750Af3Cc193fcAAeeb4084b");

export { etfAddress, usdcAddress, wethAddress, etfQuoterAddress, eptAddress };
