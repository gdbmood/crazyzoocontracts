require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */

module.exports = {
  solidity: "0.8.7",
  networks: {
    mumbai: {
      url: "https://polygon-mumbai.g.alchemy.com/v2/Qg-FtBXZr0sZeieqGOg1HoR1ma6MscWF",
      accounts: [`0x73d96a1f681f84fa872fe740e727a8aec8f54c341b213eb7323af6331344aaa8`],
    },
    arbitrum: {
      url: "https://arb-goerli.g.alchemy.com/v2/pCXGTOX5cerPI87r5_a_IGJsclHxk6kj",
      accounts: [`0x73d96a1f681f84fa872fe740e727a8aec8f54c341b213eb7323af6331344aaa8`],
    },
  },
};