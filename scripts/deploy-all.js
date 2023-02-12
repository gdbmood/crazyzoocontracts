const hre = require("hardhat");

async function main() {
    const Token = await hre.ethers.getContractFactory("CrazyZooToken");
    const NFT = await hre.ethers.getContractFactory("CrazyZooNFT");
    const Staking = await hre.ethers.getContractFactory("CrazyZooNftStaking");

    const token = await Token.deploy();
    await token.deployed();
    console.log("Token deployed to:", token.address);

    const nft = await NFT.deploy(125 * Math.pow(10, 6), 250 * Math.pow(10, 6), 500 * Math.pow(10, 6),
        token.address, '0x4696F32B4F26476e0d6071d99f196929Df56575b',
        'https://crazyzoo.mypinata.cloud/ipfs/', 'QmRULr4Roskph3ssTeTFEhEPHyoLVGd3FnKNqTCMYf6TbA', 'QmUpCH3KoADdvY3rXo6gSCM9j9k7Rchzebe5GJk9WbSzmM', 'QmUpCH3KoADdvY3rXo6gSCM9j9k7Rchzebe5GJk9WbSzmM');
    await nft.deployed();
    console.log("NFT deployed to:", nft.address);

    const staking = await Staking.deploy(nft.address, token.address, token.address, '0x89E6F71562f080aAeBAfB362E0F34fad8708891c');
    await staking.deployed();
    console.log("Staking deployed to:", staking.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
