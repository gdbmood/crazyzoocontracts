const { expect } = require("chai");

describe("CrazyZooToken contract", function () {

  it("Deployment should assign the total supply of tokens to the owner", async function () {
    const [owner] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("CrazyZooToken");

    const hardhatToken = await Token.deploy();

    const ownerBalance = await hardhatToken.balanceOf(owner.address);
    expect(await hardhatToken.totalSupply()).to.equal(ownerBalance);

  });

  it("Token decimal should return 6", async function () {
    const [owner] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("CrazyZooToken");

    const hardhatToken = await Token.deploy();

    const ownerBalance = await hardhatToken.decimals();
    expect(ownerBalance).to.equal(6);

  });

  it("myReferrer should return 0 address ", async function () {
    const [owner] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("CrazyZooToken");

    const hardhatToken = await Token.deploy();

    const myReferrer = await hardhatToken.referrer(owner.address);
    expect(myReferrer).to.equal('0x0000000000000000000000000000000000000000');

  });

  it("getFeeCollectors should return 0 addresses", async function () {
    const [owner] = await ethers.getSigners();
  
    const Token = await ethers.getContractFactory("CrazyZooToken");
  
    const hardhatToken = await Token.deploy();
    // const [stakingContractAddress, marketingWallet] = await hardhatToken.getFeeCollectors();
    const stakingContractAddress = await hardhatToken.StakingContractAddress();
    const marketingWallet = await hardhatToken.marketingWallet();
    const zeroAddress = '0x0000000000000000000000000000000000000000';
    
    expect(stakingContractAddress).to.equal(zeroAddress);
    expect(marketingWallet).to.equal(zeroAddress);
    /*
    */
  });

  it("getFee should return 1500000,1500000 and 3000000 ", async function () {
    const [owner] = await ethers.getSigners();
  
    const Token = await ethers.getContractFactory("CrazyZooToken");
  
    const hardhatToken = await Token.deploy();
    // const [StakingFee, MarketingFee, ReferrarFee] = await hardhatToken.getFees();
    const StakingFee = await hardhatToken.StakingFee();
    const MarketingFee = await hardhatToken.MarketingFee();
    const ReferrarFee = await hardhatToken.ReferrarFee();
    
    expect(StakingFee).to.equal(1500000);
    expect(MarketingFee).to.equal(1500000);
    expect(ReferrarFee).to.equal(3000000);
    /*
    **/
  });

  it("Fees should set to 3000000,3000000 and 1500000 ", async function () {
    const [owner] = await ethers.getSigners();
  
    const Token = await ethers.getContractFactory("CrazyZooToken");
  
    const hardhatToken = await Token.deploy();
  
    await hardhatToken.setReferralFee(1500000);
    await hardhatToken.setStakingFee(3000000);
    await hardhatToken.setMarketingFee(3000000);

    // const [StakingFee, MarketingFee, ReferrarFee] = await hardhatToken.getFees();
    const StakingFee = await hardhatToken.StakingFee();
    const MarketingFee = await hardhatToken.MarketingFee();
    const ReferrarFee = await hardhatToken.ReferrarFee();
    
    expect(StakingFee).to.equal(3000000);
    expect(MarketingFee).to.equal(3000000);
    expect(ReferrarFee).to.equal(1500000);
    /*
    **/
  });

  it("setReferralFee should revert for 0 value", async function () {
    const zeroReferralFee = 0;
    
    const [owner] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("CrazyZooToken");

    const hardhatToken = await Token.deploy();

    await expect(hardhatToken.setReferralFee(zeroReferralFee)).to.be.revertedWith('ReferralFee must be greater than 0');

  });

  it("setReferralFee should set the ReferralFee to 5000000", async function () {
    
    const [owner] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("CrazyZooToken");

    const hardhatToken = await Token.deploy();

    await hardhatToken.setReferralFee(5000000);

    const ReferrarFee = await hardhatToken.ReferrarFee();
    
    expect(ReferrarFee).to.equal(5000000);
  });
  
  it("setReferralFee should be reverted for OnlyOwner", async function () {
    const zeroReferralFee = 0;
    
    const [owner, addr1, addr2] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("CrazyZooToken");

    const hardhatToken = await Token.deploy();

    await expect(hardhatToken.connect(addr1).setReferralFee(zeroReferralFee)).to.be.reverted;
  });

  it("setStakingFee should revert for 0 value", async function () {
    const zeroReferralFee = 0;
    
    const [owner] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("CrazyZooToken");

    const hardhatToken = await Token.deploy();

    await expect(hardhatToken.setStakingFee(zeroReferralFee)).to.be.revertedWith('StakingFee must be greater than 0');

  });

  it("setStakingFee should set the StakingFee to 5000000", async function () {
    
    const [owner] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("CrazyZooToken");

    const hardhatToken = await Token.deploy();

    await hardhatToken.setStakingFee(5000000);

    const StakingFee = await hardhatToken.StakingFee();
    
    expect(StakingFee).to.equal(5000000);
  });
  
  it("setStakingFee should be reverted for OnlyOwner", async function () {
    const zeroReferralFee = 0;
    
    const [owner, addr1, addr2] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("CrazyZooToken");

    const hardhatToken = await Token.deploy();

    await expect(hardhatToken.connect(addr1).setStakingFee(zeroReferralFee)).to.be.reverted;
  });

  it("setMarketingFee should revert for 0 value", async function () {
    const zeroReferralFee = 0;
    
    const [owner] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("CrazyZooToken");

    const hardhatToken = await Token.deploy();

    await expect(hardhatToken.setMarketingFee(zeroReferralFee)).to.be.revertedWith('MarketingFee must be greater than 0');

  });

  it("setMarketingFee should set the StakingFee to 5000000", async function () {
    
    const [owner] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("CrazyZooToken");

    const hardhatToken = await Token.deploy();

    await hardhatToken.setMarketingFee(5000000);

    const MarketingFee = await hardhatToken.MarketingFee();
    
    expect(MarketingFee).to.equal(5000000);
  });
  
  it("setMarketingFee should be reverted for OnlyOwner", async function () {
    const zeroReferralFee = 0;
    
    const [owner, addr1, addr2] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("CrazyZooToken");

    const hardhatToken = await Token.deploy();

    await expect(hardhatToken.connect(addr1).setMarketingFee(zeroReferralFee)).to.be.reverted;
  });

  it("setMarketingWallet and setStakingContractAddress should set the MarketingWallet to add1 and add2 respectively", async function () {
    
    const [owner, addr1, addr2] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("CrazyZooToken");

    const hardhatToken = await Token.deploy();

    await hardhatToken.setMarketingWallet(addr1.address);
    await hardhatToken.setStakingContractAddress(addr2.address);

    const StakingContractAddress = await hardhatToken.StakingContractAddress();
    const marketingWallet = await hardhatToken.marketingWallet();

    expect(marketingWallet).to.equal(addr1.address);
    expect(StakingContractAddress).to.equal(addr2.address);
  });

  it("setMarketingWallet and setStakingContractAddress should be reverted for OnlyOwner", async function () {
    
    const [owner, addr1, addr2] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("CrazyZooToken");

    const hardhatToken = await Token.deploy();

    await expect(hardhatToken.connect(addr1).setMarketingWallet(addr1.address)).to.be.reverted;
    await expect(hardhatToken.connect(addr1).setStakingContractAddress(addr2.address)).to.be.reverted;

  });

  it("setMarketingWallet and setStakingContractAddress should be reverted for 0 address", async function () {
    
    const [owner, addr1, addr2] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("CrazyZooToken");

    const hardhatToken = await Token.deploy();

    await expect(hardhatToken.setMarketingWallet('0x0000000000000000000000000000000000000000')).to.be.revertedWith('you are setting 0 address');
    await expect(hardhatToken.setStakingContractAddress('0x0000000000000000000000000000000000000000')).to.be.revertedWith('you are setting 0 address');

  });



  it("setMinter should set the PoolAddress to add1 ", async function () {
    const [owner, addr1, addr2] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("CrazyZooToken");

    const hardhatToken = await Token.deploy();

    await hardhatToken.setMinter(addr1.address);

    expect(await hardhatToken.isMinter(addr1.address)).to.be.true;
  });


  it("setMinter should revert for 0 address ", async function () {
    const [owner, addr1, addr2] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("CrazyZooToken");

    const hardhatToken = await Token.deploy();

    await expect(hardhatToken.setMinter('0x0000000000000000000000000000000000000000')).to.be.revertedWith('you are setting 0 address');

  });


  it("setMinter should be reverted for OnlyOwner", async function () {
    
    const [owner, addr1, addr2] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("CrazyZooToken");

    const hardhatToken = await Token.deploy();

    await expect(hardhatToken.connect(addr1).setMinter(addr1.address)).to.be.reverted;

  });


  it("isMinter should return false ", async function () {
    const [owner, addr1, addr2] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("CrazyZooToken");

    const hardhatToken = await Token.deploy();

    expect(await hardhatToken.isMinter(addr1.address)).to.be.false;
  });

  it("SetReferral should set address of referrer to add1 and refferal to add2 ", async function () {
    const [owner, addr1, addr2] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("CrazyZooToken");

    const hardhatToken = await Token.deploy();

    await hardhatToken.SetReferral(addr1.address,owner.address);

    // expect(await hardhatToken.myReferrer(owner.address)).to.equal(addr1.address);
    expect(await hardhatToken.referrer(owner.address)).to.equal(addr1.address);
    // expect(await hardhatToken.myReferrals(addr1.address)).to.deep.equal([owner.address]);
    expect(await hardhatToken.allReferrals(addr1.address)).to.deep.equal([owner.address]);
  });

  it("SetReferral should revert for 0 addresses ", async function () {
    const [owner, addr1, addr2] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("CrazyZooToken");

    const hardhatToken = await Token.deploy();

    await expect(hardhatToken.SetReferral('0x0000000000000000000000000000000000000000','0x0000000000000000000000000000000000000000')).to.be.revertedWith('referrer is undefined');

  });

  it("SetReferral should revert for same refferer and refferal addresses ", async function () {
    const [owner, addr1, addr2] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("CrazyZooToken");

    const hardhatToken = await Token.deploy();

    await expect(hardhatToken.SetReferral(owner.address,owner.address)).to.be.revertedWith('You can not be your own referral');

  });

  it("SetReferral should revert for refferal has alreagy got a refferal ", async function () {
    const [owner, addr1, addr2] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("CrazyZooToken");

    const hardhatToken = await Token.deploy();

    await hardhatToken.SetReferral(addr1.address,owner.address);

    await expect(hardhatToken.SetReferral(addr1.address,owner.address)).to.be.revertedWith('person you are referring has already got a referrer');

  });


  it("isDeprecated should return false ", async function () {
    const [owner, addr1, addr2] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("CrazyZooToken");

    const hardhatToken = await Token.deploy();

    expect(await hardhatToken.deprecated()).to.be.false;
  });

  it("isDeprecated should return true ", async function () {
    const [owner, addr1, addr2] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("CrazyZooToken");

    const hardhatToken = await Token.deploy();

    await hardhatToken.deprecate(addr1.address);

    expect(await hardhatToken.deprecated()).to.be.true;
  });


  it("deprecate should set the upgradedAddress to addr1 ", async function () {
    const [owner, addr1, addr2] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("CrazyZooToken");

    const hardhatToken = await Token.deploy();

    await hardhatToken.deprecate(addr1.address);

    expect(await hardhatToken.upgradedAddress()).to.equal(addr1.address);
  });


  it("deprecate should reverted for OnlyOwner ", async function () {
    const [owner, addr1, addr2] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("CrazyZooToken");

    const hardhatToken = await Token.deploy();

    await expect(hardhatToken.connect(addr1).deprecate(addr1.address)).to.be.reverted;

  });

  it("deprecate should reverted for 0 address ", async function () {
    const [owner, addr1, addr2] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("CrazyZooToken");

    const hardhatToken = await Token.deploy();

    await expect(hardhatToken.deprecate("0x0000000000000000000000000000000000000000")).to.be.revertedWith('upgradedAddress is undefined');

  });


  it("approve should set the spender to addr1 and amount to 10 ZooToken ", async function () {
    const [owner, addr1, addr2] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("CrazyZooToken");

    const hardhatToken = await Token.deploy();

    await hardhatToken.approve(addr1.address,10000000);

    expect(await hardhatToken.allowance(owner.address,addr1.address)).to.equal(10000000);
  });

  it("approve should be reverted for 0 value ", async function () {
    const [owner, addr1, addr2] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("CrazyZooToken");

    const hardhatToken = await Token.deploy();

    expect(await hardhatToken.approve(addr1.address,0)).to.be.reverted;
  });

  it("_calculateFee should return 0 fees. msg.sender is owner ", async function () {
    const [owner, addr1, addr2] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("CrazyZooToken");

    const hardhatToken = await Token.deploy();

    const [StakingFees,MarketingFee,ReferrerFee,fee] = await hardhatToken._calculateFee(addr2.address,10000000);

    expect(StakingFees).to.equal(0)
    expect(MarketingFee).to.equal(0)
    expect(ReferrerFee).to.equal(0)
    expect(fee).to.equal(0)

  });

  it("_calculateFee should return 0 fees. StakingContractAddress is msg.sender ", async function () {
    const [owner, addr1, addr2] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("CrazyZooToken");

    const hardhatToken = await Token.deploy();

    await hardhatToken.setStakingContractAddress(addr2.address);

    const [StakingFees,MarketingFee,ReferrerFee,fee] = await hardhatToken.connect(addr2)._calculateFee(addr2.address,10000000);

    expect(StakingFees).to.equal(0)
    expect(MarketingFee).to.equal(0)
    expect(ReferrerFee).to.equal(0)
    expect(fee).to.equal(0)

  });

  it("_calculateFee should return 0 fees. marketingWallet is msg.sender ", async function () {
    const [owner, addr1, addr2] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("CrazyZooToken");

    const hardhatToken = await Token.deploy();

    await hardhatToken.setMarketingWallet(addr1.address);

    const [StakingFees,MarketingFee,ReferrerFee,fee] = await hardhatToken.connect(addr1)._calculateFee(addr1.address,10000000);

    expect(StakingFees).to.equal(0)
    expect(MarketingFee).to.equal(0)
    expect(ReferrerFee).to.equal(0)
    expect(fee).to.equal(0)

  });


  
  it("_calculateFee should return (150000,150000,0,300000). UniswapAddres[_from] ", async function () {
    const [owner, addr1, addr2] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("CrazyZooToken");

    const hardhatToken = await Token.deploy();


    const [StakingFees,MarketingFee,ReferrerFee,fee] = await hardhatToken.connect(addr1)._calculateFee(addr1.address,10000000);

    expect(StakingFees).to.equal(150000)
    expect(MarketingFee).to.equal(150000)
    expect(ReferrerFee).to.equal(0)
    expect(fee).to.equal(300000)

  });

  it("transfer should update the balance of addr1 ", async function () {
    const [owner, addr1, addr2] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("CrazyZooToken");

    const hardhatToken = await Token.deploy();

    await hardhatToken.transfer(addr1.address,20000000);

    expect(await hardhatToken.balanceOf(addr1.address)).to.equal(20000000);

  });



  it("transferFrom should update the balance of addr1 ", async function () {
    const [owner, addr1, addr2, addr3] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("CrazyZooToken");

    const hardhatToken = await Token.deploy();

    await hardhatToken.transfer(addr1.address,20000000);
    
    await hardhatToken.connect(addr1).approve(addr2.address,10000000);

    await hardhatToken.connect(addr2).transferFrom(addr1.address,addr3.address,10000000);

    expect(await hardhatToken.balanceOf(addr1.address)).to.equal(10000000);
    expect(await hardhatToken.balanceOf(addr3.address)).to.equal(10000000);

  });

  
});