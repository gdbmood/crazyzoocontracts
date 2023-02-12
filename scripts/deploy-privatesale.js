const hre = require("hardhat");
const SHA3 = require('keccak256');

async function main() {
    const Sales = await hre.ethers.getContractFactory("ZooPrivateSale");
    // const Zoo = await hre.ethers.getContractFactory("ZOOToken");
    const sales = await Sales.deploy('0x8DEBd2065866888D0E38A6E4D43bB9ccc0d08829', '0x4F78C5Bb5AF7f61F67365729A66F5B203358d0d4');

    await sales.deployed();
    console.log("Sales deployed to:", sales.address);
    // const zoo = Zoo.attach('0x2B56424FBE1632993163d3DdfE59aeb86070f0F1');
    // await zoo.setMinter(sales.address);
    // console.log("Set minter");
    // const ADMIN = SHA3("ADMIN");
    // await sales.grantRole(ADMIN, '0x129F3153E143A32CFb3FC0ca023375109491f435');


}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
