require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();
/** @type import('hardhat/config').HardhatUserConfig */

module.exports = {
  // solidity: "0.8.7",
  solidity: {
    version: "0.8.7",
    settings: {
      optimizer: {
        enabled: true,
        runs:200
      }
    }
  },
  networks: {
    hardhat:{
      // forking: {
      //   url: "https://polygon-mumbai.g.alchemy.com/v2/Qg-FtBXZr0sZeieqGOg1HoR1ma6MscWF",
      //   blockNumber: 35759121
      // },
    },
    ganache: {
      url: "HTTP://127.0.0.1:7545",
      accounts: [
        process.env.GANACHE_PRIVATE_KEY0,
        process.env.GANACHE_PRIVATE_KEY1,
        process.env.GANACHE_PRIVATE_KEY2,
        process.env.GANACHE_PRIVATE_KEY3,
      ],
    },
    goerli: {
      url: process.env.GOERLI_URL,
      accounts: [process.env.MUMBAI_PRIVATE_KEY],
    },
    arbitrumGoerli: {
      url: process.env.ARBITRUM_GOERLI_URL,
      accounts: [process.env.MUMBAI_PRIVATE_KEY],
    },
    mumbai: {
      url: "https://polygon-mumbai.g.alchemy.com/v2/Qg-FtBXZr0sZeieqGOg1HoR1ma6MscWF",
      accounts: [process.env.MUMBAI_PRIVATE_KEY],
    },
    arbitrum: {
      url: process.env.ARBITRUM_MAINNET_URL,
      accounts: [process.env.MUMBAI_PRIVATE_KEY],
    },
  },
  etherscan: {
    // yarn hardhat verify --network <NETWORK> <CONTRACT_ADDRESS> <CONSTRUCTOR_PARAMETERS>
    // apiKey: {
    //   goerli: process.env.ETHERSCAN_API_KEY,
    //   mumbai: process.env.POLYGON_API_KEY,
    // },
    // apiKey: process.env.POLYGON_API_KEY,
    apiKey: process.env.ARBITRUM_API_KEY,
  },
};