const chai = require("chai");
const { expect } = require("chai");
const { ethers } = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-network-helpers");
const { solidity } = require("ethereum-waffle");

chai.use(solidity);

const SHA3 = require("keccak256");

let signers,
  deployer,
  tester1,
  tester2,
  feeCollector,
  treasury,
  referer1,
  referer2,
  referer3;
let zooNFT, zooToken, zooNftStaking, usdt;
let timeStamp1, timeStamp2, reward1, reward2, timer;

describe("Zoo NFT staking test suite", async function () {
  // Fees for direct minting
  const lemurMintFee = "100";
  const rhinoMintFee = "100";
  const gorillaMintFee = "100";

  // Fees (in percent) & prices (in wei) on NFT staking contract
  const rewardsPerDay = [6, 7, 8];
  const mintingFees = ["13", "13", "13"];
  const nftPrices = ["125", "250", "500"];
  const actualRewardsPerDay = [
    rewardsPerDay[0] * parseInt(nftPrices[0]),
    rewardsPerDay[1] * parseInt(nftPrices[1]),
    rewardsPerDay[2] * parseInt(nftPrices[2]),
  ];

  const baseURI = "https://ipfs.io/demo_url";
  const cids = ["nftCID1", "nftCID2", "nftCID3"];
  const lemurIds = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 2222];
  const rhinoIds = [
    2223, 2224, 2225, 2226, 2227, 2228, 2229, 2230, 2231, 2232, 4444,
  ];
  const gorillaIds = [
    4445, 4446, 4447, 4448, 4449, 4450, 4451, 4452, 4453, 4454, 6666,
  ];
  const nftIndex = [1, 2, 3];
  const tester1mintedTokenIds = [1];
  const tester2mintedTokenIds = [2];

  const transferAmount = "1000000";

  before(async function () {
    signers = await ethers.getSigners();
    deployer = signers[0];
    tester1 = signers[1];
    tester2 = signers[2];
    feeCollector = signers[3];
    referer1 = signers[4];
    referer2 = signers[5];
    referer3 = signers[6];
    treasury = signers[6];

    const ZooNFT = await ethers.getContractFactory("CrazyZooNFT");
    const ZooToken = await ethers.getContractFactory("CrazyZooToken");
    const ZooNftStaking = await ethers.getContractFactory("CrazyZooNftStaking");
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
    zooNftStaking = await ZooNftStaking.deploy(
      zooNFT.address,
      zooToken.address,
      zooToken.address,
      treasury.address
    );

    await zooNftStaking.deployed();
    await zooToken.setMinter(zooNftStaking.address);
    const MINTER_ROLE = SHA3("MINTER_ROLE");
    await zooNFT.grantRole(MINTER_ROLE, zooNftStaking.address);
  });

  it("should mint nfts from staking contract", async function () {
    // Send zoo token to tester1 from deployer
    await zooToken
      .connect(deployer)
      .transfer(tester1.address, ethers.utils.parseUnits(transferAmount, 6));
    // Send zoo token to tester2 from deployer
    await zooToken
      .connect(deployer)
      .transfer(tester2.address, ethers.utils.parseUnits(transferAmount, 6));

    // tester1 approve nft staking contract
    await zooToken
      .connect(tester1)
      .approve(
        zooNftStaking.address,
        ethers.utils.parseUnits(transferAmount, 6)
      );

    // tester2 approve nft contract
    await zooToken
      .connect(tester2)
      .approve(
        zooNftStaking.address,
        ethers.utils.parseUnits(transferAmount, 6)
      );
    expect(await zooToken.balanceOf(zooNftStaking.address)).to.equal(
      ethers.utils.parseUnits("0", 6)
    );

    expect(await zooNFT.balanceOf(tester1.address)).to.equal(0);
    expect(await zooNFT.balanceOf(tester2.address)).to.equal(0);

    const treasuryInitBal = await zooToken.balanceOf(treasury.address);

    await zooNftStaking
      .connect(tester1)
      .mintNft(
        tester1.address,
        nftIndex[0],
        referer1.address,
        referer2.address,
        referer3.address
      );

    await zooNftStaking
      .connect(tester2)
      .mintNft(
        tester2.address,
        nftIndex[0],
        referer1.address,
        referer2.address,
        referer3.address
      );

    // Assertions after transactions
    expect(await zooNftStaking.feeToken()).to.equal(zooToken.address);
    expect(await zooToken.balanceOf(treasury.address)).to.be.greaterThan(
      treasuryInitBal
    );
    expect(await zooNFT.balanceOf(tester1.address)).to.equal(1);
    expect(await zooNFT.balanceOf(tester2.address)).to.equal(1);
    expect(await zooToken.balanceOf(zooNftStaking.address)).to.be.greaterThan(
      0
    );
  });

  it("should stake minted nfts", async function () {
    // Approve staking contract to use your minted nft
    await zooNFT
      .connect(tester1)
      .setApprovalForAll(zooNftStaking.address, true);

    // Approve staking contract to use your minted nft
    await zooNFT
      .connect(tester2)
      .setApprovalForAll(zooNftStaking.address, true);

    const stakingInitialBal = await zooNFT.balanceOf(zooNftStaking.address);

    // Stake nft
    await zooNftStaking.connect(tester1).stake(tester1mintedTokenIds);
    timeStamp1 = (await ethers.provider.getBlock("latest")).timestamp;
    await zooNftStaking.connect(tester2).stake(tester2mintedTokenIds);

    // Assertions after transactions
    expect(await zooNFT.balanceOf(tester1.address)).to.equal(0);
    expect(await zooNFT.balanceOf(tester2.address)).to.equal(0);
    expect(await zooNFT.balanceOf(zooNftStaking.address)).to.be.greaterThan(
      stakingInitialBal
    );
    expect((await zooNftStaking.stakers(tester1.address))[1]).to.equal(
      tester1mintedTokenIds.length
    );
    expect((await zooNftStaking.stakers(tester2.address))[1]).to.equal(
      tester2mintedTokenIds.length
    );
  });

  it("should receive rewards for staked nft", async function () {
    const initialReward1 = await zooNftStaking.availableRewards(
      tester1.address
    );
    const initialReward2 = await zooNftStaking.availableRewards(
      tester1.address
    );

    // Move timestamp by 1 day
    await time.increase(86400);

    timeStamp2 = (await ethers.provider.getBlock("latest")).timestamp;
    const rewardsCalculatedPerDay =
      ((parseInt(timeStamp2) - parseInt(timeStamp1)) *
        actualRewardsPerDay[0] *
        1e6) /
      (1000 * 86400);

    // Assertions after transactions
    expect(await zooNftStaking.availableRewards(tester1.address)).to.be.equal(
      Math.floor(rewardsCalculatedPerDay)
    );

    expect(
      await zooNftStaking.availableRewards(tester1.address)
    ).to.be.greaterThan(initialReward1);
    expect(
      await zooNftStaking.availableRewards(tester2.address)
    ).to.be.greaterThan(initialReward2);
  });

  it("should not reward expired animal", async function () {
    // Increase by 29 days
    // Previous 1 day + 29 days = 30days i.e last day for reward before expiring
    await time.increase(2505600);
    const reward1 = await zooNftStaking.availableRewards(tester1.address);

    // Increase by 6 days
    await time.increase(518400);
    const reward2 = await zooNftStaking.availableRewards(tester1.address);

    expect(reward1).to.equal(reward2);
  });

  it("should feed hungry animals", async function () {
    const initTester1TokenBal = await zooToken.balanceOf(tester1.address);
    const initstakingTokenBal = await zooToken.balanceOf(zooNftStaking.address);

    // Assertions after transactions
    const isHungry = await zooNftStaking
      .connect(tester1)
      .isHungry(tester1mintedTokenIds[0]);
    await zooNftStaking
      .connect(tester1)
      .feedYourAnimal(tester1mintedTokenIds[0]);

    await zooNftStaking
      .connect(tester2)
      .feedYourAnimal(tester2mintedTokenIds[0]);

    // Increase by 30 days
    await time.increase(2592000);
    const reward1 = await zooNftStaking.availableRewards(tester1.address);

    // Increase by 5 days
    await time.increase(432000);
    const reward2 = await zooNftStaking.availableRewards(tester1.address);

    expect(reward1).to.equal(reward2);
    expect(isHungry).to.equal(true);
    expect();
    expect(await zooToken.balanceOf(tester1.address)).to.be.lessThan(
      initTester1TokenBal
    );
    expect(await zooToken.balanceOf(zooNftStaking.address)).to.be.greaterThan(
      initstakingTokenBal
    );
  });

  it("should withdraw staked nfts and claim rewards", async function () {
    const initTester1NftBal = await zooNFT.balanceOf(tester1.address);
    const initTester2NftBal = await zooNFT.balanceOf(tester2.address);
    const initTester1TokenBal = await zooToken.balanceOf(tester1.address);
    const initTester2TokenBal = await zooToken.balanceOf(tester2.address);
    await zooNftStaking.connect(tester1).withdraw(tester1mintedTokenIds);
    await zooNftStaking.connect(tester1).claimRewards();
    await zooNftStaking.connect(tester2).withdraw(tester2mintedTokenIds);
    await zooNftStaking.connect(tester2).claimRewards();

    // Assertions after transactions
    expect(await zooNFT.balanceOf(tester1.address)).to.be.greaterThan(
      initTester1NftBal
    );
    expect(await zooToken.balanceOf(tester1.address)).to.be.greaterThan(
      initTester1TokenBal
    );
    expect(await zooNFT.balanceOf(tester2.address)).to.be.greaterThan(
      initTester2NftBal
    );
    expect(await zooToken.balanceOf(tester2.address)).to.be.greaterThan(
      initTester2TokenBal
    );
  });

  it("should revert referral rewards claim without nft", async function () {
    await expect(
        zooNftStaking.connect(referer1).claimReferralRewards()
    ).to.be.revertedWith("You Need To Have ZOO Nft");
  });

  it("should claim referral rewards", async function () {
    await zooToken
      .connect(deployer)
      .transfer(referer1.address, ethers.utils.parseUnits(transferAmount, 6));

    // referer1 approve nft staking contract
    await zooToken
      .connect(referer1)
      .approve(
        zooNftStaking.address,
        ethers.utils.parseUnits(transferAmount, 6)
      );

    await zooNftStaking
      .connect(referer1)
      .mintNft(
        referer1.address,
        nftIndex[2],
        tester1.address,
        tester2.address,
        referer3.address
      );
    const initReferer1TokenBal = await zooToken.balanceOf(referer1.address);

    await zooNftStaking.connect(referer1).claimReferralRewards();

    expect(await zooToken.balanceOf(referer1.address)).to.be.greaterThan(
      initReferer1TokenBal
    );
  });

});
