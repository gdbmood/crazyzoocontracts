const hre = require("hardhat");

async function main() {
    const Staking = await hre.ethers.getContractFactory("CrazyZooNftStaking");
    const staking = await Staking.deploy('0x3266965D7d85F1AE9AdAe1b58fc9dF85cE2a6a6b', '0x0Da4Fc2fb011c076B3DC5Dcd5c9D7d0c2E78AE68', '0x0Da4Fc2fb011c076B3DC5Dcd5c9D7d0c2E78AE68');

    await staking.deployed();

    console.log("Staking deployed to:", staking.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
