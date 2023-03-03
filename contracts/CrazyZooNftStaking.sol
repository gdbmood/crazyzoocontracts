// SPDX-License-Identifier: MIT
// Creator: andreitoma8
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Interfaces

//     IERC20: This is an interface for the standard ERC20 token contract.
//     IERC721: This is an interface for the standard ERC721 token contract.
//     INftCollection: This is a custom interface that extends IERC721. It includes additional functions for minting specific NFTs.
//     IRewardToken: This is a custom interface that extends IERC20. It includes additional functions for minting and transferring reward tokens.
//     IFeeToken: This is a custom interface that extends IERC20. It includes additional functions for minting and transferring fee tokens.

// Variables

//     feeToken: This is an immutable variable that holds the contract address for the fee token.
//     rewardsToken: This is an immutable variable that holds the contract address for the reward token.
//     nftCollection: This is an immutable variable that holds the contract address for the NFT collection.
//     lemurMinId: This is an immutable variable that holds the minimum token ID for Lemur NFTs.
//     lemurMaxId: This is an immutable variable that holds the maximum token ID for Lemur NFTs.
//     rhinoMinId: This is an immutable variable that holds the minimum token ID for Rhino NFTs.
//     rhinoMaxId: This is an immutable variable that holds the maximum token ID for Rhino NFTs.
//     gorillaMinId: This is an immutable variable that holds the minimum token ID for Gorilla NFTs.
//     gorillaMaxId: This is an immutable variable that holds the maximum token ID for Gorilla NFTs.
//     minBalance: This is an unsigned integer that holds the minimum balance (in Wei) that must be maintained by the contract.
//     maxSupply: This is an unsigned integer that holds the maximum supply (in Wei) of reward tokens that can be minted.
//     referral1Tax: This is an unsigned integer that holds the referral tax percentage (in basis points) for level 1 referrals.
//     referral2Tax: This is an unsigned integer that holds the referral tax percentage (in basis points) for level 2 referrals.
//     referral3Tax: This is an unsigned integer that holds the referral tax percentage (in basis points) for level 3 referrals.
//     basicWithdrawalFee: This is an unsigned integer that holds the basic withdrawal fee percentage (in basis points).
//     whalesWithdrawalExtraFee: This is an unsigned integer that holds the additional withdrawal fee percentage (in basis points) for users who withdraw a large amount of funds.
//     uint256 public constant MULTIPLIER : This declares a constant value of 10e8 which is used as a multiplier for some calculations in the contract.
//     address public TREASURY: This declares a public variable to store the address of the treasury account where the fees will be sent.
//     uint256 public treasuryFee : This declares a public variable to store the percentage of fees that will be sent to the treasury account. The default value is 5%.

// ARRAYS:

//     rewardsPerDay: This is an array of three unsigned integers that hold the rewards per day (in Wei) for each type of NFT deposited.
//     rewardDays: This is an array of three unsigned integers that hold the number of days for which the rewards will be distributed for each type of NFT deposited.
//     nftPrices: This is an array of three unsigned integers that hold the prices (in Wei) for each type of NFT.
//     foodPrices: This is an array of three unsigned integers that hold the prices (in Wei) for each type of food.
//     extraMintAmount: This is an array of three unsigned integers that hold the additional amount (in Wei) of reward tokens to mint when a specific type of NFT is deposited.
//     stakersArray; This is an array to store the addresses of all stakers who have staked their NFTs.


// MAPPING:

//  mapping(address => Staker) public stakers;: This creates a mapping between user addresses and a struct called Staker which contains information about the user's staked NFTs, rewards, and referral information.
//  mapping(address => StakedNft[]) public stakedNfts;: This creates a mapping between user addresses and an array of StakedNft structs which contain information about the user's staked NFTs.
//  mapping(uint256 => address) public stakerAddress;: This creates a mapping between token IDs and the address of the staker who has staked that token.
//  mapping(address => address[3]) public referrers;: This creates a mapping between user addresses and an array of three addresses which represent the user's referrers.
//  mapping(address => uint256) public usersReferralRewards;: This creates a mapping between user addresses and the amount of referral rewards they have earned.
//  mapping(address => address[]) public referees;: This creates a mapping between user addresses and an array of addresses which represent the users that they have referred.
//  mapping(uint256 => bool) public stakedBefore;: This creates a mapping between token IDs and a boolean value which represents whether that token has been staked before.
//  mapping(address => address[3]) public userReferrals;: This creates a mapping between user addresses and an array of three addresses which represent the user's referrals.
//  refwithdrawalTime: This is a mapping that associates a withdrawal time (as a Unix timestamp) with each user address. This is used to prevent multiple withdrawals from the same referral.


// events:

