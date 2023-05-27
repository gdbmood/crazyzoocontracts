const { expect } = require("chai");
const { toWei } = require('web3-utils');

describe("PreSale contract", function () {

  const addressZero = '0x0000000000000000000000000000000000000000'

  it("test final purchase", async function () {
    const [owner, liquidityWallet, teamWallet, marketingWallet, slipageFeeWallet, beneficiary, refferer] = await ethers.getSigners();

    const PresaleContract = await ethers.getContractFactory("PreSale");
    const Token = await ethers.getContractFactory("CrazyZooToken");
    const _usdc = await ethers.getContractFactory("MYUSDC");

    const ZooToken = await Token.deploy({gasLimit:6721975});
    const USDT = await _usdc.deploy({gasLimit:6721975});
    const PreSale = await PresaleContract.deploy({gasLimit:6721975});

    await PreSale.startPreSale(
      liquidityWallet.address,
      teamWallet.address,
      marketingWallet.address,
      slipageFeeWallet.address,
      100000000,
      toWei('10', 'ether'),
      toWei('10', 'ether'),
      toWei('1000000', 'ether'),
      15000000,
      1687817973,
      ZooToken.address,
      USDT.address,
      {gasLimit:6721975}
    )

    const events = await PreSale.queryFilter("_startPreSale");

    // await ZooToken.SetReferral(refferer.address,beneficiary.address, {gasLimit:6721975});
    await ZooToken.setMinter(PreSale.address, {gasLimit:6721975});
    await USDT.connect(owner).transfer(beneficiary.address,toWei('10', 'ether'), {gasLimit:6721975});
    await USDT.connect(beneficiary).approve(PreSale.address,toWei('10', 'ether'), {gasLimit:6721975});
    
    await PreSale.connect(beneficiary).buyZooTokens(beneficiary.address, refferer.address, '10000000000000000000', {gasLimit:6721975});
    
    
  });

  
  it("startPreSale should start the PreSale and set the values", async function () {
    const [owner, liquidityWallet, teamWallet, marketingWallet, slipageFeeWallet] = await ethers.getSigners();

    const PresaleContract = await ethers.getContractFactory("PreSale");
    const Token = await ethers.getContractFactory("CrazyZooToken");
    const _usdc = await ethers.getContractFactory("MYUSDC");

    const ZooToken = await Token.deploy();
    const USDT = await _usdc.deploy();
    const PreSale = await PresaleContract.deploy();

    await PreSale.startPreSale(
      liquidityWallet.address,
      teamWallet.address,
      marketingWallet.address,
      slipageFeeWallet.address,
      100000000,
      toWei('10', 'ether'),
      toWei('10', 'ether'),
      toWei('1000000', 'ether'),
      15000000,
      1687817973,
      ZooToken.address,
      USDT.address
    )

    const events = await PreSale.queryFilter("_startPreSale");
    // Check that there is one emitted event
    expect(events[0].args.liquidityWallet).to.equal(liquidityWallet.address);
    expect(events[0].args.teamWallet).to.equal(teamWallet.address);
    expect(events[0].args.marketingWallet).to.equal(marketingWallet.address);
    expect(events[0].args.slipageFeeWallet).to.equal(slipageFeeWallet.address);
    expect(events[0].args.cap).to.equal(100000000);
    expect(events[0].args.rate).to.equal(toWei('10', 'ether'));
    expect(events[0].args.minInvestment).to.equal(toWei('10', 'ether'));
    expect(events[0].args.reffererFee).to.equal(15000000);
    expect(events[0].args.endTime).to.equal(1687817973);

  });


  it("startPreSale should be reverted for _collectorWallet != address(0)", async function () {
    const [owner, liquidityWallet, teamWallet, marketingWallet, slipageFeeWallet] = await ethers.getSigners();

    const PresaleContract = await ethers.getContractFactory("PreSale");
    const Token = await ethers.getContractFactory("CrazyZooToken");
    const _usdc = await ethers.getContractFactory("MYUSDC");

    const ZooToken = await Token.deploy({gasLimit:30000000});
    const USDT = await _usdc.deploy({gasLimit:30000000});
    const Presale = await PresaleContract.deploy({gasLimit:30000000});

    await expect(
      Presale.startPreSale(
        '0x0000000000000000000000000000000000000000',
        teamWallet.address,
        marketingWallet.address,
        slipageFeeWallet.address,
        100000000,
        toWei('10', 'ether'),
        toWei('10', 'ether'),
        toWei('1000000', 'ether'),
        15000000,
        1687817973,
        ZooToken.address,
        USDT.address,
        {gasLimit:30000000}
      )
    ).to.be.reverted;

  });

  it("startPreSale should be reverted for _rate > 0", async function () {
    const [owner, liquidityWallet, teamWallet, marketingWallet, slipageFeeWallet] = await ethers.getSigners();

    const PresaleContract = await ethers.getContractFactory("PreSale");
    const Token = await ethers.getContractFactory("CrazyZooToken");
    const _usdc = await ethers.getContractFactory("MYUSDC");

    const ZooToken = await Token.deploy({gasLimit:30000000});
    const USDT = await _usdc.deploy({gasLimit:30000000});
    const Presale = await PresaleContract.deploy({gasLimit:30000000});

    await expect(
      Presale.startPreSale(
        liquidityWallet.address,
        teamWallet.address,
        marketingWallet.address,
        slipageFeeWallet.address,
        100000000,
        0,
        toWei('10', 'ether'),
        toWei('10000000', 'ether'),
        15000000,
        1687817973,
        ZooToken.address,
        USDT.address,
        {gasLimit:30000000}
      )
    ).to.be.reverted;

  });

  it("startPreSale should be reverted for _minInvestment >= _rate", async function () {
    const [owner, liquidityWallet, teamWallet, marketingWallet, slipageFeeWallet] = await ethers.getSigners();

    const PresaleContract = await ethers.getContractFactory("PreSale");
    const Token = await ethers.getContractFactory("CrazyZooToken");
    const _usdc = await ethers.getContractFactory("MYUSDC");

    const ZooToken = await Token.deploy({gasLimit:30000000});
    const USDT = await _usdc.deploy({gasLimit:30000000});
    const Presale = await PresaleContract.deploy({gasLimit:30000000});

    await expect(
      Presale.startPreSale(
        liquidityWallet.address,
        teamWallet.address,
        marketingWallet.address,
        slipageFeeWallet.address,
        100000000,
        toWei('10', 'ether'),//rate
        toWei('9', 'ether'),//min amount
        toWei('1000000', 'ether'),//max amount
        15000000,
        1687817973,
        ZooToken.address,
        USDT.address,
        {gasLimit:30000000}
      )
    ).to.be.reverted;

  });

  it("changeCollectorWallet should set the CollectorWallet when it is not zero address", async function () {
    const [owner, user1, user2, user3, liquidityWallet, teamWallet, marketingWallet, slipageFeeWallet] = await ethers.getSigners();

    const PresaleContract = await ethers.getContractFactory("PreSale");
    const Token = await ethers.getContractFactory("CrazyZooToken");
    const _usdc = await ethers.getContractFactory("MYUSDC");

    const ZooToken = await Token.deploy({gasLimit:30000000});
    const USDT = await _usdc.deploy({gasLimit:30000000});
    const PreSale = await PresaleContract.deploy({gasLimit:30000000});

    await PreSale.startPreSale(
      liquidityWallet.address,
      teamWallet.address,
      marketingWallet.address,
      slipageFeeWallet.address,
      100000000,
      toWei('10', 'ether'),//rate
      toWei('10', 'ether'),//min amount
      toWei('1000000', 'ether'),//max amount
      15000000,
      1687817973,
      ZooToken.address,
      USDT.address
    )

    const events = await PreSale.queryFilter("_startPreSale");

    // Check that there is one emitted event
    expect(events[0].args.liquidityWallet).to.equal(liquidityWallet.address);
    expect(events[0].args.teamWallet).to.equal(teamWallet.address);
    expect(events[0].args.marketingWallet).to.equal(marketingWallet.address);
    expect(events[0].args.slipageFeeWallet).to.equal(slipageFeeWallet.address);
    expect(events[0].args.cap).to.equal(100000000);
    expect(events[0].args.rate).to.equal(toWei('10', 'ether'));
    expect(events[0].args.minInvestment).to.equal(toWei('10', 'ether'));
    expect(events[0].args.reffererFee).to.equal(15000000);
    expect(events[0].args.endTime).to.equal(1687817973);

    await PreSale.changeLiquidityWallet(owner.address);
    await PreSale.changeTeamWallet(user1.address);
    await PreSale.changeMarketingWallet(user2.address);
    await PreSale.changeSlipageFeeWallet(user3.address);

    const event = await PreSale.queryFilter("_changeLiquidityWallet");
    const event1 = await PreSale.queryFilter("_changeTeamWallet");
    const event2 = await PreSale.queryFilter("_changeMarketingWallet");
    const event3 = await PreSale.queryFilter("_changeSlipageFeeWallet");

    expect(event[0].args.liquidityWallet).to.equal(owner.address);
    expect(event1[0].args.teamWallet).to.equal(user1.address);
    expect(event2[0].args.marketingWallet).to.equal(user2.address);
    expect(event3[0].args.slipageFeeWallet).to.equal(user3.address);

    //test changing share percent
    expect(Number(await PreSale.liquiditySharePercent())).to.be.equal(600);
    expect(Number(await PreSale.teamSharePercent())).to.be.equal(100);
    expect(Number(await PreSale.marketingSharePercent())).to.be.equal(235);
    expect(Number(await PreSale.slipageFeeSharePercent())).to.be.equal(65);
    
    await PreSale.changeWalletsShare(
      '500', //liquidity
      '300', //team
      '150', //marketing
      '50', //slipage
    );
    expect(Number(await PreSale.liquiditySharePercent())).to.be.equal(500);
    expect(Number(await PreSale.teamSharePercent())).to.be.equal(300);
    expect(Number(await PreSale.marketingSharePercent())).to.be.equal(150);
    expect(Number(await PreSale.slipageFeeSharePercent())).to.be.equal(50);
  });

  it("changeReffererFee should set the ReffererFee when it is not zero", async function () {
    const [owner, liquidityWallet, teamWallet, marketingWallet, slipageFeeWallet] = await ethers.getSigners();

    const PresaleContract = await ethers.getContractFactory("PreSale");
    const Token = await ethers.getContractFactory("CrazyZooToken");
    const _usdc = await ethers.getContractFactory("MYUSDC");

    const ZooToken = await Token.deploy({gasLimit:30000000});
    const USDT = await _usdc.deploy({gasLimit:30000000});
    const PreSale = await PresaleContract.deploy({gasLimit:30000000});

    await PreSale.startPreSale(
      liquidityWallet.address,
      teamWallet.address,
      marketingWallet.address,
      slipageFeeWallet.address,
      100000000,
      toWei('10', 'ether'),//rate
      toWei('10', 'ether'),//min amount
      toWei('1000000', 'ether'),//max amount
      15000000,
      1687817973,
      ZooToken.address,
      USDT.address,
      {gasLimit:30000000}
    )

    const events = await PreSale.queryFilter("_startPreSale");

    // Check that there is one emitted event
    expect(events[0].args.liquidityWallet).to.equal(liquidityWallet.address);
    expect(events[0].args.teamWallet).to.equal(teamWallet.address);
    expect(events[0].args.marketingWallet).to.equal(marketingWallet.address);
    expect(events[0].args.slipageFeeWallet).to.equal(slipageFeeWallet.address);
    expect(events[0].args.cap).to.equal(100000000);
    expect(events[0].args.rate).to.equal(toWei('10', 'ether'));
    expect(events[0].args.minInvestment).to.equal(toWei('10', 'ether'));
    expect(events[0].args.reffererFee).to.equal(15000000);
    expect(events[0].args.endTime).to.equal(1687817973);

    await PreSale.changeReffererFee(20000000, {gasLimit:30000000});

    const event = await PreSale.queryFilter("_changeReffererFee");

    expect(event[0].args.reffererFee).to.equal(20000000);



  });

  
  it("changeCap should the set cap value when it is not zero and greater the the mintedTokens", async function () {
    const [owner, liquidityWallet, teamWallet, marketingWallet, slipageFeeWallet] = await ethers.getSigners();

    const PresaleContract = await ethers.getContractFactory("PreSale");
    const Token = await ethers.getContractFactory("CrazyZooToken");
    const _usdc = await ethers.getContractFactory("MYUSDC");

    const ZooToken = await Token.deploy();
    const USDT = await _usdc.deploy();
    const PreSale = await PresaleContract.deploy();

    await PreSale.startPreSale(
      liquidityWallet.address,
      teamWallet.address,
      marketingWallet.address,
      slipageFeeWallet.address,
      100000000,
      toWei('10', 'ether'),//rate
      toWei('10', 'ether'),//min amount
      toWei('1000000', 'ether'),//max amount
      15000000,
      1687817973,
      ZooToken.address,
      USDT.address
    )

    const events = await PreSale.queryFilter("_startPreSale");
    // console.log(events[0].args.cap)
    // Check that there is one emitted event
    expect(events[0].args.liquidityWallet).to.equal(liquidityWallet.address);
    expect(events[0].args.teamWallet).to.equal(teamWallet.address);
    expect(events[0].args.marketingWallet).to.equal(marketingWallet.address);
    expect(events[0].args.slipageFeeWallet).to.equal(slipageFeeWallet.address);
    expect(events[0].args.cap).to.equal(100000000);
    expect(events[0].args.rate).to.equal(toWei('10', 'ether'));
    expect(events[0].args.minInvestment).to.equal(toWei('10', 'ether'));
    expect(events[0].args.reffererFee).to.equal(15000000);
    expect(events[0].args.endTime).to.equal(1687817973);

    await PreSale.changeCap(99000000);

    const event0 = await PreSale.queryFilter("_changeCap");

    expect(event0[0].args.cap).to.equal(99000000);


  });

  it("changeMinInvestment should set the minInvestment when it is greater then or equal to rate", async function () {
    const [owner, liquidityWallet, teamWallet, marketingWallet, slipageFeeWallet] = await ethers.getSigners();

    const PresaleContract = await ethers.getContractFactory("PreSale");
    const Token = await ethers.getContractFactory("CrazyZooToken");
    const _usdc = await ethers.getContractFactory("MYUSDC");

    const ZooToken = await Token.deploy();
    const USDT = await _usdc.deploy();
    const PreSale = await PresaleContract.deploy();

    await PreSale.startPreSale(
      liquidityWallet.address,
      teamWallet.address,
      marketingWallet.address,
      slipageFeeWallet.address,
      100000000,
      toWei('10', 'ether'),
      toWei('10', 'ether'),
      toWei('1000000', 'ether'),
      15000000,
      1687817973,
      ZooToken.address,
      USDT.address
    )

    const events = await PreSale.queryFilter("_startPreSale");
    // console.log(events[0].args.cap)
    // Check that there is one emitted event
    expect(events[0].args.liquidityWallet).to.equal(liquidityWallet.address);
    expect(events[0].args.teamWallet).to.equal(teamWallet.address);
    expect(events[0].args.marketingWallet).to.equal(marketingWallet.address);
    expect(events[0].args.slipageFeeWallet).to.equal(slipageFeeWallet.address);
    expect(events[0].args.cap).to.equal(100000000);
    expect(events[0].args.rate).to.equal(toWei('10', 'ether'));
    expect(events[0].args.minInvestment).to.equal(toWei('10', 'ether'));
    expect(events[0].args.reffererFee).to.equal(15000000);
    expect(events[0].args.endTime).to.equal(1687817973);

    await PreSale.changeMinInvestment(toWei('15', 'ether'));

    const event0 = await PreSale.queryFilter("_changeMinInvestment");

    expect(event0[0].args.minInvestment).to.equal(toWei('15', 'ether'));


  });

  it("changeMinInvestment should revert the transaction when it is less than rate", async function () {
    const [owner, liquidityWallet, teamWallet, marketingWallet, slipageFeeWallet] = await ethers.getSigners();

    const PresaleContract = await ethers.getContractFactory("PreSale");
    const Token = await ethers.getContractFactory("CrazyZooToken");
    const _usdc = await ethers.getContractFactory("MYUSDC");

    const ZooToken = await Token.deploy();
    const USDT = await _usdc.deploy();
    const PreSale = await PresaleContract.deploy();

    await PreSale.startPreSale(
      liquidityWallet.address,
      teamWallet.address,
      marketingWallet.address,
      slipageFeeWallet.address,
      100000000,
      toWei('10', 'ether'),
      toWei('10', 'ether'),
      toWei('1000000', 'ether'),
      15000000,
      1687817973,
      ZooToken.address,
      USDT.address
    )

    const events = await PreSale.queryFilter("_startPreSale");
    // console.log(events[0].args.cap)
    // Check that there is one emitted event
    expect(events[0].args.liquidityWallet).to.equal(liquidityWallet.address);
    expect(events[0].args.teamWallet).to.equal(teamWallet.address);
    expect(events[0].args.marketingWallet).to.equal(marketingWallet.address);
    expect(events[0].args.slipageFeeWallet).to.equal(slipageFeeWallet.address);
    expect(events[0].args.cap).to.equal(100000000);
    expect(events[0].args.rate).to.equal(toWei('10', 'ether'));
    expect(events[0].args.minInvestment).to.equal(toWei('10', 'ether'));
    expect(events[0].args.reffererFee).to.equal(15000000);
    expect(events[0].args.endTime).to.equal(1687817973);


    await expect(
      PreSale.changeMinInvestment(toWei('9', 'ether'))
    ).to.be.reverted;

  });

  it("buyZooTokens should not apply the reffere fee and mint the tokens only to beneficiary", async function () {
    const [owner, liquidityWallet, marketingWallet, teamWallet, slipageFeeWallet, beneficiary, refferer] = await ethers.getSigners();

    const PresaleContract = await ethers.getContractFactory("PreSale");
    const Token = await ethers.getContractFactory("CrazyZooToken");
    const _usdc = await ethers.getContractFactory("MYUSDC");

    const ZooToken = await Token.deploy();
    const USDT = await _usdc.deploy();
    const PreSale = await PresaleContract.deploy();

    await PreSale.startPreSale(
      liquidityWallet.address,
      teamWallet.address,
      marketingWallet.address,
      slipageFeeWallet.address,
      100000000,
      toWei('10', 'ether'),
      toWei('10', 'ether'),
      toWei('1000000', 'ether'),
      15000000,
      1687817973,
      ZooToken.address,
      USDT.address
    )

    const events = await PreSale.queryFilter("_startPreSale");

    // Check that there is one emitted event
    expect(events[0].args.liquidityWallet).to.equal(liquidityWallet.address);
    expect(events[0].args.teamWallet).to.equal(teamWallet.address);
    expect(events[0].args.marketingWallet).to.equal(marketingWallet.address);
    expect(events[0].args.slipageFeeWallet).to.equal(slipageFeeWallet.address);
    expect(events[0].args.cap).to.equal(100000000);
    expect(events[0].args.rate).to.equal(toWei('10', 'ether'));
    expect(events[0].args.minInvestment).to.equal(toWei('10', 'ether'));
    expect(events[0].args.reffererFee).to.equal(15000000);
    expect(events[0].args.endTime).to.equal(1687817973);
    
    await ZooToken.setMinter(PreSale.address);
    await USDT.transfer(beneficiary.address,toWei('10', 'ether'));
    await USDT.connect(beneficiary).approve(PreSale.address,toWei('10', 'ether'));
    await PreSale.buyZooTokens(beneficiary.address, addressZero, toWei('10', 'ether'));
    
    expect(await ZooToken.balanceOf(beneficiary.address)).to.equal(1000000);
    expect(await USDT.balanceOf(liquidityWallet.address)).to.equal(toWei('6', 'ether'));
    expect(await USDT.balanceOf(teamWallet.address)).to.equal(toWei('1', 'ether'));
    expect(await USDT.balanceOf(marketingWallet.address)).to.equal(toWei('2.35', 'ether'));
    expect(await USDT.balanceOf(slipageFeeWallet.address)).to.equal(toWei('0.65', 'ether'));
  
  });

  it("buyZooTokens should  apply the reffere fee and mint the tokens to refferer and beneficiary", async function () {
    const [owner, liquidityWallet, teamWallet, marketingWallet, slipageFeeWallet, beneficiary, refferer] = await ethers.getSigners();

    const PresaleContract = await ethers.getContractFactory("PreSale");
    const Token = await ethers.getContractFactory("CrazyZooToken");
    const _usdc = await ethers.getContractFactory("MYUSDC");

    const ZooToken = await Token.deploy();
    const USDT = await _usdc.deploy();
    const PreSale = await PresaleContract.deploy();

    await PreSale.startPreSale(
      liquidityWallet.address,
      teamWallet.address,
      marketingWallet.address,
      slipageFeeWallet.address,
      100000000,
      toWei('10', 'ether'),
      toWei('10', 'ether'),
      toWei('1000000', 'ether'),
      15000000,
      1687817973,
      ZooToken.address,
      USDT.address
    )

    const events = await PreSale.queryFilter("_startPreSale");

    // Check that there is one emitted event
    expect(events[0].args.liquidityWallet).to.equal(liquidityWallet.address);
    expect(events[0].args.teamWallet).to.equal(teamWallet.address);
    expect(events[0].args.marketingWallet).to.equal(marketingWallet.address);
    expect(events[0].args.slipageFeeWallet).to.equal(slipageFeeWallet.address);
    expect(events[0].args.cap).to.equal(100000000);
    expect(events[0].args.rate).to.equal(toWei('10', 'ether'));
    expect(events[0].args.minInvestment).to.equal(toWei('10', 'ether'));
    expect(events[0].args.reffererFee).to.equal(15000000);
    expect(events[0].args.endTime).to.equal(1687817973);
    
    // await ZooToken.SetReferral(refferer.address,beneficiary.address);
    await ZooToken.setMinter(PreSale.address);
    await USDT.transfer(beneficiary.address,toWei('10', 'ether'));
    await USDT.connect(beneficiary).approve(PreSale.address,toWei('10', 'ether'));
    
    await PreSale.connect(beneficiary).buyZooTokens(beneficiary.address, refferer.address, toWei('10', 'ether'));
    
    expect(await ZooToken.balanceOf(beneficiary.address)).to.equal(850000);
    expect(Number(await ZooToken.balanceOf(refferer.address))).to.equal(150000);
    expect(await USDT.balanceOf(liquidityWallet.address)).to.equal(toWei('6', 'ether'));
    expect(await USDT.balanceOf(teamWallet.address)).to.equal(toWei('1', 'ether'));
    expect(await USDT.balanceOf(marketingWallet.address)).to.equal(toWei('2.35', 'ether'));
    expect(await USDT.balanceOf(slipageFeeWallet.address)).to.equal(toWei('0.65', 'ether'));
  
  });


  it("buyZooTokens should revert the transaction for exceeding the cap", async function () {
    const [owner, liquidityWallet, teamWallet, marketingWallet, slipageFeeWallet, beneficiary, refferer] = await ethers.getSigners();

    const PresaleContract = await ethers.getContractFactory("PreSale");
    const Token = await ethers.getContractFactory("CrazyZooToken");
    const _usdc = await ethers.getContractFactory("MYUSDC");

    const ZooToken = await Token.deploy();
    const USDT = await _usdc.deploy();
    const PreSale = await PresaleContract.deploy();

    await PreSale.startPreSale(
      liquidityWallet.address,
      teamWallet.address,
      marketingWallet.address,
      slipageFeeWallet.address,
      100000000,
      toWei('10', 'ether'),
      toWei('10', 'ether'),
      toWei('1000000', 'ether'),
      15000000,
      1687817973,
      ZooToken.address,
      USDT.address
    )

    const events = await PreSale.queryFilter("_startPreSale");

    // Check that there is one emitted event
    expect(events[0].args.liquidityWallet).to.equal(liquidityWallet.address);
    expect(events[0].args.teamWallet).to.equal(teamWallet.address);
    expect(events[0].args.marketingWallet).to.equal(marketingWallet.address);
    expect(events[0].args.slipageFeeWallet).to.equal(slipageFeeWallet.address);
    expect(events[0].args.cap).to.equal(100000000);
    expect(events[0].args.rate).to.equal(toWei('10', 'ether'));
    expect(events[0].args.minInvestment).to.equal(toWei('10', 'ether'));
    expect(events[0].args.reffererFee).to.equal(15000000);
    expect(events[0].args.endTime).to.equal(1687817973);
        
    await expect(
      PreSale.buyZooTokens(beneficiary.address, refferer.address, toWei('1100', 'ether'))
    ).to.be.revertedWith("you are exceeding the cap");
    
  });


  it("test final purchase", async function () {
    const [owner, liquidityWallet, teamWallet, marketingWallet, slipageFeeWallet, beneficiary, refferer] = await ethers.getSigners();

    const PresaleContract = await ethers.getContractFactory("PreSale");
    const Token = await ethers.getContractFactory("CrazyZooToken");
    const _usdc = await ethers.getContractFactory("MYUSDC");

    const ZooToken = await Token.deploy();
    const USDT = await _usdc.deploy();
    const PreSale = await PresaleContract.deploy();

    await PreSale.startPreSale(
      liquidityWallet.address,
      teamWallet.address,
      marketingWallet.address,
      slipageFeeWallet.address,
      100000000,
      toWei('10', 'ether'),
      toWei('10', 'ether'),
      toWei('1000000', 'ether'),
      15000000,
      1687817973,
      ZooToken.address,
      USDT.address
    )

    const events = await PreSale.queryFilter("_startPreSale");

    // await ZooToken.SetReferral(refferer.address,beneficiary.address);
    await ZooToken.setMinter(PreSale.address);
    await USDT.transfer(beneficiary.address,toWei('10', 'ether'));
    await USDT.connect(beneficiary).approve(PreSale.address,toWei('10', 'ether'));
    
    await PreSale.connect(beneficiary).buyZooTokens(beneficiary.address, refferer.address, '10000000000000000000');
    
    expect(await USDT.balanceOf(liquidityWallet.address)).to.equal(toWei('6', 'ether'));
    expect(await USDT.balanceOf(teamWallet.address)).to.equal(toWei('1', 'ether'));
    expect(await USDT.balanceOf(marketingWallet.address)).to.equal(toWei('2.35', 'ether'));
    expect(await USDT.balanceOf(slipageFeeWallet.address)).to.equal(toWei('0.65', 'ether'));
  });
})
