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

const crazyZooNFT = async( mockToken , feeCollector) => {
  const CrazyZooNFT = await hre.ethers.getContractFactory("CrazyZooNFT");
  const crazyZooNFT = await CrazyZooNFT.deploy(mockToken,feeCollector);

  await crazyZooNFT.deployed();

  console.log(
    `crazyZooNFT deployed to ${crazyZooNFT.address}`
  );
  return crazyZooNFT.address;
}

const preSale = async() => {
  const PreSale = await hre.ethers.getContractFactory("PreSale");
  const preSale = await PreSale.deploy();

  await preSale.deployed();

  console.log(
    `preSale deployed to ${preSale.address}`
  );
  return preSale.address;
}

// UniswapIntermediary
const uniswapIntermediary = async(
 routerAddress, Zoo, factory, Quote, poolFee 
) => {
  const UniswapIntermediary = await hre.ethers.getContractFactory("UniswapIntermediary");
  const uniswapIntermediary = await UniswapIntermediary.deploy(routerAddress, Zoo, factory, Quote, poolFee);

  await uniswapIntermediary.deployed();

  console.log(
    `uniswapIntermediary deployed to ${uniswapIntermediary.address}`
  );
  return uniswapIntermediary.address;
}

const crazyZooStaking = async(
  ZooNFT,UsdtToken,uniSwap,ZooToken,feeCollector
  ) => {
  const CrazyZooStaking = await hre.ethers.getContractFactory("CrazyZooStaking");
  const crazyZooStaking = await CrazyZooStaking.deploy(ZooNFT,UsdtToken,uniSwap,ZooToken,feeCollector);

  await crazyZooStaking.deployed();

  console.log(
    `crazyZooStaking deployed to ${crazyZooStaking.address}`
  );
  return crazyZooStaking.address;
} 
const mockToken = async(
  ) => {
  const MYUSDC = await hre.ethers.getContractFactory("MYUSDC");
  const mYUSDC = await MYUSDC.deploy();

  await mYUSDC.deployed();

  console.log(
    `mYUSDC deployed to ${mYUSDC.address}`
  );
  return mYUSDC.address;
} 
async function main() {
    const ZooToken = await crazyZooToken()
    const preSaleContract = await preSale() 
    const _mockToken = await mockToken()
    const ZooNFT = await crazyZooNFT(`${_mockToken}`,`0x34Baffa584cF55d1CCF8d8A2762e938e6f765F3E`)
    const uniswap = await uniswapIntermediary("0xE592427A0AEce92De3Edee1F18E0157C05861564",`${ZooToken}`,"0x1F98431c8aD98523631AE4a59f267346ea31F984","0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6",'3000')
    const Staking = await crazyZooStaking(`${ZooNFT}`,`${_mockToken}`,`${uniswap}`,`${ZooToken}`,`0x34Baffa584cF55d1CCF8d8A2762e938e6f765F3E`)
  
}
    // address routerAddress = 0xE592427A0AEce92De3Edee1F18E0157C05861564
    // address factory = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    // address Quoter = 0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6
// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