//  event Staked(uint256[] indexed _ids, address indexed _staker);: This is an event that is emitted when a user stakes their NFTs.
//  event Withdrawn(uint256[] indexed _ids, address indexed _staker);: This is an event that is emitted when a user withdraws their staked NFTs.
//  event AnimalFed(uint256 indexed nftIndex, address indexed feeder, uint256 indexed foodPrice);: This is an event that is emitted when a user feeds an NFT.
//  event NewRewardDays(uint256 indexed nftIndex, uint256 indexed newDays);: This is an event that is emitted when the reward period for an NFT is changed.
//  event NewRewardsPerDay(uint256 indexed nftIndex, uint256 indexed newValue);: This is an event that is emitted when the rewards per day for an NFT are changed.
//  event NewNftPrice(uint256 indexed nftIndex, uint256 indexed newPrice);: This is an event that is emitted when the price of an NFT is changed.
//  event NewFoodPrice(uint256 indexed nftIndex, uint256 indexed newPrice);: This is an event that is emitted when the price of food for an NFT is changed.
//  event NewRefTaxes(uint256 indexed newRefTax1, uint256 indexed newRefTax2, uint256 indexed newRefTax
//  event NewBasicWithdrawalFee(uint256 indexed newBasicWithdrawalFee): An event emitted when the basic withdrawal fee is updated. The new withdrawal fee value is passed as a parameter.
//  event NewWhaleFee(uint256 indexed newBasicWhaleFee): An event emitted when the whale fee is updated. The new whale fee value is passed as a parameter.
//  event NewMinBalance(uint256 indexed _newMinBal): An event emitted when the minimum balance requirement is updated. The new minimum balance value is passed as a parameter.
//  event NewMaxSupply(uint256 indexed _newMaxSupply): An event emitted when the maximum supply is updated. The new maximum supply value is passed as a parameter.


interface INftCollection is IERC721 {
    function mintLemur(address to) external;

    function mintRhino(address to) external;

    function mintGorilla(address to) external;
}

interface IRewardToken {
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external;

    function mint(address to, uint256 amount) external;

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external;

    function transfer(address to, uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);
}

interface IFeeToken {
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external;

    function mint(address to, uint256 amount) external;

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external;

    function transfer(address to, uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);
}

