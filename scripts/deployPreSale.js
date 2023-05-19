const hre = require("hardhat");


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
