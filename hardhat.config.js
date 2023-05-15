require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */

module.exports = {
  solidity: "0.8.7",
  networks: {
    mumbai: {
      url: "https://polygon-mumbai.g.alchemy.com/v2/Qg-FtBXZr0sZeieqGOg1HoR1ma6MscWF",
      accounts: [`place your private key here`],
    },
    arbitrum: {
      url: "https://arb-goerli.g.alchemy.com/v2/pCXGTOX5cerPI87r5_a_IGJsclHxk6kj",
      accounts: [`place your private key here`],
    },
  },
};