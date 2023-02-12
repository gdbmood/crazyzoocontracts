# CRAZY ZOO PROTOCOL

## Introduction

This repo contains contracts for the Crazy Zoo Protocol and includes:

1. [Zoo Token](./contracts/ZooToken.sol)
2. [Zoo NFT](./contracts/CrazyZooNFT.sol)
3. [Zoo NFT Staking](./contracts/CrazyZooNftStaking.sol)

## [Zoo Token](./contracts/ZooToken.sol):

- `mint` - mints the specified ZOO token amount
- `setMinter` - adds an address/wallet as minter
- `setParams` - updates the minting fees
- `setFeeCollectors` - updates the fee collectors

  **_Note_** All these functions are only called by the `owner` except `mint` which can also be called by a `minter`

## [Zoo NFT](./contracts/CrazyZooNFT.sol):

- `mintLemur` - mints Lemur NFT of id range 1-2222
- `mintRhino` - mints Rhino NFT of id range 2223-4444
- `mintGorilla` - mints Gorilla NFT of id range 4445-6666
- `setMintFeeToken` - to updates `mintFeeToken`
- `setDirectMinting` - to enable minting from the NFT contract mint function
- `changeMintFeeStatus` - to disable/enable fee charge on NFT mint
- `setFeeCollector` - updates `feeCollector`
- `setBaseURI` - updates the `baseURI`
- `setFees` - updates `lemurMintFee`, `rhinoMintFee`, `gorillaMintFee`
- `setCid` - update the cid for the NFTs
  **_Note_** All functions are only called by the `admin` except for `mintLemur`, `mintRhino`, `mintGorilla`

## [Zoo NFT Staking](./contracts/CrazyZooNftStaking.sol):

- `stake` - stake/deposit NFTs to the staking contract in order to earn rewards
- `withdraw` - withdraws the specified NFT ids to the staker
- `feedYourAnimal` - feed your hungry animal NFTs that staked. Only animal NFTs staked that can get hungry and can fed not less than twice monthly
- `setRewardsPerDay` - updates `rewardsPerDay` for any of the value in the array
- `setRewardDays` - update `rewardDays` for any of the values in the array
- `setNftPrices` - update `nftPrices` for any of the values in the array
- `setFoodPrices` - update `foodPrices` for any of the values in the array
- `setExtraMintAmount` - updates the `extraMintAmount` value
- `setMintingFees` - update `mintingFees` for any of the values in the array
- `setReferralTaxes` - update referral1Tax referral2Tax referral3Tax
- `setBasicWithdrawalFee` - update `basicWithdrawalFee`
- `setWhaleFee` - update `whalesWithdrawalExtraFee`
  **_Note_** All functions are only called by the `owner` except `stake`, `withdraw`, `feedYourAnimal`

## Configuration Steps after Contract Deployments

1. Deploy [Zoo token](./contracts/ZooToken.sol)
2. Set the `nftStakingContractAddress` and `marketingWallet` addresses using the function `setFeeCollectors`
3. Deploy [Zoo NFT](./contracts/CrazyZooNFT.sol)
4. Deploy [Zoo NFT staking](./contracts/CrazyZooNftStaking.sol)
5. Set `Zoo NFT staking` address as a minter of the `Zoo token` using the `setMinter` on the `Zoo token` contract
6. Also grant `MINTER_ROLE` role to the `Zoo NFT staking` address on the `Zoo NFT` contract using `grantRole` function
   **_Note_** These setter and grant role functions are only called the respective contract deployers
