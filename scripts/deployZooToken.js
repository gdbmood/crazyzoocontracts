const hre = require("hardhat");

// token address = 0x3F96DA7Ab90610160Cfd973BA9F4e68a890C354C mumbai
// token address = 0xd1d2C63e8f84410e8eB9cA3Fcd5d81064Cc7AeA7 arbitrumGoerli
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


