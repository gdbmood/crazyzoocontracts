const { expect } = require("chai");

describe("CrazyZooNFT contract", function () {
    
    it("setRange should set the id range", async function () {
        
        const [owner] = await ethers.getSigners();
    
        const Token = await ethers.getContractFactory("CrazyZooNFT");
    
        const hardhatToken = await Token.deploy();
    
        await hardhatToken.setRange(1,10);

        expect(await hardhatToken.getIndexForId(1)).to.equal(1);
        expect(await hardhatToken.getIndexForId(11)).to.equal(2);
        expect(await hardhatToken.getIndexForId(21)).to.equal(3);
    });

    it("setFees should set the fee", async function () {
        
        const [owner] = await ethers.getSigners();
    
        const Token = await ethers.getContractFactory("CrazyZooNFT");
    
        const hardhatToken = await Token.deploy();
    
        await hardhatToken.setFees([100,200,300]);

        await hardhatToken.setRange(1,10);

        expect(await hardhatToken.getFeeForId(1)).to.equal(100);
        expect(await hardhatToken.getFeeForId(11)).to.equal(200);
        expect(await hardhatToken.getFeeForId(21)).to.equal(300);
    });

    it("setDirectMinting should set the DirectMinting to true", async function () {
        
        const [owner, addr1] = await ethers.getSigners();
    
        const Token = await ethers.getContractFactory("CrazyZooNFT");
    
        const hardhatToken = await Token.deploy();
    
        await hardhatToken.setDirectMinting(true);

        expect(await hardhatToken.getDirectMinting()).to.be.true;
    });

    it("setDirectMinting should set the DirectMinting to false", async function () {
        
        const [owner, addr1] = await ethers.getSigners();
    
        const Token = await ethers.getContractFactory("CrazyZooNFT");
    
        const hardhatToken = await Token.deploy();
    
        await hardhatToken.setDirectMinting(false);

        expect(await hardhatToken.getDirectMinting()).to.be.false;
    });

    it("setMintFeeStatus should set the DirectMinting to true", async function () {
        
        const [owner, addr1] = await ethers.getSigners();
    
        const Token = await ethers.getContractFactory("CrazyZooNFT");
    
        const hardhatToken = await Token.deploy();
    
        await hardhatToken.setMintFeeStatus(true);

        expect(await hardhatToken.getMintFeeStatus()).to.be.true;
    });

    it("setMintFeeStatus should set the DirectMinting to false", async function () {
        
        const [owner, addr1] = await ethers.getSigners();
    
        const Token = await ethers.getContractFactory("CrazyZooNFT");
    
        const hardhatToken = await Token.deploy();
    
        await hardhatToken.setMintFeeStatus(false);

        expect(await hardhatToken.getMintFeeStatus()).to.be.false;
    });

    it("setFeeCollector should set the FeeCollectorAddress", async function () {
        
        const [owner, addr1] = await ethers.getSigners();
    
        const Token = await ethers.getContractFactory("CrazyZooNFT");
    
        const hardhatToken = await Token.deploy();
    
        await hardhatToken.setFeeCollector(addr1.address);

        expect(await hardhatToken.getFeeCollector()).to.equal(addr1.address);
    });
    it("setFeeCollector should be reverted for setting 0 address", async function () {
        
        const [owner, addr1] = await ethers.getSigners();
    
        const Token = await ethers.getContractFactory("CrazyZooNFT");
    
        const hardhatToken = await Token.deploy();

        await expect(hardhatToken.setFeeCollector('0x0000000000000000000000000000000000000000')).to.be.revertedWith('Collector Can Not Be Zero Address');

    });
    it("setFeeCollector should be reverted for onlyRole", async function () {
        
        const [owner, addr1] = await ethers.getSigners();
    
        const Token = await ethers.getContractFactory("CrazyZooNFT");
    
        const hardhatToken = await Token.deploy();
        
        await expect(hardhatToken.connect(addr1).setFeeCollector('0x0000000000000000000000000000000000000000')).to.be.reverted;


    });

    it("transferFee should update the balance of feeCollector", async function () {
        
        const [owner, addr1, feeColector, add2] = await ethers.getSigners();
    
        const NFT = await ethers.getContractFactory("CrazyZooNFT");
        const Token = await ethers.getContractFactory("CrazyZooToken");
        
        const ZooToken = await Token.deploy();
        const ZooNFT = await NFT.deploy();
        

        await ZooNFT.setZooToken(ZooToken.address);
        await ZooToken.approve(ZooNFT.address,250000000);

        await ZooNFT.transferFee(owner.address,feeColector.address,250000000);

        expect(await ZooToken.balanceOf(feeColector.address)).to.equal(250000000);

    });

    it("transferFee should be reverted for 0 address", async function () {
        
        const [owner, addr1, feeColector, add2] = await ethers.getSigners();
    
        const NFT = await ethers.getContractFactory("CrazyZooNFT");
        const Token = await ethers.getContractFactory("CrazyZooToken");
        
        const ZooToken = await Token.deploy();
        const ZooNFT = await NFT.deploy();
        

        await ZooNFT.setZooToken(ZooToken.address);
        await ZooToken.approve(ZooNFT.address,250000000);

        
        await expect(ZooNFT.transferFee(owner.address,'0x0000000000000000000000000000000000000000',250000000)).to.be.revertedWith('Can Not Transfer To Zero Address');

    });

    it("transferFee should be reverted for 0 amount", async function () {
        
        const [owner, addr1, feeColector, add2] = await ethers.getSigners();
    
        const NFT = await ethers.getContractFactory("CrazyZooNFT");
        const Token = await ethers.getContractFactory("CrazyZooToken");
        
        const ZooToken = await Token.deploy();
        const ZooNFT = await NFT.deploy();
        

        await ZooNFT.setZooToken(ZooToken.address);
        await ZooToken.approve(ZooNFT.address,250000000);

        await expect(ZooNFT.transferFee(owner.address,feeColector.address,0)).to.not.emit(ZooNFT, 'Transfer');

    });

    it("mintLemur should mint the LemurId", async function () {
        
        const [owner, addr1, feeColector, add2] = await ethers.getSigners();
    
        const NFT = await ethers.getContractFactory("CrazyZooNFT");
        const Token = await ethers.getContractFactory("CrazyZooToken");
        
        const ZooToken = await Token.deploy();
        const ZooNFT = await NFT.deploy();
        
        await ZooNFT.setZooToken(ZooToken.address);
        await ZooNFT.setRange(1,10);
        await ZooNFT.setDirectMinting(true);
        await ZooNFT.setMintFeeStatus(true);
        await ZooNFT.setFees([250000000,250000000,250000000]);
        await ZooNFT.setFeeCollector(feeColector.address);
        
        await ZooToken.transfer(addr1.address,2500000000);
        await ZooToken.connect(addr1).approve(ZooNFT.address,2500000000);

        for (let i = 1; i < 11; i++) {
            await ZooNFT.connect(addr1).mintLemur(add2.address);
        }

        expect(await ZooToken.balanceOf(feeColector.address)).to.equal(2500000000);
        expect(await ZooNFT.balanceOf(add2.address)).to.equal(10);

    });

    it("mintLemur should mint the LemurId for Minter Role", async function () {
        
        const [owner, addr1, feeColector, add2] = await ethers.getSigners();
    
        const NFT = await ethers.getContractFactory("CrazyZooNFT");
        const Token = await ethers.getContractFactory("CrazyZooToken");
        
        const ZooToken = await Token.deploy();
        const ZooNFT = await NFT.deploy();
        
        await ZooNFT.setZooToken(ZooToken.address);
        await ZooNFT.setRange(1,10);
        await ZooNFT.setDirectMinting(true);
        await ZooNFT.setMintFeeStatus(true);
        await ZooNFT.setFees([250000000,250000000,250000000]);
        await ZooNFT.setFeeCollector(feeColector.address);
        
        await ZooToken.approve(ZooNFT.address,250000000);

        await ZooNFT.mintLemur(add2.address);

        expect(await ZooToken.balanceOf(feeColector.address)).to.equal(0);
        expect(await ZooNFT.balanceOf(add2.address)).to.equal(1);


    });

    it("mintLemur should be reverted when directMint is disabled", async function () {
        
        const [owner, addr1, feeColector, add2] = await ethers.getSigners();
    
        const NFT = await ethers.getContractFactory("CrazyZooNFT");
        const Token = await ethers.getContractFactory("CrazyZooToken");
        
        const ZooToken = await Token.deploy();
        const ZooNFT = await NFT.deploy();
        
        await ZooNFT.setZooToken(ZooToken.address);
        await ZooNFT.setRange(1,10);
        await ZooNFT.setDirectMinting(false);
        await ZooNFT.setMintFeeStatus(true);
        await ZooNFT.setFees([250000000,250000000,250000000]);
        await ZooNFT.setFeeCollector(feeColector.address);
        
        await ZooToken.transfer(addr1.address,250000000);
        await ZooToken.connect(addr1).approve(ZooNFT.address,250000000);

        await expect(ZooNFT.connect(addr1).mintLemur(add2.address)).to.be.revertedWith('You Can Not Mint Now');

    });

    it("mintLemur should mint the LemurId when chargeFeeOnMint is false", async function () {
        
        const [owner, addr1, feeColector, add2] = await ethers.getSigners();
    
        const NFT = await ethers.getContractFactory("CrazyZooNFT");
        const Token = await ethers.getContractFactory("CrazyZooToken");
        
        const ZooToken = await Token.deploy();
        const ZooNFT = await NFT.deploy();
        
        await ZooNFT.setZooToken(ZooToken.address);
        await ZooNFT.setRange(1,10);
        await ZooNFT.setDirectMinting(true);
        await ZooNFT.setMintFeeStatus(false);
        await ZooNFT.setFees([250000000,250000000,250000000]);
        await ZooNFT.setFeeCollector(feeColector.address);
        
        await ZooNFT.connect(addr1).mintLemur(add2.address);

        expect(await ZooToken.balanceOf(feeColector.address)).to.equal(0);
        expect(await ZooNFT.balanceOf(add2.address)).to.equal(1);

    });

    it("mintLemur should be reverted for lemurIdCounter <= lemurMaxId", async function () {
        
        const [owner, addr1, feeColector, add2] = await ethers.getSigners();
    
        const NFT = await ethers.getContractFactory("CrazyZooNFT");
        const Token = await ethers.getContractFactory("CrazyZooToken");
        
        const ZooToken = await Token.deploy();
        const ZooNFT = await NFT.deploy();
        
        await ZooNFT.setZooToken(ZooToken.address);
        await ZooNFT.setRange(1,10);
        await ZooNFT.setDirectMinting(true);
        await ZooNFT.setMintFeeStatus(true);
        await ZooNFT.setFees([250000000,250000000,250000000]);
        await ZooNFT.setFeeCollector(feeColector.address);
        
        await ZooToken.transfer(addr1.address,2500000000);
        await ZooToken.connect(addr1).approve(ZooNFT.address,2500000000);

        for (let i = 1; i <= 11; i++) {
            if(i==11){
                await expect(ZooNFT.connect(addr1).mintLemur(add2.address)).to.be.revertedWith('No more Lemurs available for minting');
            } else {
               await ZooNFT.connect(addr1).mintLemur(add2.address);
            }
        }
    });

    it("mintRhino should mint the RhinoId", async function () {
        
        const [owner, addr1, feeColector, add2] = await ethers.getSigners();
    
        const NFT = await ethers.getContractFactory("CrazyZooNFT");
        const Token = await ethers.getContractFactory("CrazyZooToken");
        
        const ZooToken = await Token.deploy();
        const ZooNFT = await NFT.deploy();
        
        await ZooNFT.setZooToken(ZooToken.address);
        await ZooNFT.setRange(1,10);
        await ZooNFT.setDirectMinting(true);
        await ZooNFT.setMintFeeStatus(true);
        await ZooNFT.setFees([250000000,250000000,250000000]);
        await ZooNFT.setFeeCollector(feeColector.address);
        
        await ZooToken.transfer(addr1.address,2500000000);
        await ZooToken.connect(addr1).approve(ZooNFT.address,2500000000);

        for (let i = 1; i < 11; i++) {
            await ZooNFT.connect(addr1).mintRhino(add2.address);
        }

        expect(await ZooToken.balanceOf(feeColector.address)).to.equal(2500000000);
        expect(await ZooNFT.balanceOf(add2.address)).to.equal(10);
        expect(6).to.equal(6);

    });

    it("mintRhino should mint the RhinoId for Minter Role", async function () {
        
        const [owner, addr1, feeColector, add2] = await ethers.getSigners();
    
        const NFT = await ethers.getContractFactory("CrazyZooNFT");
        const Token = await ethers.getContractFactory("CrazyZooToken");
        
        const ZooToken = await Token.deploy();
        const ZooNFT = await NFT.deploy();
        
        await ZooNFT.setZooToken(ZooToken.address);
        await ZooNFT.setRange(1,10);
        await ZooNFT.setDirectMinting(true);
        await ZooNFT.setMintFeeStatus(true);
        await ZooNFT.setFees([250000000,250000000,250000000]);
        await ZooNFT.setFeeCollector(feeColector.address);
        
        await ZooToken.approve(ZooNFT.address,250000000);

        await ZooNFT.mintRhino(add2.address);

        expect(await ZooToken.balanceOf(feeColector.address)).to.equal(0);
        expect(await ZooNFT.balanceOf(add2.address)).to.equal(1);


    });

    it("mintRhino should be reverted when directMint is disabled", async function () {
        
        const [owner, addr1, feeColector, add2] = await ethers.getSigners();
    
        const NFT = await ethers.getContractFactory("CrazyZooNFT");
        const Token = await ethers.getContractFactory("CrazyZooToken");
        
        const ZooToken = await Token.deploy();
        const ZooNFT = await NFT.deploy();
        
        await ZooNFT.setZooToken(ZooToken.address);
        await ZooNFT.setRange(1,10);
        await ZooNFT.setDirectMinting(false);
        await ZooNFT.setMintFeeStatus(true);
        await ZooNFT.setFees([250000000,250000000,250000000]);
        await ZooNFT.setFeeCollector(feeColector.address);
        
        await ZooToken.transfer(addr1.address,250000000);
        await ZooToken.connect(addr1).approve(ZooNFT.address,250000000);

        await expect(ZooNFT.connect(addr1).mintRhino(add2.address)).to.be.revertedWith('You Can Not Mint Now');

    });

    it("mintRhino should mint the RhinoId when chargeFeeOnMint is false", async function () {
        
        const [owner, addr1, feeColector, add2] = await ethers.getSigners();
    
        const NFT = await ethers.getContractFactory("CrazyZooNFT");
        const Token = await ethers.getContractFactory("CrazyZooToken");
        
        const ZooToken = await Token.deploy();
        const ZooNFT = await NFT.deploy();
        
        await ZooNFT.setZooToken(ZooToken.address);
        await ZooNFT.setRange(1,10);
        await ZooNFT.setDirectMinting(true);
        await ZooNFT.setMintFeeStatus(false);
        await ZooNFT.setFees([250000000,250000000,250000000]);
        await ZooNFT.setFeeCollector(feeColector.address);
        
        await ZooNFT.connect(addr1).mintRhino(add2.address);

        expect(await ZooToken.balanceOf(feeColector.address)).to.equal(0);
        expect(await ZooNFT.balanceOf(add2.address)).to.equal(1);

    });

    it("mintRhino should be reverted for rhinoIdCounter <= rhinoMaxId", async function () {
        
        const [owner, addr1, feeColector, add2] = await ethers.getSigners();
    
        const NFT = await ethers.getContractFactory("CrazyZooNFT");
        const Token = await ethers.getContractFactory("CrazyZooToken");
        
        const ZooToken = await Token.deploy();
        const ZooNFT = await NFT.deploy();
        
        await ZooNFT.setZooToken(ZooToken.address);
        await ZooNFT.setRange(1,10);
        await ZooNFT.setDirectMinting(true);
        await ZooNFT.setMintFeeStatus(true);
        await ZooNFT.setFees([250000000,250000000,250000000]);
        await ZooNFT.setFeeCollector(feeColector.address);
        
        await ZooToken.transfer(addr1.address,2500000000);
        await ZooToken.connect(addr1).approve(ZooNFT.address,2500000000);

        for (let i = 1; i <= 11; i++) {
            if(i==11){
                await expect(ZooNFT.connect(addr1).mintRhino(add2.address)).to.be.revertedWith('No more Rhinos available for minting');
            } else {
               await ZooNFT.connect(addr1).mintRhino(add2.address);
            }
        }
    });

    it("mintGorilla should mint the GorillaId", async function () {
        
        const [owner, addr1, feeColector, add2] = await ethers.getSigners();
    
        const NFT = await ethers.getContractFactory("CrazyZooNFT");
        const Token = await ethers.getContractFactory("CrazyZooToken");
        
        const ZooToken = await Token.deploy();
        const ZooNFT = await NFT.deploy();
        
        await ZooNFT.setZooToken(ZooToken.address);
        await ZooNFT.setRange(1,10);
        await ZooNFT.setDirectMinting(true);
        await ZooNFT.setMintFeeStatus(true);
        await ZooNFT.setFees([250000000,250000000,250000000]);
        await ZooNFT.setFeeCollector(feeColector.address);
        
        await ZooToken.transfer(addr1.address,2500000000);
        await ZooToken.connect(addr1).approve(ZooNFT.address,2500000000);

        for (let i = 1; i < 11; i++) {
            await ZooNFT.connect(addr1).mintGorilla(add2.address);
        }

        expect(await ZooToken.balanceOf(feeColector.address)).to.equal(2500000000);
        expect(await ZooNFT.balanceOf(add2.address)).to.equal(10);
        expect(6).to.equal(6);

    });

    it("mintGorilla should mint the GorillaId for Minter Role", async function () {
        
        const [owner, addr1, feeColector, add2] = await ethers.getSigners();
    
        const NFT = await ethers.getContractFactory("CrazyZooNFT");
        const Token = await ethers.getContractFactory("CrazyZooToken");
        
        const ZooToken = await Token.deploy();
        const ZooNFT = await NFT.deploy();
        
        await ZooNFT.setZooToken(ZooToken.address);
        await ZooNFT.setRange(1,10);
        await ZooNFT.setDirectMinting(true);
        await ZooNFT.setMintFeeStatus(true);
        await ZooNFT.setFees([250000000,250000000,250000000]);
        await ZooNFT.setFeeCollector(feeColector.address);
        
        await ZooToken.approve(ZooNFT.address,250000000);

        await ZooNFT.mintGorilla(add2.address);

        expect(await ZooToken.balanceOf(feeColector.address)).to.equal(0);
        expect(await ZooNFT.balanceOf(add2.address)).to.equal(1);


    });

    it("mintGorilla should be reverted when directMint is disabled", async function () {
        
        const [owner, addr1, feeColector, add2] = await ethers.getSigners();
    
        const NFT = await ethers.getContractFactory("CrazyZooNFT");
        const Token = await ethers.getContractFactory("CrazyZooToken");
        
        const ZooToken = await Token.deploy();
        const ZooNFT = await NFT.deploy();
        
        await ZooNFT.setZooToken(ZooToken.address);
        await ZooNFT.setRange(1,10);
        await ZooNFT.setDirectMinting(false);
        await ZooNFT.setMintFeeStatus(true);
        await ZooNFT.setFees([250000000,250000000,250000000]);
        await ZooNFT.setFeeCollector(feeColector.address);
        
        await ZooToken.transfer(addr1.address,250000000);
        await ZooToken.connect(addr1).approve(ZooNFT.address,250000000);

        await expect(ZooNFT.connect(addr1).mintGorilla(add2.address)).to.be.revertedWith('You Can Not Mint Now');

    });

    it("mintGorilla should mint the GorillaId when chargeFeeOnMint is false", async function () {
        
        const [owner, addr1, feeColector, add2] = await ethers.getSigners();
    
        const NFT = await ethers.getContractFactory("CrazyZooNFT");
        const Token = await ethers.getContractFactory("CrazyZooToken");
        
        const ZooToken = await Token.deploy();
        const ZooNFT = await NFT.deploy();
        
        await ZooNFT.setZooToken(ZooToken.address);
        await ZooNFT.setRange(1,10);
        await ZooNFT.setDirectMinting(true);
        await ZooNFT.setMintFeeStatus(false);
        await ZooNFT.setFees([250000000,250000000,250000000]);
        await ZooNFT.setFeeCollector(feeColector.address);
        
        await ZooNFT.connect(addr1).mintGorilla(add2.address);

        expect(await ZooToken.balanceOf(feeColector.address)).to.equal(0);
        expect(await ZooNFT.balanceOf(add2.address)).to.equal(1);

    });


    it("mintGorilla should be reverted for gorillaIdCounter <= gorillaMaxId", async function () {
        
        const [owner, addr1, feeColector, add2] = await ethers.getSigners();
    
        const NFT = await ethers.getContractFactory("CrazyZooNFT");
        const Token = await ethers.getContractFactory("CrazyZooToken");
        
        const ZooToken = await Token.deploy();
        const ZooNFT = await NFT.deploy();
        
        await ZooNFT.setZooToken(ZooToken.address);
        await ZooNFT.setRange(1,10);
        await ZooNFT.setDirectMinting(true);
        await ZooNFT.setMintFeeStatus(true);
        await ZooNFT.setFees([250000000,250000000,250000000]);
        await ZooNFT.setFeeCollector(feeColector.address);
        
        await ZooToken.transfer(addr1.address,2500000000);
        await ZooToken.connect(addr1).approve(ZooNFT.address,2500000000);

        for (let i = 1; i <= 11; i++) {
            if(i==11){
                await expect(ZooNFT.connect(addr1).mintGorilla(add2.address)).to.be.revertedWith('No more Gorillas available for minting');
            } else {
                await ZooNFT.connect(addr1).mintGorilla(add2.address);
            }
        }
    });


    // QmYwAPJ
    it("setBaseURI should set the BaseURI", async function () {
        
        const [owner, add2,feeColector] = await ethers.getSigners();
    
        const NFT = await ethers.getContractFactory("CrazyZooNFT");
        const Token = await ethers.getContractFactory("CrazyZooToken");

        const ZooToken = await Token.deploy();
        const ZooNFT = await NFT.deploy();
    
        await ZooNFT.setZooToken(ZooToken.address);
        await ZooNFT.setRange(1,10);
        await ZooNFT.setDirectMinting(true);
        await ZooNFT.setMintFeeStatus(true);
        await ZooNFT.setFees([250000000,250000000,250000000]);
        await ZooNFT.setFeeCollector(feeColector.address);
        
        await ZooNFT.mintLemur(add2.address);
        await ZooNFT.mintRhino(add2.address);
        await ZooNFT.mintGorilla(add2.address);
    
        await ZooNFT.setBaseURI("https://ipfs.io/ipfs/");
        await ZooNFT.setCid(1,"first");
        await ZooNFT.setCid(2,"second");
        await ZooNFT.setCid(3,"third");

        expect(await ZooNFT.tokenURI(1)).to.equal("https://ipfs.io/ipfs/first/1.json");
        expect(await ZooNFT.tokenURI(11)).to.equal("https://ipfs.io/ipfs/second/11.json");
        expect(await ZooNFT.tokenURI(21)).to.equal("https://ipfs.io/ipfs/third/21.json");

    })
    
})