const { expect } = require("chai");
const { ethers } = require("hardhat");
const { solidity } = require("ethereum-waffle");
const SHA3 = require("keccak256");

let signers, deployer, tester1, tester2, feeCollector;
let zooNFT, zooToken, usdt;

describe("Crazy Zoo NFT test suite", async function () {
  const lemurMintFee = "100";
  const rhinoMintFee = "100";
  const gorillaMintFee = "100";
  const baseURI = "https://ipfs.io/demo_url";
  const cids = ["nftCID1", "nftCID2", "nftCID3"];
  const lemurIds = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 2222];
  const rhinoIds = [
    2223, 2224, 2225, 2226, 2227, 2228, 2229, 2230, 2231, 2232, 4444,
  ];
  const gorillaIds = [
    4445, 4446, 4447, 4448, 4449, 4450, 4451, 4452, 4453, 4454, 6666,
  ];

  beforeEach(async function () {
    signers = await ethers.getSigners();
    deployer = signers[0];
    tester1 = signers[1];
    tester2 = signers[2];
    feeCollector = signers[3];
    const ZooNFT = await ethers.getContractFactory("CrazyZooNFT");
    const ZooToken = await ethers.getContractFactory("CrazyZooToken");
    zooToken = await ZooToken.deploy();
    await zooToken.deployed();
    zooNFT = await ZooNFT.deploy(
      ethers.utils.parseUnits(lemurMintFee, 6),
      ethers.utils.parseUnits(rhinoMintFee, 6),
      ethers.utils.parseUnits(gorillaMintFee, 6),
      zooToken.address,
      feeCollector.address,
      baseURI,
      cids[0],
      cids[1],
      cids[2]
    );
    await zooNFT.deployed();

    // Send zoo token to tester1 from deployer
    const transferAmount = "1000000";
    await zooToken
      .connect(deployer)
      .transfer(tester1.address, ethers.utils.parseUnits(transferAmount, 6));

    // Send zoo token to tester2 from deployer
    await zooToken
      .connect(deployer)
      .transfer(tester2.address, ethers.utils.parseUnits(transferAmount, 6));

    // tester1 approve nft contract
    await zooToken
      .connect(tester1)
      .approve(zooNFT.address, ethers.utils.parseUnits(transferAmount, 6));

    // tester2 approve nft contract
    await zooToken
      .connect(tester2)
      .approve(zooNFT.address, ethers.utils.parseUnits(transferAmount, 6));
  });

  it("should NOT allow minting", async function () {
    await expect(
      zooNFT.connect(tester1).safeMint(tester1.address, lemurIds[0])
    ).to.be.revertedWith("You Can Not Mint Now");
    await expect(
      zooNFT.connect(tester1).mintRhino(tester1.address)
    ).to.be.revertedWith("You Can Not Mint Now");

    // tester2 mints Gorilla nft with mintGorilla function
    await expect(
      zooNFT.connect(tester2).mintGorilla(tester2.address)
    ).to.be.revertedWith("You Can Not Mint Now");
  });

  it("should mint different nfts", async function () {
    await zooNFT.safeMint(deployer.address, lemurIds[0]);

    // Set directing minting to true so that others can mint for a fee
    await zooNFT.setDirectMinting(true);

    // tester1 mints Rhino nft with safeMint function
    await zooNFT.connect(tester1).safeMint(tester1.address, rhinoIds[0]);

    // tester2 mints Gorilla nft with mintGorilla function
    await zooNFT.connect(tester2).mintGorilla(tester2.address);

    // Assertions after transactions
    await expect(
      zooNFT.connect(tester1).safeMint(tester1.address, rhinoIds[0])
    ).to.be.revertedWith("ERC721: token already minted");
    expect(await zooNFT.ownerOf(lemurIds[0])).to.equal(deployer.address);
    expect(await zooNFT.ownerOf(rhinoIds[0])).to.equal(tester1.address);
    expect(await zooNFT.balanceOf(tester2.address)).to.equal(1);
    expect(await zooToken.balanceOf(feeCollector.address)).to.equal(
      ethers.utils.parseUnits(
        (parseInt(rhinoMintFee) + parseInt(gorillaMintFee)).toString(),
        6
      )
    );
  });
});
