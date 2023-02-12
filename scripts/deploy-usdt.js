const hre = require("hardhat");

async function main() {
    const USDT = await hre.ethers.getContractFactory("TetherToken");
    const usdt = await USDT.deploy(1000000000000, 'Tether USD', 'USDT', 6);

    await usdt.deployed();

    console.log("USDT deployed to:", usdt.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
