const hre = require("hardhat");

// myusdc address = 0xb17943D0340100b08e81de93577929C80C6E46e7 mumbai
// myusdc address = 0xb17943D0340100b08e81de93577929C80C6E46e7 arbitrumGoerli
// PreSale address = 0x19A2fC2505098AF4560ABDeF6757CE9eBce157BF mumbai
// PreSale address = 0x577F4f1Cc45b9e14C0b770A1efBf601f5E8b7594 arbitrumGoerli

const preSale = async() => {
  const PreSale = await hre.ethers.getContractFactory("PreSale");
  const preSale = await PreSale.deploy();

  await preSale.deployed();

  console.log(
    `preSale deployed to ${preSale.address}`
  );
  return preSale.address;
}


async function main() {
    const preSaleContract = await preSale()
}
   
// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
