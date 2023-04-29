const { expect } = require("chai");
const { toWei } = require('web3-utils');

describe("PreSale contract", function () {


  it("startPreSale should start the PreSale and set the values", async function () {
    const [owner, collectorWallet] = await ethers.getSigners();

    const PresaleContract = await ethers.getContractFactory("PreSale");
    const Token = await ethers.getContractFactory("CrazyZooToken");
    const _usdc = await ethers.getContractFactory("MYUSDC");

    const ZooToken = await Token.deploy();
    const USDT = await _usdc.deploy();
    const PreSale = await PresaleContract.deploy();

    await PreSale.startPreSale(
      collectorWallet.address,
      100000000,
      toWei('10', 'ether'),
      toWei('10', 'ether'),
      15000000,
      1687817973,
      ZooToken.address,
      USDT.address
    )

    const events = await PreSale.queryFilter("_startPreSale");
    // Check that there is one emitted event
    expect(events[0].args.collectorWallet).to.equal(collectorWallet.address);
    expect(events[0].args.cap).to.equal(100000000);
    expect(events[0].args.rate).to.equal(toWei('10', 'ether'));
    expect(events[0].args.minInvestment).to.equal(toWei('10', 'ether'));
    expect(events[0].args.reffererFee).to.equal(15000000);
    expect(events[0].args.endTime).to.equal(1687817973);

  });


  it("startPreSale should be reverted for _collectorWallet != address(0)", async function () {
    const [owner, _collectorWallet] = await ethers.getSigners();

    const PresaleContract = await ethers.getContractFactory("PreSale");
    const Token = await ethers.getContractFactory("CrazyZooToken");
    const _usdc = await ethers.getContractFactory("MYUSDC");

    const ZooToken = await Token.deploy();
    const USDT = await _usdc.deploy();
    const Presale = await PresaleContract.deploy();

    await expect(
      Presale.startPreSale(
        '0x0000000000000000000000000000000000000000',
        100000000,
        toWei('10', 'ether'),
        toWei('10', 'ether'),
        15000000,
        1687817973,
        ZooToken.address,
        USDT.address
      )
    ).to.be.reverted;

  });

  it("startPreSale should be reverted for _rate > 0", async function () {
    const [owner, collectorWallet] = await ethers.getSigners();

    const PresaleContract = await ethers.getContractFactory("PreSale");
    const Token = await ethers.getContractFactory("CrazyZooToken");
    const _usdc = await ethers.getContractFactory("MYUSDC");

    const ZooToken = await Token.deploy();
    const USDT = await _usdc.deploy();
    const Presale = await PresaleContract.deploy();

    await expect(
      Presale.startPreSale(
        collectorWallet.address,
        100000000,
        0,
        toWei('10', 'ether'),
        15000000,
        1687817973,
        ZooToken.address,
        USDT.address
      )
    ).to.be.reverted;

  });

  it("startPreSale should be reverted for _minInvestment >= _rate", async function () {
    const [owner, collectorWallet] = await ethers.getSigners();

    const PresaleContract = await ethers.getContractFactory("PreSale");
    const Token = await ethers.getContractFactory("CrazyZooToken");
    const _usdc = await ethers.getContractFactory("MYUSDC");

    const ZooToken = await Token.deploy();
    const USDT = await _usdc.deploy();
    const Presale = await PresaleContract.deploy();

    await expect(
      Presale.startPreSale(
        collectorWallet.address,
        100000000,
        toWei('10', 'ether'),
        toWei('9', 'ether'),
        15000000,
        1687817973,
        ZooToken.address,
        USDT.address
      )
    ).to.be.reverted;

  });

  it("changeCollectorWallet should set the CollectorWallet when it is not zero address", async function () {
    const [owner, collectorWallet] = await ethers.getSigners();

    const PresaleContract = await ethers.getContractFactory("PreSale");
    const Token = await ethers.getContractFactory("CrazyZooToken");
    const _usdc = await ethers.getContractFactory("MYUSDC");

    const ZooToken = await Token.deploy();
    const USDT = await _usdc.deploy();
    const PreSale = await PresaleContract.deploy();

    await PreSale.startPreSale(
      collectorWallet.address,
      100000000,
      toWei('10', 'ether'),
      toWei('10', 'ether'),
      15000000,
      1687817973,
      ZooToken.address,
      USDT.address
    )

    const events = await PreSale.queryFilter("_startPreSale");

    // Check that there is one emitted event
    expect(events[0].args.collectorWallet).to.equal(collectorWallet.address);
    expect(events[0].args.cap).to.equal(100000000);
    expect(events[0].args.rate).to.equal(toWei('10', 'ether'));
    expect(events[0].args.minInvestment).to.equal(toWei('10', 'ether'));
    expect(events[0].args.reffererFee).to.equal(15000000);
    expect(events[0].args.endTime).to.equal(1687817973);

    await PreSale.changeCollectorWallet(owner.address);

    const event = await PreSale.queryFilter("_changeCollectorWallet");

    expect(event[0].args.collectorWallet).to.equal(owner.address);
  });

  it("changeReffererFee should set the ReffererFee when it is not zero", async function () {
    const [owner, collectorWallet] = await ethers.getSigners();

    const PresaleContract = await ethers.getContractFactory("PreSale");
    const Token = await ethers.getContractFactory("CrazyZooToken");
    const _usdc = await ethers.getContractFactory("MYUSDC");

    const ZooToken = await Token.deploy();
    const USDT = await _usdc.deploy();
    const PreSale = await PresaleContract.deploy();

    await PreSale.startPreSale(
      collectorWallet.address,
      100000000,
      toWei('10', 'ether'),
      toWei('10', 'ether'),
      15000000,
      1687817973,
      ZooToken.address,
      USDT.address
    )

    const events = await PreSale.queryFilter("_startPreSale");

    // Check that there is one emitted event
    expect(events[0].args.collectorWallet).to.equal(collectorWallet.address);
    expect(events[0].args.cap).to.equal(100000000);
    expect(events[0].args.rate).to.equal(toWei('10', 'ether'));
    expect(events[0].args.minInvestment).to.equal(toWei('10', 'ether'));
    expect(events[0].args.reffererFee).to.equal(15000000);
    expect(events[0].args.endTime).to.equal(1687817973);

    await PreSale.changeReffererFee(20000000);

    const event = await PreSale.queryFilter("_changeReffererFee");

    expect(event[0].args.reffererFee).to.equal(20000000);



  });

  
  it("changeCap should the set cap value when it is not zero and greater the the mintedTokens", async function () {
    const [owner, collectorWallet] = await ethers.getSigners();

    const PresaleContract = await ethers.getContractFactory("PreSale");
    const Token = await ethers.getContractFactory("CrazyZooToken");
    const _usdc = await ethers.getContractFactory("MYUSDC");

    const ZooToken = await Token.deploy();
    const USDT = await _usdc.deploy();
    const PreSale = await PresaleContract.deploy();

    await PreSale.startPreSale(
      collectorWallet.address,
      100000000,
      toWei('10', 'ether'),
      toWei('10', 'ether'),
      15000000,
      1687817973,
      ZooToken.address,
      USDT.address
    )

    const events = await PreSale.queryFilter("_startPreSale");
    // console.log(events[0].args.cap)
    // Check that there is one emitted event
    expect(events[0].args.collectorWallet).to.equal(collectorWallet.address);
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
    const [owner, collectorWallet] = await ethers.getSigners();

    const PresaleContract = await ethers.getContractFactory("PreSale");
    const Token = await ethers.getContractFactory("CrazyZooToken");
    const _usdc = await ethers.getContractFactory("MYUSDC");

    const ZooToken = await Token.deploy();
    const USDT = await _usdc.deploy();
    const PreSale = await PresaleContract.deploy();

    await PreSale.startPreSale(
      collectorWallet.address,
      100000000,
      toWei('10', 'ether'),
      toWei('10', 'ether'),
      15000000,
      1687817973,
      ZooToken.address,
      USDT.address
    )

    const events = await PreSale.queryFilter("_startPreSale");
    // console.log(events[0].args.cap)
    // Check that there is one emitted event
    expect(events[0].args.collectorWallet).to.equal(collectorWallet.address);
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
    const [owner, collectorWallet] = await ethers.getSigners();

    const PresaleContract = await ethers.getContractFactory("PreSale");
    const Token = await ethers.getContractFactory("CrazyZooToken");
    const _usdc = await ethers.getContractFactory("MYUSDC");

    const ZooToken = await Token.deploy();
    const USDT = await _usdc.deploy();
    const PreSale = await PresaleContract.deploy();

    await PreSale.startPreSale(
      collectorWallet.address,
      100000000,
      toWei('10', 'ether'),
      toWei('10', 'ether'),
      15000000,
      1687817973,
      ZooToken.address,
      USDT.address
    )

    const events = await PreSale.queryFilter("_startPreSale");
    // console.log(events[0].args.cap)
    // Check that there is one emitted event
    expect(events[0].args.collectorWallet).to.equal(collectorWallet.address);
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
    const [owner, collectorWallet, beneficiary] = await ethers.getSigners();

    const PresaleContract = await ethers.getContractFactory("PreSale");
    const Token = await ethers.getContractFactory("CrazyZooToken");
    const _usdc = await ethers.getContractFactory("MYUSDC");

    const ZooToken = await Token.deploy();
    const USDT = await _usdc.deploy();
    const PreSale = await PresaleContract.deploy();

    await PreSale.startPreSale(
      collectorWallet.address,
      100000000,
      toWei('10', 'ether'),
      toWei('10', 'ether'),
      15000000,
      1687817973,
      ZooToken.address,
      USDT.address
    )

    const events = await PreSale.queryFilter("_startPreSale");

    // Check that there is one emitted event
    expect(events[0].args.collectorWallet).to.equal(collectorWallet.address);
    expect(events[0].args.cap).to.equal(100000000);
    expect(events[0].args.rate).to.equal(toWei('10', 'ether'));
    expect(events[0].args.minInvestment).to.equal(toWei('10', 'ether'));
    expect(events[0].args.reffererFee).to.equal(15000000);
    expect(events[0].args.endTime).to.equal(1687817973);
    
    await ZooToken.setMinter(PreSale.address);
    await USDT.transfer(beneficiary.address,toWei('10', 'ether'));
    await USDT.connect(beneficiary).approve(PreSale.address,toWei('10', 'ether'));
    await PreSale.buyZooTokens(beneficiary.address, toWei('10', 'ether'));
    
    expect(await ZooToken.balanceOf(beneficiary.address)).to.equal(1000000);
    expect(await USDT.balanceOf(collectorWallet.address)).to.equal(toWei('10', 'ether'));
  
  });

  it("buyZooTokens should  apply the reffere fee and mint the tokens to refferer and beneficiary", async function () {
    const [owner, collectorWallet, beneficiary, refferer] = await ethers.getSigners();

    const PresaleContract = await ethers.getContractFactory("PreSale");
    const Token = await ethers.getContractFactory("CrazyZooToken");
    const _usdc = await ethers.getContractFactory("MYUSDC");

    const ZooToken = await Token.deploy();
    const USDT = await _usdc.deploy();
    const PreSale = await PresaleContract.deploy();

    await PreSale.startPreSale(
      collectorWallet.address,
      100000000,
      toWei('10', 'ether'),
      toWei('10', 'ether'),
      15000000,
      1687817973,
      ZooToken.address,
      USDT.address
    )

    const events = await PreSale.queryFilter("_startPreSale");

    // Check that there is one emitted event
    expect(events[0].args.collectorWallet).to.equal(collectorWallet.address);
    expect(events[0].args.cap).to.equal(100000000);
    expect(events[0].args.rate).to.equal(toWei('10', 'ether'));
    expect(events[0].args.minInvestment).to.equal(toWei('10', 'ether'));
    expect(events[0].args.reffererFee).to.equal(15000000);
    expect(events[0].args.endTime).to.equal(1687817973);
    
    await ZooToken.SetReferral(refferer.address,beneficiary.address);
    await ZooToken.setMinter(PreSale.address);
    await USDT.transfer(beneficiary.address,toWei('10', 'ether'));
    await USDT.connect(beneficiary).approve(PreSale.address,toWei('10', 'ether'));
    
    await PreSale.buyZooTokens(beneficiary.address, toWei('10', 'ether'));
    
    expect(await ZooToken.balanceOf(beneficiary.address)).to.equal(850000);
    expect(await ZooToken.balanceOf(refferer.address)).to.equal(150000);
    expect(await USDT.balanceOf(collectorWallet.address)).to.equal(toWei('10', 'ether'));
  
  });


  it("buyZooTokens should revert the transaction for exceeding the cap", async function () {
    const [owner, collectorWallet, beneficiary, refferer] = await ethers.getSigners();

    const PresaleContract = await ethers.getContractFactory("PreSale");
    const Token = await ethers.getContractFactory("CrazyZooToken");
    const _usdc = await ethers.getContractFactory("MYUSDC");

    const ZooToken = await Token.deploy();
    const USDT = await _usdc.deploy();
    const PreSale = await PresaleContract.deploy();

    await PreSale.startPreSale(
      collectorWallet.address,
      100000000,
      toWei('10', 'ether'),
      toWei('10', 'ether'),
      15000000,
      1687817973,
      ZooToken.address,
      USDT.address
    )

    const events = await PreSale.queryFilter("_startPreSale");

    // Check that there is one emitted event
    expect(events[0].args.collectorWallet).to.equal(collectorWallet.address);
    expect(events[0].args.cap).to.equal(100000000);
    expect(events[0].args.rate).to.equal(toWei('10', 'ether'));
    expect(events[0].args.minInvestment).to.equal(toWei('10', 'ether'));
    expect(events[0].args.reffererFee).to.equal(15000000);
    expect(events[0].args.endTime).to.equal(1687817973);
        
    await expect(
      PreSale.buyZooTokens(beneficiary.address, toWei('1100', 'ether'))
    ).to.be.revertedWith("you are exceeding the cap");
    
  });
})
