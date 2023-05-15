const { expect } = require("chai");
const { toWei } = require('web3-utils');


describe("CrazyZooStaking contract", function () {


  it("Setting addresses and fees value.", async function () {
    const [owner, addr1, addr2, addr3, addr4] = await ethers.getSigners();

    const Staking = await ethers.getContractFactory("CrazyZooStaking");

    const StakingContract = await Staking.deploy(addr4.address, addr3.address, addr2.address, addr1.address);


    expect(await StakingContract.getNFTAddress()).to.equal(addr4.address);
    expect(await StakingContract.getUsdcAddress()).to.equal(addr3.address);
    expect(await StakingContract.getSwapAddress()).to.equal(addr2.address);
    expect(await StakingContract.getZooAddress()).to.equal(addr1.address);


    await StakingContract.setNFTAddress(addr1.address);
    await StakingContract.setUsdcAddress(addr2.address);
    await StakingContract.setSwapAddress(addr3.address);
    await StakingContract.setZooAddress(addr4.address);
    await StakingContract.setZooTokenDecimal(10000000);
    await StakingContract.setwhalesWithdrawalExtraFee(2500000);

    expect(await StakingContract.getNFTAddress()).to.equal(addr1.address);
    expect(await StakingContract.getUsdcAddress()).to.equal(addr2.address);
    expect(await StakingContract.getSwapAddress()).to.equal(addr3.address);
    expect(await StakingContract.getZooAddress()).to.equal(addr4.address);
    expect(await StakingContract.getZooTokenDecimal()).to.equal(10000000);
    expect(await StakingContract.getwhalesWithdrawalExtraFee()).to.equal(2500000);

  });


  it("getWhaleFee should return the correct percentage of withdraw Fees. when contract has only 1 staked nft", async function () {
    const [owner, addr1, addr2, addr3, addr4] = await ethers.getSigners();

    const Staking = await ethers.getContractFactory("CrazyZooStaking");
    const Token = await ethers.getContractFactory("CrazyZooToken");
    const NFT = await ethers.getContractFactory("CrazyZooNFT");

    const ZooToken = await Token.deploy();
    const ZooStaking = await Staking.deploy(addr1.address, addr2.address, addr3.address, ZooToken.address);
    const ZooNFT = await NFT.deploy()


    await ZooNFT.setRange(1, 10);
    await ZooNFT.setFees([250000000, 250000000, 250000000]);
    const fees = await ZooNFT.getFeeForId(1)


    await ZooToken.connect(owner).transfer(ZooStaking.address, fees);
    expect(await ZooToken.balanceOf(ZooStaking.address)).to.equal(fees);
    const ZooTokenDecimal = await ZooStaking.getZooTokenDecimal()


    // if user stakef 1 nft and withdraw that nft then
    const depositAmount = fees;
    const withdrawAmount = fees;
    const BaiscWithdrawFees = await ZooStaking.getwhalesWithdrawalExtraFee()

    const percentOf_WithdrawAmount = await ZooStaking.getWhaleFee(withdrawAmount, depositAmount);
    const expecte_percentOf_WithdrawAmount = ((withdrawAmount / 100) * (BaiscWithdrawFees * 8)) / ZooTokenDecimal

    expect(percentOf_WithdrawAmount).to.equal(expecte_percentOf_WithdrawAmount);

  });

  it("getWhaleFee should return the correct percentage of withdraw Fees. ", async function () {
    const [owner, addr1, addr2, addr3, addr4] = await ethers.getSigners();

    const Staking = await ethers.getContractFactory("CrazyZooStaking");
    const Token = await ethers.getContractFactory("CrazyZooToken");
    const NFT = await ethers.getContractFactory("CrazyZooNFT");

    const ZooToken = await Token.deploy();
    const ZooStaking = await Staking.deploy(addr1.address, addr2.address, addr3.address, ZooToken.address);
    const ZooNFT = await NFT.deploy()


    await ZooNFT.setRange(1, 10);
    await ZooNFT.setFees([250000000, 250000000, 250000000]);
    const fees = await ZooNFT.getFeeForId(1)


    await ZooToken.connect(owner).transfer(ZooStaking.address, fees * 100);
    expect(await ZooToken.balanceOf(ZooStaking.address)).to.equal(fees * 100);

    const ZooTokenDecimal = await ZooStaking.getZooTokenDecimal()
    const BaiscWithdrawFees = await ZooStaking.getwhalesWithdrawalExtraFee()


    for (let i = 1; i < 8; i++) {

      const depositAmount = fees * i;
      const withdrawAmount = fees;


      const percentOf_WithdrawAmount = await ZooStaking.getWhaleFee(withdrawAmount, depositAmount);
      const expecte_percentOf_WithdrawAmount = ((withdrawAmount / 100) * (BaiscWithdrawFees * i)) / ZooTokenDecimal

      expect(percentOf_WithdrawAmount).to.equal(expecte_percentOf_WithdrawAmount);
    }

  });

  it("calculateRewards should return the correct value of rewards based on the stakerData and stakedNFT", async function () {
    const [owner, USDCadd, SWAPadd, user1, user2] = await ethers.getSigners();

    const _token = await ethers.getContractFactory("CrazyZooToken");
    const _nft = await ethers.getContractFactory("CrazyZooNFT");
    const _testing = await ethers.getContractFactory("TestingStakingContract");

    const ZooToken = await _token.deploy();
    const NFT = await _nft.deploy();
    const TestingStakingContract = await _testing.deploy(NFT.address, USDCadd.address, SWAPadd.address, ZooToken.address);

    const Days = 15
    await TestingStakingContract._1_testCalculateRewards(user1.address, Days);
    await NFT.setRange(1, 10);
    await NFT.setFees([250000000, 250000000, 250000000]);

    const ZooTokenDecimal = await TestingStakingContract.getZooTokenDecimal()
    const [Lemur, Rhino, Gorilla] = await TestingStakingContract.getRewardsPerDay()
    const FeeForId = await NFT.getFeeForId(1)

    const e_rewardRatePerDay = ((Lemur / 100) * FeeForId) / ZooTokenDecimal
    const calculateRewards = await TestingStakingContract.calculateRewards(user1.address)
    const e_expectedReward = e_rewardRatePerDay * Days

    //there is slightly difference because of epox time thats why we are using equal.
    expect(calculateRewards / ZooTokenDecimal).to.be.within(e_expectedReward / ZooTokenDecimal - 0.1, e_expectedReward / ZooTokenDecimal + 0.1);
  });

  it("calculateRewards should return the correct value of rewards based on the stakerData and stakedNFT. it has been morethen 30 days since the nft didn't feed", async function () {
    const [owner, USDCadd, SWAPadd, user1, user2] = await ethers.getSigners();

    const _token = await ethers.getContractFactory("CrazyZooToken");
    const _nft = await ethers.getContractFactory("CrazyZooNFT");
    const _testing = await ethers.getContractFactory("TestingStakingContract");

    const ZooToken = await _token.deploy();
    const NFT = await _nft.deploy();
    const TestingStakingContract = await _testing.deploy(NFT.address, USDCadd.address, SWAPadd.address, ZooToken.address);

    const Days = 15
    await TestingStakingContract._2_testCalculateRewards(user1.address, Days);
    await NFT.setRange(1, 10);
    await NFT.setFees([250000000, 250000000, 250000000]);

    const ZooTokenDecimal = await TestingStakingContract.getZooTokenDecimal()
    const [Lemur, Rhino, Gorilla] = await TestingStakingContract.getRewardsPerDay()
    const FeeForId = await NFT.getFeeForId(1)

    const e_rewardRatePerDay = ((Lemur / 100) * FeeForId) / ZooTokenDecimal
    const calculateRewards = await TestingStakingContract.calculateRewards(user1.address)
    const e_expectedReward = e_rewardRatePerDay * Days

    //there is slightly difference because of epox time thats why we are using equal.
    expect(calculateRewards / ZooTokenDecimal).to.be.within(e_expectedReward / ZooTokenDecimal - 0.1, e_expectedReward / ZooTokenDecimal + 0.1);

  });

  it("calculateRewards should return 0 when expired nft has set to true", async function () {
    const [owner, USDCadd, SWAPadd, user1, user2] = await ethers.getSigners();

    const _token = await ethers.getContractFactory("CrazyZooToken");
    const _nft = await ethers.getContractFactory("CrazyZooNFT");
    const _testing = await ethers.getContractFactory("TestingStakingContract");

    const ZooToken = await _token.deploy();
    const NFT = await _nft.deploy();
    const TestingStakingContract = await _testing.deploy(NFT.address, USDCadd.address, SWAPadd.address, ZooToken.address);

    const Days = 15
    await TestingStakingContract._2_testCalculateRewards(user1.address, Days);
    await NFT.setRange(1, 10);
    await NFT.setFees([250000000, 250000000, 250000000]);

    const ZooTokenDecimal = await TestingStakingContract.getZooTokenDecimal()
    const [Lemur, Rhino, Gorilla] = await TestingStakingContract.getRewardsPerDay()
    const FeeForId = await NFT.getFeeForId(1)

    const e_rewardRatePerDay = ((Lemur / 100) * FeeForId) / ZooTokenDecimal
    await TestingStakingContract.testUpdateUserPool(user1.address)
    const calculateRewards = await TestingStakingContract.calculateRewards(user1.address)
    const e_expectedReward = e_rewardRatePerDay * Days

    //there is slightly difference because of epox time thats why we are using equal.
    expect(calculateRewards).to.equal(0);

  });


  it("calculateRewards should return 0 when timestaked has exceed reward days", async function () {
    const [owner, USDCadd, SWAPadd, user1, user2] = await ethers.getSigners();

    const _token = await ethers.getContractFactory("CrazyZooToken");
    const _nft = await ethers.getContractFactory("CrazyZooNFT");
    const _testing = await ethers.getContractFactory("TestingStakingContract");

    const ZooToken = await _token.deploy();
    const NFT = await _nft.deploy();
    const TestingStakingContract = await _testing.deploy(NFT.address, USDCadd.address, SWAPadd.address, ZooToken.address);

    const Days = 15
    await TestingStakingContract._3_testCalculateRewards(user1.address, Days);
    await NFT.setRange(1, 10);
    await NFT.setFees([250000000, 250000000, 250000000]);

    const ZooTokenDecimal = await TestingStakingContract.getZooTokenDecimal()
    const [Lemur, Rhino, Gorilla] = await TestingStakingContract.getRewardsPerDay()
    const FeeForId = await NFT.getFeeForId(1)

    const e_rewardRatePerDay = ((Lemur / 100) * FeeForId) / ZooTokenDecimal
    const calculateRewards = await TestingStakingContract.calculateRewards(user1.address)
    const e_expectedReward = e_rewardRatePerDay * Days

    //there is slightly difference because of epox time thats why we are using equal.
    expect(calculateRewards).to.equal(0);

  });

   it("setRewardsPerDay should set the rewardPerDay", async function () {
    const [owner, USDCadd, SWAPadd, user1, user2] = await ethers.getSigners();

    const _token = await ethers.getContractFactory("CrazyZooToken");
    const _nft = await ethers.getContractFactory("CrazyZooNFT");
    const _testing = await ethers.getContractFactory("TestingStakingContract");

    const ZooToken = await _token.deploy();
    const NFT = await _nft.deploy();
    const TestingStakingContract = await _testing.deploy(NFT.address, USDCadd.address, SWAPadd.address, ZooToken.address);

    const Days = 15
    await TestingStakingContract._1_testCalculateRewards(user1.address, Days);
    await NFT.setRange(1, 10);
    await NFT.setFees([250000000, 250000000, 250000000]);

    const ZooTokenDecimal = await TestingStakingContract.getZooTokenDecimal()

    const calculateRewards_berfore_setRewardsPerDay = await TestingStakingContract.calculateRewards(user1.address)

    await TestingStakingContract.setRewardsPerDay(1, 500000)
    const _calculateRewards_after_setRewardsPerDay = await TestingStakingContract.calculateRewards(user1.address)
    const user1_availableReward = await TestingStakingContract.availableRewards(user1.address)
    const [lemur, rhino, gorilla] = await TestingStakingContract.getRewardsPerDay()


    expect(lemur).to.equal(500000)
    expect(user1_availableReward / ZooTokenDecimal).to.be.within(calculateRewards_berfore_setRewardsPerDay / ZooTokenDecimal - 0.1, calculateRewards_berfore_setRewardsPerDay / ZooTokenDecimal + 0.1);
    expect(_calculateRewards_after_setRewardsPerDay).to.equal(0);

   });

  it("setRewardDays should set the rewardDays.", async function () {
    const [owner, USDCadd, SWAPadd, user1, user2] = await ethers.getSigners();

    const _token = await ethers.getContractFactory("CrazyZooToken");
    const _nft = await ethers.getContractFactory("CrazyZooNFT");
    const _testing = await ethers.getContractFactory("TestingStakingContract");

    const ZooToken = await _token.deploy();
    const NFT = await _nft.deploy();
    const TestingStakingContract = await _testing.deploy(NFT.address, USDCadd.address, SWAPadd.address, ZooToken.address);

    const Days = 15
    await TestingStakingContract._1_testCalculateRewards(user1.address, Days);
    await NFT.setRange(1, 10);
    await NFT.setFees([250000000, 250000000, 250000000]);

    const ZooTokenDecimal = await TestingStakingContract.getZooTokenDecimal()


    const calculateRewards_berfore_setRewardsPerDay = await TestingStakingContract.calculateRewards(user1.address)

    await TestingStakingContract.setRewardDays(1, 500)
    const _calculateRewards_after_setRewardsDay = await TestingStakingContract.calculateRewards(user1.address)
    const user1_availableReward = await TestingStakingContract.availableRewards(user1.address)
    const [lemur, rhino, gorilla] = await TestingStakingContract.getRewardDays()


    expect(lemur).to.equal(500)
    expect(user1_availableReward / ZooTokenDecimal).to.be.within(calculateRewards_berfore_setRewardsPerDay / ZooTokenDecimal - 0.1, calculateRewards_berfore_setRewardsPerDay / ZooTokenDecimal + 0.1);
    expect(_calculateRewards_after_setRewardsDay).to.equal(0);

  });

  it("isHungry should return false when lastTimeFed is less than 30 days.", async function () {
    const [owner, USDCadd, SWAPadd, user1, user2] = await ethers.getSigners();

    const _token = await ethers.getContractFactory("CrazyZooToken");
    const _nft = await ethers.getContractFactory("CrazyZooNFT");
    const _testing = await ethers.getContractFactory("TestingStakingContract");

    const ZooToken = await _token.deploy();
    const NFT = await _nft.deploy();
    const TestingStakingContract = await _testing.deploy(NFT.address, USDCadd.address, SWAPadd.address, ZooToken.address);

    await TestingStakingContract._1_testIsHungry(user1.address);
    const Ishungry = await TestingStakingContract.isHungry(0);
    expect(Ishungry).to.equal(false);

  });

  it("isHungry should return true when lastTimeFed is greater than 30 days.", async function () {
    const [owner, USDCadd, SWAPadd, user1, user2] = await ethers.getSigners();

    const _token = await ethers.getContractFactory("CrazyZooToken");
    const _nft = await ethers.getContractFactory("CrazyZooNFT");
    const _testing = await ethers.getContractFactory("TestingStakingContract");

    const ZooToken = await _token.deploy();
    const NFT = await _nft.deploy();
    const TestingStakingContract = await _testing.deploy(NFT.address, USDCadd.address, SWAPadd.address, ZooToken.address);

    await TestingStakingContract._2_testIsHungry(user1.address);
    const Ishungry = await TestingStakingContract.isHungry(0);
    expect(Ishungry).to.equal(true);

  });

  it("feedYourAnimal should revert if the user has allowed staking contract to deduct fee from USDC", async function () {
    const [owner, USDCadd, SWAPadd, user1, user2] = await ethers.getSigners();

    const _token = await ethers.getContractFactory("CrazyZooToken");
    const _nft = await ethers.getContractFactory("CrazyZooNFT");
    const _usdc = await ethers.getContractFactory("MYUSDC");
    const _testing = await ethers.getContractFactory("TestingStakingContract");

    const ZooToken = await _token.deploy();
    const USDC = await _usdc.deploy();
    const NFT = await _nft.deploy();
    const TestingStakingContract = await _testing.deploy(NFT.address, USDC.address, SWAPadd.address, ZooToken.address);

    await NFT.setRange(1, 10);
    await expect(TestingStakingContract.feedYourAnimal(1)).to.be.revertedWith('Approve Staking Contract');

  });

  it("feedYourAnimal should feed the animal and relarted values should be updated as expected", async function () {
    const [owner, USDCadd, SWAPadd, user1, user2] = await ethers.getSigners();

    const _token = await ethers.getContractFactory("CrazyZooToken");
    const _nft = await ethers.getContractFactory("CrazyZooNFT");
    const _usdc = await ethers.getContractFactory("MYUSDC");
    const _testing = await ethers.getContractFactory("TestingStakingContract");

    const ZooToken = await _token.deploy();
    const USDC = await _usdc.deploy();
    const NFT = await _nft.deploy();
    const TestingStakingContract = await _testing.deploy(NFT.address, USDC.address, SWAPadd.address, ZooToken.address);

    await NFT.setRange(1, 10);
    await USDC.transfer(user1.address, toWei('3.5', 'ether'));
    await USDC.connect(user1).approve(TestingStakingContract.address, toWei('3.5', 'ether'));
    const expectedTime = Math.floor(new Date().getTime() / 1000);

    await TestingStakingContract._1_testfeedYourAnimal(user1.address)
    await TestingStakingContract.connect(user1).feedYourAnimal(1);
    const [feedCounter, time] = await TestingStakingContract._1_1_testfeedYourAnimal(user1.address);

    expect(time).to.be.at.least(expectedTime);
    expect(feedCounter).to.equal(1);
    expect(await USDC.balanceOf(TestingStakingContract.address)).to.equal(toWei('3.5', 'ether'));

  });

  it("claimReward function should update the user's balance with ZooTokens that will be equal to calculate reward + unclaimed Reward", async function () {
    const [owner, USDCadd, SWAPadd, user1, user2] = await ethers.getSigners();

    const _token = await ethers.getContractFactory("CrazyZooToken");
    const _nft = await ethers.getContractFactory("CrazyZooNFT");
    const _testing = await ethers.getContractFactory("TestingStakingContract");

    const ZooToken = await _token.deploy();
    const NFT = await _nft.deploy();
    const TestingStakingContract = await _testing.deploy(NFT.address, USDCadd.address, SWAPadd.address, ZooToken.address);

    //before claiming reward
    const Days = 15
    await TestingStakingContract._1_testClaimReward(user1.address, Days);
    await NFT.setRange(1, 10);
    await NFT.setFees([250000000, 250000000, 250000000]);


    const ZooTokenDecimal = await TestingStakingContract.getZooTokenDecimal()
    const [Lemur, Rhino, Gorilla] = await TestingStakingContract.getRewardsPerDay()
    const FeeForId = await NFT.getFeeForId(1)

    const e_rewardRatePerDay = ((Lemur / 100) * FeeForId) / ZooTokenDecimal
    const expectedReward_before_claiming = e_rewardRatePerDay * Days
    const calculateRewards_before_claiming = await TestingStakingContract.calculateRewards(user1.address)

    //after claiming reward
    await ZooToken.transfer(TestingStakingContract.address, parseInt(calculateRewards_before_claiming) + 2000000)
    await TestingStakingContract.connect(user1).claimRewards()

    const calculateRewards_after_claiming = await TestingStakingContract.calculateRewards(user1.address)
    const expectedRewards_after_claiming = 0

    const calculated_userBalance_after_claiming = await ZooToken.balanceOf(user1.address);
    const expected_userBalance_after_claiming = parseInt(calculateRewards_before_claiming) + 1000000

    // Before claiming expectedReward == calculatedReward
    expect(calculateRewards_before_claiming / ZooTokenDecimal).to.be.within(expectedReward_before_claiming / ZooTokenDecimal - 0.0001, expectedReward_before_claiming / ZooTokenDecimal + 0.0001);

    // expected User balance  == calculated user balance
    expect(calculated_userBalance_after_claiming / ZooTokenDecimal).to.be.within(expected_userBalance_after_claiming / ZooTokenDecimal - 0.0001, expected_userBalance_after_claiming / ZooTokenDecimal + 0.0001);

    // now there should be no reward
    expect(calculateRewards_after_claiming).to.equal(0);
  });

  it("Withdraw token should update the staking contract balance and user balance", async function () {
    const [owner, USDCadd, SWAPadd, user1, feeColector,user2] = await ethers.getSigners();

    const _token = await ethers.getContractFactory("CrazyZooToken");
    const _nft = await ethers.getContractFactory("CrazyZooNFT");
    const _testing = await ethers.getContractFactory("TestingStakingContract");

    const ZooToken = await _token.deploy();
    const ZooNFT = await _nft.deploy();
    const TestingStakingContract = await _testing.deploy(ZooNFT.address, USDCadd.address, SWAPadd.address, ZooToken.address);

    //minting 1 nft
    await ZooNFT.setZooToken(ZooToken.address);
    await ZooNFT.setRange(1, 10);
    await ZooNFT.setDirectMinting(true);
    await ZooNFT.setMintFeeStatus(true);
    await ZooNFT.setFees([250000000, 250000000, 250000000]);
    await ZooNFT.setFeeCollector(feeColector.address);

    await ZooToken.approve(ZooNFT.address, 250000000);

    await ZooNFT.mintLemur(user1.address);

    expect(await ZooNFT.balanceOf(user1.address)).to.equal(1);


    //staking minted nft
    const Days = 15
    await ZooNFT.connect(user1).approve(user2.address,1)
    await ZooNFT.connect(user2).transferFrom(user1.address,TestingStakingContract.address,1)
    await TestingStakingContract._1_testCalculateRewards(user1.address,Days);

    expect(await ZooNFT.balanceOf(TestingStakingContract.address)).to.equal(1);
    expect(await ZooNFT.balanceOf(user1.address)).to.equal(0);

    //withdrawing nft
    await TestingStakingContract.connect(user1).withdraw([1])

    expect(await ZooNFT.balanceOf(TestingStakingContract.address)).to.equal(0);
    expect(await ZooNFT.balanceOf(user1.address)).to.equal(1);
    expect(await TestingStakingContract.calculateRewards(user1.address)).to.equal(0);
    
  });


})