contract CrazyZooNftStaking is Ownable, ReentrancyGuard {
    using SafeERC20 for IRewardToken;
    using SafeERC20 for IFeeToken;

    // Interfaces for ERC20 and ERC721
    IFeeToken public immutable feeToken;
    IRewardToken public immutable rewardsToken;
    INftCollection public immutable nftCollection;

    uint256 public immutable lemurMinId = 1;
    uint256 public immutable lemurMaxId = 2222;
    uint256 public immutable rhinoMinId = 2223;
    uint256 public immutable rhinoMaxId = 4444;
    uint256 public immutable gorillaMinId = 4445;
    uint256 public immutable gorillaMaxId = 6666;

    struct StakedNft {
        uint256 id;
        uint256 feedCounter;
        uint256 lastTimeFed;
        uint256 timeStaked;
        bool expired;
    }

    // Staker info
    struct Staker {
        uint256 fundsDeposited;
        // Amount of ERC721 Tokens staked
        uint256 amountStaked;
        // Last time of details update for this User
        uint256 timeOfLastUpdate;
        // Calculated, but unclaimed rewards for the User. The rewards are
        // calculated each time the user writes to the Smart Contract
        uint256 unclaimedRewards;
    }

    // Rewards per day for the different NFTs deposited in Wei.
    // Rewards are cumulated once every hour.
    // 0 for Lemur, 1 for Rhino, 2 for Gorilla
    // 0.6 = 6/10, 0.7 = 7/10, 0.8 = 8/10
    uint256[3] public rewardsPerDay = [6, 7, 8];
    // 0 for Lemur, 1 for Rhino, 2 for Gorilla
    uint256[3] public rewardDays = [500 days, 500 days, 500 days];

    uint256[3] public nftPrices = [125 * 1e6, 250 * 1e6, 500 * 1e6];

    uint256[3] public foodPrices = [3.5 * 1e6, 7.5 * 1e6, 15 * 1e6];

    // Figures in Percentage
    uint256[3] public extraMintAmount = nftPrices;

    uint256 public minBalance = 50000 * 1e6;
    uint256 public maxSupply = 99999999 * 1e6;

    // Figures in Percentage
    // 100 = 10% * 10, 25 = 2.5% * 10, 5 = 0.5% * 10
    uint256 public referral1Tax = 100;
    uint256 public referral2Tax = 25;
    uint256 public referral3Tax = 5;
    mapping(address => uint256) refwithdrawalTime;

    // Figure in Percentage
    // 3% = 3/100
    uint256 public basicWithdrawalFee = 3;

    // 5% = 5/100
    uint256 public whalesWithdrawalExtraFee = 5;

    // In Ethereum blockchain, the arithmetic operations for handling numbers are based on a fixed-point arithmetic system with a precision of up to 18 decimal places. This means that any number on the Ethereum blockchain can have up to 18 decimal places.
    uint256 public constant MULTIPLIER = 10e8;

    address[] public stakersArray;

    address public TREASURY;
    // 5% = 5/100
    uint256 public treasuryFee = 5;

    // Mapping of User Address to Staker info
    mapping(address => Staker) public stakers;
    // Mapping of User Address to StakedNft
    mapping(address => StakedNft[]) public stakedNfts;

    // Mapping of Token Id to staker. Made for the SC to remember
    // who to send back the ERC721 Token to.
    mapping(uint256 => address) public stakerAddress;

    // Referral system
    // Records the 3 levels user's referrers
    mapping(address => address[3]) public referrers;
    // Populate a user's referral reward
    mapping(address => uint256) public usersReferralRewards;
    // Mapping for each user's referees
    mapping(address => address[]) public referees;

    mapping(uint256 => bool) public stakedBefore;
    mapping(address => address[3]) public userReferrals;

    // Events
    event Staked(uint256[] indexed _ids, address indexed _staker);
    event Withdrawn(uint256[] indexed _ids, address indexed _staker);
    event AnimalFed(
        uint256 indexed nftIndex,
        address indexed feeder,
        uint256 indexed foodPrice
    );
    event NewRewardDays(uint256 indexed nftIndex, uint256 indexed newDays);
    event NewRewardsPerDay(uint256 indexed nftIndex, uint256 indexed newValue);
    event NewNftPrice(uint256 indexed nftIndex, uint256 indexed newPrice);
    event NewFoodPrice(uint256 indexed nftIndex, uint256 indexed newPrice);
    event NewRefTaxes(
        uint256 indexed newRefTax1,
        uint256 indexed newRefTax2,
        uint256 indexed newRefTax3
    );
    event NewBasicWithdrawalFee(uint256 indexed newBasicWithdrawalFee);
    event NewWhaleFee(uint256 indexed newBasicWhaleFee);
    event NewMinBalance(uint256 indexed _newMinBal);
    event NewMaxSupply(uint256 indexed _newMaxSupply);

    // Constructor function
    constructor(
        INftCollection _nftCollection,
        IRewardToken _rewardsToken,
        IFeeToken _feeToken,
        address _treasury
    ) {
        nftCollection = _nftCollection;
        rewardsToken = _rewardsToken;
        feeToken = _feeToken;
        TREASURY = _treasury;
    }

    function mintNft(
        address to,
        uint256 nftIndex,
        address referral1,
        address referral2,
        address referral3
    ) external nonReentrant {

        //This line retrieves the price of the NFT with the given index (nftIndex) from the nftPrices array and assigns it to a variable called nftPriceToPay. Note that the nftPrices array is 0-indexed, so we need to subtract 1 from nftIndex.
        uint256 nftPriceToPay = nftPrices[nftIndex - 1];

        // This line checks whether the feeToken contract has been authorized to transfer at least nftPriceToPay tokens by the address calling the function (_msgSender()). If the allowance is less than nftPriceToPay, the function will revert with the error message "Approve Staking contract".
        require(
            feeToken.allowance(_msgSender(), address(this)) >= nftPriceToPay,
            "Approve Staking contract"
        );

        // This line transfers nftPriceToPay tokens from the address calling the function (_msgSender()) to the staking contract (address(this)) using the transferFrom function of the feeToken contract.
        // Deduct tax
        feeToken.transferFrom(_msgSender(), address(this), nftPriceToPay);

        // This line calculates the referral reward amount for the given NFT purchase. It multiplies nftPriceToPay by the sum of the referral taxes (referral1Tax + referral2Tax + referral3Tax), and then divides the result by 1000 to convert it from basis points to a percentage. The resulting value is assigned to a variable called refReward.
        uint256 refReward = (nftPriceToPay *
            (referral1Tax + referral2Tax + referral3Tax)) / 1000;

        // This line calculates the treasury fee for the given NFT purchase. It multiplies the treasury fee percentage (treasuryFee) by the difference between nftPriceToPay and refReward, and then divides the result by 100 to convert it from basis points to a percentage. The resulting value is assigned to a variable called treasuryAmount.
        uint256 treasuryAmount = (treasuryFee * (nftPriceToPay - refReward)) / 100;

        // This line transfers treasuryAmount tokens from the staking contract to the TREASURY address using the transfer function of the feeToken contract.
        feeToken.transfer(TREASURY, treasuryAmount);

        // Mint fee token
        if (feeToken.totalSupply() < maxSupply) {
            feeToken.mint(address(this), nftPrices[nftIndex - 1]);
        }
        // This function is responsible for minting the NFT and transferring it to the provided address to.
        _mintNft(to, nftIndex);

        // This function is responsible for distributing referral rewards to the referrers, if any.
        _runReferralSystem(
            _msgSender(),
            referral1,
            referral2,
            referral3,
            nftPriceToPay
        );
        
    }


    // This function allows a user to stake one or more NFTs specified by their token IDs in the _tokenIds array.
    // If address already has ERC721 Token/s staked, calculate the rewards.
    // For every new Token Id in param transferFrom user to this Smart Contract,
    // increment the amountStaked and map msg.sender to the Token Ids of the staked
    // Token to later send back on withdrawal. Finally give timeOfLastUpdate the
    // value of now.
    function stake(uint256[] calldata _tokenIds) external nonReentrant {
        
        // Before staking, it checks the balance and total supply of the reward token (referred to as rewardsToken in the contract) and if the balance is below a specified minimum (minBalance) and the total supply is below a specified maximum (maxSupply), it mints additional reward tokens to the smart contract address.
        // Maintain minimum amount of the reward token
        if (
            rewardsToken.balanceOf(address(this)) < minBalance &&
            rewardsToken.totalSupply() < maxSupply
        ) {
            rewardsToken.mint(address(this), minBalance);
        }

        //  it checks if the caller (_msgSender()) has staked any tokens before. If yes, it calculates the rewards for the caller, adds them to the unclaimedRewards variable of the caller's staking record, and updates the staking pool for the caller. If not, it adds the caller's address to an array of stakers.
        if (stakers[_msgSender()].amountStaked > 0) {
            uint256 rewards = calculateRewards(_msgSender());
            stakers[_msgSender()].unclaimedRewards += rewards;
            updateUserPool(_msgSender());
        } else {
            stakersArray.push(_msgSender());
        }

        uint256 len = _tokenIds.length;

        //  The loop iterates over the array of _tokenIds
        for (uint256 i; i < len; ++i) {
            
            //For each ERC721 token ID in the input array, it checks if the token has been staked before. If yes, it throws an error. as a token can only be staked once
            require(!stakedBefore[_tokenIds[i]], "Can't Restake A Token");
            uint256 index = getIndexForId(_tokenIds[i]);

            // It also checks if the caller is the owner of the token
            require(
                nftCollection.ownerOf(_tokenIds[i]) == _msgSender(),
                "Can't Stake Token You Don't Own!"
            );

            // if the smart contract is authorized to handle the token by checking if the caller has approved the smart contract's address as an operator for the token.    
            require(
                nftCollection.isApprovedForAll(_msgSender(), address(this)),
                "Approve Staker For The Nft"
            );

            // If these checks pass, 
            
            // the smart contract transfers the token from the caller's address to the smart contract address
            nftCollection.transferFrom(
                _msgSender(),
                address(this),
                _tokenIds[i]
            );
            
            // mints additional reward tokens based on the token ID,
            // Mint extra reward token
            rewardsToken.mint(address(this), extraMintAmount[index - 1]);


            // records the token's staking details in the staking records of the caller.
            stakerAddress[_tokenIds[i]] = _msgSender();
            StakedNft memory _stakedNft;
            _stakedNft.id = _tokenIds[i];
            _stakedNft.feedCounter = 0;
            _stakedNft.lastTimeFed = block.timestamp;
            _stakedNft.timeStaked = block.timestamp;
            stakedNfts[_msgSender()].push(_stakedNft);
            stakers[_msgSender()].fundsDeposited +=
                nftPrices[index - 1] +
                extraMintAmount[index - 1];
            stakedBefore[_tokenIds[i]] = true;
        }

        // the amountStaked variable of the staker's struct is incremented by the number of tokens being staked (len), indicating that the staker has staked additional tokens
        stakers[_msgSender()].amountStaked += len;

        // setting the current time
        stakers[_msgSender()].timeOfLastUpdate = block.timestamp;
        emit Staked(_tokenIds, _msgSender());
    }

    // Check if user has any ERC721 Tokens Staked and if he tried to withdraw,
    // calculate the rewards and store them in the unclaimedRewards and for each
    // ERC721 Token in param: check if msg.sender is the original staker, decrement
    // the amountStaked of the user and transfer the ERC721 token back to them.

    // The function checks that the amountStaked of the staker is greater than zero before allowing a withdrawal. However, there is no check to ensure that the unclaimedRewards of the staker are also greater than zero. If a staker has no unclaimed rewards, they should not be allowed to withdraw any tokens.

    // In the loop that removes the staker from the stakersArray if they have no tokens staked, the loop variable i is not initialized. This can cause issues if the length of the stakersArray is zero.    
    function withdraw(uint256[] calldata _tokenIds) external nonReentrant {
        Staker storage __staker = stakers[_msgSender()];
        
        //  it checks if the user has any tokens staked by checking if the amountStaked for the user in the stakers mapping is greater than 0. If not, it reverts with an error message.
        require(__staker.amountStaked > 0, "You Have No Tokens Staked");

        // It calculates the rewards that the user is eligible to receive and updates the user's pool by calling the updateUserPool function.
        uint256 rewards = calculateRewards(_msgSender());
        updateUserPool(_msgSender());
        
        // It calculates the total amount of funds that the user deposited (including the rewards).
        uint256 userFunds = __staker.fundsDeposited;

        // It checks if the transaction is a whale transaction (i.e. the amount being withdrawn is greater than a certain threshold) and calculates a fee based on that.   
        // Check if whale txn and deduce tax accordingly
        uint256 whaleFee = getWhaleFee(userFunds);
        uint256 len = _tokenIds.length;

        __staker.unclaimedRewards += (rewards -
            ((basicWithdrawalFee * rewards * len) / 100) -
            ((whaleFee * rewards * len) / 100));

        // It loops through the list of NFT token IDs that the user wants to withdraw
            // It checks if the NFT token is currently staked by the user.
           // It sets the stakerAddress for that token ID to address(0) to indicate that it is no longer staked.
           // It transfers the NFT token from the contract to the user.

        for (uint256 i; i < len; ++i) {
            require(stakerAddress[_tokenIds[i]] == _msgSender());
            stakerAddress[_tokenIds[i]] = address(0);
            nftCollection.transferFrom(
                address(this),
                _msgSender(),
                _tokenIds[i]
            );
        }

        // t updates the user's amountStaked in the stakers mapping by subtracting the length of the _tokenIds array (i.e. the number of tokens being withdrawn).
        __staker.amountStaked -= len;
        
        // It updates the user's timeOfLastUpdate to the current block timestamp.
        __staker.timeOfLastUpdate = block.timestamp;

        // f the user has no tokens staked after this withdrawal, it removes the user's address from the stakersArray to save gas costs.
        if (__staker.amountStaked == 0) {
            for (uint256 i; i < stakersArray.length; ++i) {
                if (stakersArray[i] == _msgSender()) {
                    stakersArray[i] = stakersArray[stakersArray.length - 1];
                    stakersArray.pop();
                }
            }
        }
        // It emits an event to indicate that the user has withdrawn their tokens.
        emit Withdrawn(_tokenIds, _msgSender());
    }

    // Calculate rewards for the msg.sender, check if there are any rewards
    // claim, set unclaimedRewards to 0 and transfer the ERC20 Reward token
    // to the user.
    function claimRewards() external {

        // calculates the total amount of rewards that the caller is eligible to claim. It then adds to this the amount of unclaimed rewards that the caller has already earned and stored in the unclaimedRewards field of their Staker struct.
        uint256 rewards = calculateRewards(_msgSender()) +
            stakers[_msgSender()].unclaimedRewards;
        updateUserPool(_msgSender());
        // checks that the amount of rewards to be claimed is greater than zero.
        require(rewards > 0, "You have no rewards to claim");
        // updates the timeOfLastUpdate field in the caller's Staker struct to the current block timestamp. This is done to ensure that the rewards calculation is accurate and up to date.
        stakers[_msgSender()].timeOfLastUpdate = block.timestamp;

        //  sets the unclaimedRewards of the staker to zero after they have claimed their rewards. It ensures that the staker cannot claim the same rewards twice.
        stakers[_msgSender()].unclaimedRewards = 0;

        // transfers the claimed rewards to the caller by calling the transfer function of the rewardsToken contract (which was previously defined in the constructor). The amount to be transferred is the rewards value calculated earlier, and the recipient is _msgSender().
        rewardsToken.transfer(_msgSender(), rewards);
    }

    // This function is called to claim referral rewards by the user who has referred others to buy NFTs
    function claimReferralRewards() external {

        //  if the user who is calling this function has at least one ZOO NFT
        require(
            nftCollection.balanceOf(_msgSender()) > 0,
            "You Need To Have ZOO Nft"
        );

        // checks whether the last time the user claimed their referral rewards is greater than zero, meaning they have already claimed rewards at least once before.
        // If refwithdrawalTime[_msgSender()] is equal to zero, it means the user has never claimed any referral rewards before, so there is no need to check whether they have waited for the required time between claims.
        if (refwithdrawalTime[_msgSender()] > 0) {
            
            // checks if the last time the user claimed their referral rewards was at least 1 day ago.
            require(
                (block.timestamp - refwithdrawalTime[_msgSender()]) >= 1 days,
                "Referral Reward Is Only Claimed Per Day"
            );
        }
        // calculate the referral rewards that the user is eligible to claim and set the user's referral rewards to zer
        uint256 refRewards = usersReferralRewards[_msgSender()];
        usersReferralRewards[_msgSender()] = 0;

        // transfers the referral rewards to the user's address using the rewardsToken token contract's transfer function.
        rewardsToken.transfer(_msgSender(), refRewards);

        // sets the timestamp of the last time the user claimed referral rewards to the current block timestamp so that the user can claim rewards again after one day from this timestamp.
        refwithdrawalTime[_msgSender()] = block.timestamp;
    }

    // TokenId parameter in the feedYourAnimal function is used to specify the ID of the NFT that the user wants to feed
    function feedYourAnimal(uint256 _tokenId) external nonReentrant {
        // returns the index of the NFT based on the _tokenId parameter.
        uint256 nftIndex = getIndexForId(_tokenId);
        // fetches the price of food for the NFT at the given nftIndex.
        uint256 foodPrice = foodPrices[nftIndex - 1];
        // checks if the contract has been approved to spend the required amount of feeToken tokens by the caller
        require(
            feeToken.allowance(_msgSender(), address(this)) >= foodPrice,
            "Approve Staking Contract"
        );

        // transfers the foodPrice amount of feeToken tokens from the caller to the contract.
        feeToken.transferFrom(_msgSender(), address(this), foodPrice);

        // fetches the array of StakedNft structs for the caller from the stakedNfts mapping.
        StakedNft[] storage userStakedNfts = stakedNfts[_msgSender()];

        // stores the length of the userStakedNfts array.
        uint256 len = userStakedNfts.length;

        // iterates over each StakedNft struct in the userStakedNfts array.
        for (uint256 i; i < len; i++) {
            // checks if the _tokenId matches with the id of the StakedNft struct in the current iteration.
            if (userStakedNfts[i].id == _tokenId) {

                //  increments the feedCounter property of the StakedNft struct by 1.
                userStakedNfts[i].feedCounter += 1;

                // updates the lastTimeFed property of the StakedNft struct with the current block timestamp.
                userStakedNfts[i].lastTimeFed = block.timestamp;

                // emits the AnimalFed event with the nftIndex, _msgSender(), and foodPrice parameters.
                emit AnimalFed(nftIndex, _msgSender(), foodPrice);

                // exits the function once the if condition is met, meaning that the appropriate StakedNft struct has been found and updated.
                return;
            }
        }
    }

    function setReferralTaxes(
        uint256 _newRefTax1,
        uint256 _newRefTax2,
        uint256 _newRefTax3
    ) external onlyOwner {
        referral1Tax = _newRefTax1;
        referral2Tax = _newRefTax2;
        referral3Tax = _newRefTax3;
        emit NewRefTaxes(_newRefTax1, _newRefTax2, _newRefTax3);
    }

    function setFoodPrices(uint256 _nftIndex, uint256 _newPrice)
        external
        onlyOwner
    {
        require(_nftIndex > 0 && _nftIndex < 4, "Invalid Index");
        foodPrices[_nftIndex - 1] = _newPrice;
        emit NewFoodPrice(_nftIndex, _newPrice);
    }

    function setNftPrices(uint256 _nftIndex, uint256 _newPrice)
        external
        onlyOwner
    {
        require(_nftIndex > 0 && _nftIndex < 4, "Invalid Index");
        nftPrices[_nftIndex - 1] = _newPrice;
        emit NewNftPrice(_nftIndex, _newPrice);
    }

    function setRewardDays(uint256 _nftIndex, uint256 _newDays)
        external
        onlyOwner
    {
        // checks if the _nftIndex argument is a valid index
        require(_nftIndex > 0 && _nftIndex < 4, "Invalid Index");
        address[] memory _stakers = stakersArray;
        uint256 len = _stakers.length;

        // iterates through each address in the _stakers

        // Adds the calculated rewards of the user to their unclaimedRewards balance.
        // Updates the user's pool data with updateUserPool().
        // Sets the user's timeOfLastUpdate to the current block timestamp.
        for (uint256 i; i < len; ++i) {
            address user = _stakers[i];
            stakers[user].unclaimedRewards += calculateRewards(user);
            updateUserPool(user);
            stakers[user].timeOfLastUpdate = block.timestamp;
        }

        // sets the rewardDays value for the specified _nftIndex to _newDays
        rewardDays[_nftIndex - 1] = _newDays;
        emit NewRewardDays(_nftIndex, _newDays);
    }

    function setBasicWithdrawalFee(uint256 _newBasicFee) external onlyOwner {
        basicWithdrawalFee = _newBasicFee;
        emit NewBasicWithdrawalFee(_newBasicFee);
    }

    function setWhaleFee(uint256 _newWhaleFee) external onlyOwner {
        whalesWithdrawalExtraFee = _newWhaleFee;
        emit NewWhaleFee(_newWhaleFee);
    }

    function setMinBalance(uint256 newMinBal) external onlyOwner {
        minBalance = newMinBal;
        emit NewMinBalance(newMinBal);
    }

    function setMaxSupply(uint256 newMaxSupply) external onlyOwner {
        maxSupply = newMaxSupply;
        emit NewMaxSupply(newMaxSupply);
    }

    function emergencyNftWithdraw(address to, uint256 __tokenId)
        external
        onlyOwner
    {
        nftCollection.safeTransferFrom(_msgSender(), to, __tokenId);
    }

    function emergencyFeeTokenWithdraw(address to, uint256 __amount)
        external
        onlyOwner
    {
        feeToken.transfer(to, __amount);
    }

    function emergencyRewardsTokenWithdraw(address to, uint256 __amount)
        external
        onlyOwner
    {
        rewardsToken.transfer(to, __amount);
    }

    //whalesWithdrawalExtraFee

    // Set the rewardsPerDay variable
    // Because the rewards are calculated passively, the owner has to first update the rewards
    // to all the stakers, which could result in very heavy load and expensive transactions or
    // even reverting due to reaching the gas limit per block. Redesign incoming to bound loop.
    function setRewardsPerDay(uint256 _nftIndex, uint256 _newValue)
        public
        onlyOwner
    {
        require(_nftIndex > 0 && _nftIndex < 4, "Invalid Index");
        address[] memory _stakers = stakersArray;
        uint256 len = _stakers.length;
        for (uint256 i; i < len; ++i) {
            address user = _stakers[i];
            stakers[user].unclaimedRewards += calculateRewards(user);
            updateUserPool(user);
            stakers[user].timeOfLastUpdate = block.timestamp;
        }
        rewardsPerDay[_nftIndex - 1] = _newValue;
        emit NewRewardsPerDay(_nftIndex, _newValue);
    }

    //////////
    // View //
    //////////
    // function calculates the ratio of the user's funds to the total balance of the rewards token held by the contract. If the ratio is less than 1%, no fee is charged. If the ratio is between 1% and 8%, the function calculates a fee based on a multiple of the whalesWithdrawalExtraFee parameter.
    function getWhaleFee(uint256 _userFunds) internal view returns (uint256) {

        //  checks how many rewards tokens the contract has in its balance.
        uint256 rewardTokenBalance = rewardsToken.balanceOf(address(this));
        
        // _userFunds represents the amount of funds that the user wants to withdraw.
        //  MULTIPLIER is a constant with a value of 10e8, which is used to convert the fractional ratio into an integer value.
        // whalesWithdrawalExtraFee represents the extra fee charged for a withdrawal
    // rewardTokenBalance represents the balance of the reward token held by the contract.
        uint256 ratio = (_userFunds * MULTIPLIER) / rewardTokenBalance;

        // If the ratio is less than 1% (represented as 1 * MULTIPLIER / 100), the function returns 0, indicating that the user does not need to pay any extra fee.
        // If the ratio is between 1% and 2%, the function returns the whalesWithdrawalExtraFee, multiplied by 1. If the ratio is between 2% and 3%, the function returns the whalesWithdrawalExtraFee multiplied by 2, and so on, until the ratio is greater than or equal to 8%, at which point the function returns the whalesWithdrawalExtraFee multiplied by 8.
        if (ratio < (1 * MULTIPLIER) / 100) {
            return 0;
        } else if (
            ratio >= ((1 * MULTIPLIER) / 100) &&
            ratio < ((2 * MULTIPLIER) / 100)
        ) {
            return 1 * whalesWithdrawalExtraFee;
        } else if (
            ratio >= ((2 * MULTIPLIER) / 100) &&
            ratio < ((3 * MULTIPLIER) / 100)
        ) {
            return 2 * whalesWithdrawalExtraFee;
        } else if (
            ratio >= ((3 * MULTIPLIER) / 100) &&
            ratio < ((4 * MULTIPLIER) / 100)
        ) {
            return 3 * whalesWithdrawalExtraFee;
        } else if (
            ratio >= ((4 * MULTIPLIER) / 100) &&
            ratio < ((5 * MULTIPLIER) / 100)
        ) {
            return 4 * whalesWithdrawalExtraFee;
        } else if (
            ratio >= ((5 * MULTIPLIER) / 100) &&
            ratio < ((6 * MULTIPLIER) / 100)
        ) {
            return 5 * whalesWithdrawalExtraFee;
        } else if (
            ratio >= ((6 * MULTIPLIER) / 100) &&
            ratio < ((7 * MULTIPLIER) / 100)
        ) {
            return 6 * whalesWithdrawalExtraFee;
        } else if (
            ratio >= ((7 * MULTIPLIER) / 100) &&
            ratio < ((8 * MULTIPLIER) / 100)
        ) {
            return 7 * whalesWithdrawalExtraFee;
        } else {
            return 8 * whalesWithdrawalExtraFee;
        }
    }

    // checks if an NFT with a given _tokenId is hungry or not
    function isHungry(uint256 _tokenId) public view returns (bool) {
        bool _isHungry;
        address _staker = stakerAddress[_tokenId];
        // It first checks if the NFT is staked or not by getting the staker address from stakerAddress mapping
        require(_staker != address(0), "Nft Is Not Staked");
        // f the NFT is staked, it retrieves the staker's information and the array of staked NFTs associated with the staker.
        Staker memory staker = stakers[_staker];
        StakedNft[] memory _stakedNfts = stakedNfts[_staker];

        // loops over each staked NFT to check if the given _tokenId matches any of the staked NFTs. If it finds a match, it checks whether the NFT is hungry or not by comparing the difference between the current block timestamp and the time the NFT was last fed. If this difference is greater than 30 days, it means that the NFT is hungry and the function returns true. If the _tokenId is not found among the staked NFTs or if the NFT is not hungry, the function returns false.
        for (uint256 i; i < staker.amountStaked; i++) {
            StakedNft memory _stakedNft = _stakedNfts[i];
            if (_stakedNft.id == _tokenId) {
                return (block.timestamp - _stakedNft.lastTimeFed) > 30 days;
            }
        }
        return _isHungry;
    }

    function userStakeInfo(address _user)
        public
        view
        returns (uint256 _tokensStaked, uint256 _availableRewards)
    {
        return (stakers[_user].amountStaked, availableRewards(_user));
    }

    function availableRewards(address _user) public view returns (uint256) {
        if (stakers[_user].amountStaked == 0) {
            return stakers[_user].unclaimedRewards;
        }
        uint256 _rewards = stakers[_user].unclaimedRewards +
            calculateRewards(_user);
        return _rewards;
    }

    function getIndexForId(uint256 _id) public pure returns (uint256) {
        if (_id >= lemurMinId && _id <= lemurMaxId) {
            return 1;
        } else if (_id >= rhinoMinId && _id <= rhinoMaxId) {
            return 2;
        } else if (_id >= gorillaMinId && _id <= gorillaMaxId) {
            return 3;
        } else {
            revert("Id Out Of Range");
        }
    }

    // Calculate rewards for param staker_ by calculating the time passed
    // since last update in hours and multiplying it to ERC721 Tokens Staked
    // and rewardsPerDay.
    function calculateRewards(address staker_) public view returns (uint256) {

        // creates a memory variable staker of type Staker and assigns it the value of the Staker struct for the staker_ address in the stakers mapping.
        Staker memory staker = stakers[staker_];
        // creates a memory variable _stakedNfts of type StakedNft array and assigns it the value of the StakedNft array for the staker_ address in the stakedNfts mapping.
        StakedNft[] memory _stakedNfts = stakedNfts[staker_];

        uint256 accRewards;
        for (uint256 i; i < staker.amountStaked; i++) {
            uint256 _index = getIndexForId(_stakedNfts[i].id);

            //  checks if the staked NFT at index i has expired. If it has not expired, the function continues to the next check.
            if (!_stakedNfts[i].expired) {
                // checks if the staked NFT at index i belongs to the staker_ address and if the NFT has been staked for fewer days than the corresponding reward period. If both conditions are true, the function continues to the next check.
                if (
                    stakerAddress[_stakedNfts[i].id] == staker_ &&
                    (block.timestamp - _stakedNfts[i].timeStaked <=
                        rewardDays[_index - 1])
                ) {
                    // Check if NFT has NOT expired
                    //  checks if the staked NFT at index i has been fed within the last 30 days. If it has, the function calculates the accumulated rewards using the formula (timeSinceLastUpdate * rewardsPerDay * NFTPrice) / (1000 * 86400) and adds it to the accRewards variable.
                    if (
                        (block.timestamp - _stakedNfts[i].lastTimeFed) <=
                        30 days
                    ) {
                        accRewards +=
                            ((block.timestamp - staker.timeOfLastUpdate) *
                                rewardsPerDay[_index - 1] *
                                nftPrices[_index - 1]) /
                            (1000 * 86400);

                    //If the staked NFT at index i has not been fed within the last 30 days, the function calculates the accumulated rewards using the formula ((30 days - timeSinceLastFed) * rewardsPerDay * NFTPrice) / (1000 * 86400) and adds it to the accRewards variable.
                    } else {
                        // NFT has expired

                        accRewards +=
                            ((_stakedNfts[i].lastTimeFed +
                                30 days -
                                staker.timeOfLastUpdate) *
                                rewardsPerDay[_index - 1] *
                                nftPrices[_index - 1]) /
                            (1000 * 86400);
                    }
                }
            }
        }
        //Finally,  returns the accumulated rewards for the staker.
        return accRewards;
    }

    /////////////
    // Internal//
    /////////////

    // It is used to update the state of the staker's NFTs in the stakedNfts mapping.
    function updateUserPool(address staker_) internal {

        //create references to the Staker and StakedNft storage variables in the stakers and stakedNfts mappings respectively, for the staker_ address passed as an argument.
        Staker storage staker = stakers[staker_];
        StakedNft[] storage _stakedNfts = stakedNfts[staker_];

        for (uint256 i; i < staker.amountStaked; i++) {
            //  calculates the _index of the NFT using the getIndexForId function.
            uint256 _index = getIndexForId(_stakedNfts[i].id);

            // hecks if the current NFT has not expire
            if (!_stakedNfts[i].expired) {

                //if the staker_ address is the same as the stakerAddress for the NFT,
                // if the NFT has been staked for a duration less than or equal to the reward days specified in the rewardDays array for the NFT.
                if (
                    stakerAddress[_stakedNfts[i].id] == staker_ &&
                    (block.timestamp - _stakedNfts[i].timeStaked <=
                        rewardDays[_index - 1])
                ) {
                    // checks if the last time the NFT was fed is more than 30 days ago, and if so, it sets the expired flag for the NFT to true. This will prevent the NFT from being used to calculate rewards in the future.
                    // Check if NFT has expired
                    if (
                        (block.timestamp - _stakedNfts[i].lastTimeFed) > 30 days
                    ) {
                        _stakedNfts[i].expired = true;
                    }
                }
            }
        }
    }

    // takes five parameters:

    // _minter: the address of the account that minted the NFT.
    // _referral1: the address of the first-level referral.
    // _referral2: the address of the second-level referral.
    // _referral3: the address of the third-level referral.
    // _nftPriceToPay: the price of the NFT being minted.
    function _runReferralSystem(
        address _minter,
        address _referral1,
        address _referral2,
        address _referral3,
        uint256 _nftPriceToPay
    ) internal {

        //  checks if the _minter address has a first level referrer, and it checks if the _referral1 address is not zero. If both conditions are true, it sets the _referral1 address as the first level referrer of the _minter address.
        if (referrers[_minter][0] == address(0) && _referral1 != address(0)) {

            // pdate the necessary mapping and arrays to record the first level referrer and the referral rewards for the _referral1 address.
            referrers[_minter][0] = _referral1;
            referees[_referral1].push(_minter);
            usersReferralRewards[_referral1] += ((_nftPriceToPay *
                referral1Tax) / 1000);
        }
        if (referrers[_minter][1] == address(0) && _referral2 != address(0)) {
            referrers[_minter][1] = _referral2;
            referees[_referral2].push(_minter);
            usersReferralRewards[_referral2] += ((_nftPriceToPay *
                referral2Tax) / 1000);
        }
        if (referrers[_minter][2] == address(0) && _referral3 != address(0)) {
            referrers[_minter][2] = _referral3;
            referees[_referral3].push(_minter);
            usersReferralRewards[_referral3] += ((_nftPriceToPay *
                referral3Tax) / 1000);
        }
    }


    // This is an internal function called _mintNft which mints an NFT to the given address based on the provided _index parameter. 
    function _mintNft(address _to, uint256 _index) internal {
        if (_index == 1) {
            nftCollection.mintLemur(_to);
        } else if (_index == 2) {
            nftCollection.mintRhino(_to);
        } else if (_index == 3) {
            nftCollection.mintGorilla(_to);
        } else {
            revert("Invalid token index");
        }
    }
}
