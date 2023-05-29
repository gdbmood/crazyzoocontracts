const hre = require("hardhat");

// myusdc address = 0xb17943D0340100b08e81de93577929C80C6E46e7 mumbai
// myusdc address = 0xb17943D0340100b08e81de93577929C80C6E46e7 arbitrumGoerli
// PreSale address = 0x19A2fC2505098AF4560ABDeF6757CE9eBce157BF mumbai
// PreSale address = 0xD474BA29Ef9AA01Fa897C0A65B23872D8Cd8C146 arbitrumGoerli
// usdc address = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8 //arbitrum mainnet
//PreSale address = 0x719Fc5B98cD13CB17327C30fD5075dB076E5756c //arbitrum mainnet
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
