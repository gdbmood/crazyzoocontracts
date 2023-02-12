const hre = require("hardhat");

async function main() {
    const NFT = await hre.ethers.getContractFactory("CrazyZooNFT");
    const nft = await NFT.deploy(125, 250, 500,
        '0x0Da4Fc2fb011c076B3DC5Dcd5c9D7d0c2E78AE68', '0x4696F32B4F26476e0d6071d99f196929Df56575b',
        'https://crazyzoo.mypinata.cloud/ipfs/', 'QmRULr4Roskph3ssTeTFEhEPHyoLVGd3FnKNqTCMYf6TbA', 'QmUpCH3KoADdvY3rXo6gSCM9j9k7Rchzebe5GJk9WbSzmM', 'QmUpCH3KoADdvY3rXo6gSCM9j9k7Rchzebe5GJk9WbSzmM');

    await nft.deployed();

    console.log("NFT deployed to:", nft.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
