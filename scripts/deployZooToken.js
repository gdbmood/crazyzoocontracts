const hre = require("hardhat");

const crazyZooToken = async() => {
  const CrazyZooToken = await hre.ethers.getContractFactory("CrazyZooToken");
  const crazyZooToken = await CrazyZooToken.deploy();

  await crazyZooToken.deployed();

  console.log(
    `crazyZooToken deployed to ${crazyZooToken.address}`
  );
  return crazyZooToken.address;
}

async function main() {
    const ZooToken = await crazyZooToken()
}
   
// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
