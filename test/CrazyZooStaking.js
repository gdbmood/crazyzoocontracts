const { expect } = require("chai");

describe("CrazyZooStaking contract", function () {


  it("Setting addresses and fees value.", async function () {
    const [owner,addr1,addr2,addr3,addr4] = await ethers.getSigners();

    const Staking = await ethers.getContractFactory("CrazyZooStaking");

    const StakingContract = await Staking.deploy(addr4.address,addr3.address,addr2.address,addr1.address,owner.address);


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


  it("getWhaleFee should return the correct value of Fees based on rewardTokenBalance", async function () {
    const [owner,addr1,addr2,addr3,addr4] = await ethers.getSigners();

    const Staking = await ethers.getContractFactory("CrazyZooStaking");
    const Token = await ethers.getContractFactory("CrazyZooToken");

    const ZooToken = await Token.deploy();
    const ZooStaking = await Staking.deploy(addr1.address,addr2.address,addr3.address,ZooToken.address,owner.address);

    await ZooToken.connect(owner).transfer(ZooStaking.address,100000000);

    const balanceOfStaking = await ZooToken.balanceOf(ZooStaking.address);
    const ZooTokenDecimal = await ZooStaking.getZooTokenDecimal()
    const whalesWithdrawalExtraFee = await ZooStaking.getwhalesWithdrawalExtraFee()
  
    for (let i = 0; i < 10; i++) {
      const percentOfStakingDeposit = (i*ZooTokenDecimal/100) * balanceOfStaking/ZooTokenDecimal;
      var expectedFees = (i*ZooTokenDecimal / 100) * (whalesWithdrawalExtraFee*i/ZooTokenDecimal);
      if(i < 8){
        expectedFees = (i*ZooTokenDecimal / 100) * (whalesWithdrawalExtraFee*i/ZooTokenDecimal);
      } else {
        expectedFees = (i*ZooTokenDecimal / 100) * (whalesWithdrawalExtraFee*8/ZooTokenDecimal);
      }

      expect(await ZooStaking.getWhaleFee(percentOfStakingDeposit)).to.equal(expectedFees);
    }

  });

  it("calculateRewards should return the correct value of rewards based on the stakerData and stakedNFT", async function () {
    const [owner,USDCadd,SWAPadd,user1,user2] = await ethers.getSigners();

    const _token = await ethers.getContractFactory("CrazyZooToken");
    const _nft = await ethers.getContractFactory("CrazyZooNFT");
    const _testing = await ethers.getContractFactory("TestingStakingContract");
    
    const ZooToken = await _token.deploy();
    const NFT = await _nft.deploy();
    const TestingStakingContract = await _testing.deploy(NFT.address,USDCadd.address,SWAPadd.address,ZooToken.address,owner.address);
    
    const Days = 15
    await TestingStakingContract._1_testCalculateRewards(user1.address,Days);
    await NFT.setRange(1,10);
    await NFT.setFees([250000000,250000000,250000000]);

    const ZooTokenDecimal = await TestingStakingContract.getZooTokenDecimal()
    const [Lemur,Rhino,Gorilla] = await TestingStakingContract.getRewardsPerDay()
    const FeeForId =  await NFT.getFeeForId(1)

    const e_rewardRatePerDay = ((Lemur/100) * FeeForId)/ZooTokenDecimal
    const calculateRewards = await TestingStakingContract.calculateRewards(user1.address)
    const e_expectedReward = e_rewardRatePerDay *  Days

    //there is slightly difference because of epox time thats why we are using equal.
    expect(calculateRewards/ZooTokenDecimal).to.be.within(e_expectedReward/ZooTokenDecimal-0.1, e_expectedReward/ZooTokenDecimal+0.1);

  });

  it("calculateRewards should return the correct value of rewards based on the stakerData and stakedNFT. it has been morethen 30 days since the nft didn't feed", async function () {
    const [owner,USDCadd,SWAPadd,user1,user2] = await ethers.getSigners();

    const _token = await ethers.getContractFactory("CrazyZooToken");
    const _nft = await ethers.getContractFactory("CrazyZooNFT");
    const _testing = await ethers.getContractFactory("TestingStakingContract");
    
    const ZooToken = await _token.deploy();
    const NFT = await _nft.deploy();
    const TestingStakingContract = await _testing.deploy(NFT.address,USDCadd.address,SWAPadd.address,ZooToken.address,owner.address);
    
    const Days = 15
    await TestingStakingContract._2_testCalculateRewards(user1.address,Days);
    await NFT.setRange(1,10);
    await NFT.setFees([250000000,250000000,250000000]);

    const ZooTokenDecimal = await TestingStakingContract.getZooTokenDecimal()
    const [Lemur,Rhino,Gorilla] = await TestingStakingContract.getRewardsPerDay()
    const FeeForId =  await NFT.getFeeForId(1)

    const e_rewardRatePerDay = ((Lemur/100) * FeeForId)/ZooTokenDecimal
    const calculateRewards = await TestingStakingContract.calculateRewards(user1.address)
    const e_expectedReward = e_rewardRatePerDay *  Days

    //there is slightly difference because of epox time thats why we are using equal.
    expect(calculateRewards/ZooTokenDecimal).to.be.within(e_expectedReward/ZooTokenDecimal-0.1, e_expectedReward/ZooTokenDecimal+0.1);

  });

  it("calculateRewards should return 0 when expired nft has set to true", async function () {
    const [owner,USDCadd,SWAPadd,user1,user2] = await ethers.getSigners();

    const _token = await ethers.getContractFactory("CrazyZooToken");
    const _nft = await ethers.getContractFactory("CrazyZooNFT");
    const _testing = await ethers.getContractFactory("TestingStakingContract");
    
    const ZooToken = await _token.deploy();
    const NFT = await _nft.deploy();
    const TestingStakingContract = await _testing.deploy(NFT.address,USDCadd.address,SWAPadd.address,ZooToken.address,owner.address);
    
    const Days = 15
    await TestingStakingContract._2_testCalculateRewards(user1.address,Days);
    await NFT.setRange(1,10);
    await NFT.setFees([250000000,250000000,250000000]);

    const ZooTokenDecimal = await TestingStakingContract.getZooTokenDecimal()
    const [Lemur,Rhino,Gorilla] = await TestingStakingContract.getRewardsPerDay()
    const FeeForId =  await NFT.getFeeForId(1)

    const e_rewardRatePerDay = ((Lemur/100) * FeeForId)/ZooTokenDecimal
    await TestingStakingContract.testUpdateUserPool(user1.address)
    const calculateRewards = await TestingStakingContract.calculateRewards(user1.address)
    const e_expectedReward = e_rewardRatePerDay *  Days

    // console.log(calculateRewards)
    //there is slightly difference because of epox time thats why we are using equal.
    expect(calculateRewards).to.equal(0);

  });


  it("calculateRewards should return 0 when timestaked has exceed reward days", async function () {
    const [owner,USDCadd,SWAPadd,user1,user2] = await ethers.getSigners();

    const _token = await ethers.getContractFactory("CrazyZooToken");
    const _nft = await ethers.getContractFactory("CrazyZooNFT");
    const _testing = await ethers.getContractFactory("TestingStakingContract");
    
    const ZooToken = await _token.deploy();
    const NFT = await _nft.deploy();
    const TestingStakingContract = await _testing.deploy(NFT.address,USDCadd.address,SWAPadd.address,ZooToken.address,owner.address);
    
    const Days = 15
    await TestingStakingContract._3_testCalculateRewards(user1.address,Days);
    await NFT.setRange(1,10);
    await NFT.setFees([250000000,250000000,250000000]);

    const ZooTokenDecimal = await TestingStakingContract.getZooTokenDecimal()
    const [Lemur,Rhino,Gorilla] = await TestingStakingContract.getRewardsPerDay()
    const FeeForId =  await NFT.getFeeForId(1)

    const e_rewardRatePerDay = ((Lemur/100) * FeeForId)/ZooTokenDecimal
    const calculateRewards = await TestingStakingContract.calculateRewards(user1.address)
    const e_expectedReward = e_rewardRatePerDay *  Days

    // console.log(calculateRewards)
    //there is slightly difference because of epox time thats why we are using equal.
    expect(calculateRewards).to.equal(0);

  });

  it("setRewardsPerDay should set the rewardPerDay", async function () {
    const [owner,USDCadd,SWAPadd,user1,user2] = await ethers.getSigners();

    const _token = await ethers.getContractFactory("CrazyZooToken");
    const _nft = await ethers.getContractFactory("CrazyZooNFT");
    const _testing = await ethers.getContractFactory("TestingStakingContract");
    
    const ZooToken = await _token.deploy();
    const NFT = await _nft.deploy();
    const TestingStakingContract = await _testing.deploy(NFT.address,USDCadd.address,SWAPadd.address,ZooToken.address,owner.address);
    
    const Days = 15
    await TestingStakingContract._1_testCalculateRewards(user1.address,Days);
    await NFT.setRange(1,10);
    await NFT.setFees([250000000,250000000,250000000]);

    const ZooTokenDecimal = await TestingStakingContract.getZooTokenDecimal()


    const calculateRewards_berfore_setRewardsPerDay = await TestingStakingContract.calculateRewards(user1.address)

    await TestingStakingContract.setRewardsPerDay(1,500000)
    const _calculateRewards_after_setRewardsPerDay = await TestingStakingContract.calculateRewards(user1.address)
    const user1_availableReward = await TestingStakingContract.availableRewards(user1.address)
    const [lemur,rhino,gorilla] = await TestingStakingContract.getRewardsPerDay()
    

    expect(lemur).to.equal(500000)
    expect(user1_availableReward/ZooTokenDecimal).to.be.within(calculateRewards_berfore_setRewardsPerDay/ZooTokenDecimal-0.1,calculateRewards_berfore_setRewardsPerDay/ZooTokenDecimal+0.1);
    expect(_calculateRewards_after_setRewardsPerDay).to.equal(0);

  });

  it("setRewardDays should set the rewardDays.", async function () {
    const [owner,USDCadd,SWAPadd,user1,user2] = await ethers.getSigners();

    const _token = await ethers.getContractFactory("CrazyZooToken");
    const _nft = await ethers.getContractFactory("CrazyZooNFT");
    const _testing = await ethers.getContractFactory("TestingStakingContract");
    
    const ZooToken = await _token.deploy();
    const NFT = await _nft.deploy();
    const TestingStakingContract = await _testing.deploy(NFT.address,USDCadd.address,SWAPadd.address,ZooToken.address,owner.address);
    
    const Days = 15
    await TestingStakingContract._1_testCalculateRewards(user1.address,Days);
    await NFT.setRange(1,10);
    await NFT.setFees([250000000,250000000,250000000]);

    const ZooTokenDecimal = await TestingStakingContract.getZooTokenDecimal()


    const calculateRewards_berfore_setRewardsPerDay = await TestingStakingContract.calculateRewards(user1.address)

    await TestingStakingContract.setRewardDays(1,500)
    const _calculateRewards_after_setRewardsPerDay = await TestingStakingContract.calculateRewards(user1.address)
    const user1_availableReward = await TestingStakingContract.availableRewards(user1.address)
    const [lemur,rhino,gorilla] = await TestingStakingContract.getRewardDays()
    

    expect(lemur).to.equal(500)
    expect(user1_availableReward/ZooTokenDecimal).to.be.within(calculateRewards_berfore_setRewardsPerDay/ZooTokenDecimal-0.1,calculateRewards_berfore_setRewardsPerDay/ZooTokenDecimal+0.1);
    expect(_calculateRewards_after_setRewardsPerDay).to.equal(0);

  });

  it("isHungry should return false when lastTimeFed is less than 30 days.", async function () {
    const [owner,USDCadd,SWAPadd,user1,user2] = await ethers.getSigners();
  
    const _token = await ethers.getContractFactory("CrazyZooToken");
    const _nft = await ethers.getContractFactory("CrazyZooNFT");
    const _testing = await ethers.getContractFactory("TestingStakingContract");
    
    const ZooToken = await _token.deploy();
    const NFT = await _nft.deploy();
    const TestingStakingContract = await _testing.deploy(NFT.address,USDCadd.address,SWAPadd.address,ZooToken.address,owner.address);
    
    await TestingStakingContract._1_testIsHungry(user1.address);
    const Ishungry = await TestingStakingContract.isHungry(0);
    expect(Ishungry).to.equal(false);
  
  });
  
  it("isHungry should return true when lastTimeFed is greater than 30 days.", async function () {
    const [owner,USDCadd,SWAPadd,user1,user2] = await ethers.getSigners();
  
    const _token = await ethers.getContractFactory("CrazyZooToken");
    const _nft = await ethers.getContractFactory("CrazyZooNFT");
    const _testing = await ethers.getContractFactory("TestingStakingContract");
    
    const ZooToken = await _token.deploy();
    const NFT = await _nft.deploy();
    const TestingStakingContract = await _testing.deploy(NFT.address,USDCadd.address,SWAPadd.address,ZooToken.address,owner.address);
    
    await TestingStakingContract._2_testIsHungry(user1.address);
    const Ishungry = await TestingStakingContract.isHungry(0);
    expect(Ishungry).to.equal(true);
  
  });
})


// it("", async function () {
//     const [owner] = await ethers.getSigners();

//     const Staking = await ethers.getContractFactory("CrazyZooStaking");

//     const hardhatToken = await Staking.deploy();

//   });
