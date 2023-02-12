// SPDX-License-Identifier: MIT
// Creator: andreitoma8
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

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
        uint256 nftPriceToPay = nftPrices[nftIndex - 1];
        require(
            feeToken.allowance(_msgSender(), address(this)) >= nftPriceToPay,
            "Approve Staking contract"
        );
        // Deduct tax
        feeToken.transferFrom(_msgSender(), address(this), nftPriceToPay);
        uint256 refReward = (nftPriceToPay *
            (referral1Tax + referral2Tax + referral3Tax)) / 1000;

        uint256 treasuryAmount = (treasuryFee * (nftPriceToPay - refReward)) /
            100;
        feeToken.transfer(TREASURY, treasuryAmount);

        // Mint fee token
        if (feeToken.totalSupply() < maxSupply) {
            feeToken.mint(address(this), nftPrices[nftIndex - 1]);
        }
        _mintNft(to, nftIndex);
        _runReferralSystem(
            _msgSender(),
            referral1,
            referral2,
            referral3,
            nftPriceToPay
        );
    }

    // If address already has ERC721 Token/s staked, calculate the rewards.
    // For every new Token Id in param transferFrom user to this Smart Contract,
    // increment the amountStaked and map msg.sender to the Token Ids of the staked
    // Token to later send back on withdrawal. Finally give timeOfLastUpdate the
    // value of now.
    function stake(uint256[] calldata _tokenIds) external nonReentrant {
        // Maintain minimum amount of the reward token
        if (
            rewardsToken.balanceOf(address(this)) < minBalance &&
            rewardsToken.totalSupply() < maxSupply
        ) {
            rewardsToken.mint(address(this), minBalance);
        }

        if (stakers[_msgSender()].amountStaked > 0) {
            uint256 rewards = calculateRewards(_msgSender());
            stakers[_msgSender()].unclaimedRewards += rewards;
            updateUserPool(_msgSender());
        } else {
            stakersArray.push(_msgSender());
        }

        uint256 len = _tokenIds.length;
        for (uint256 i; i < len; ++i) {
            require(!stakedBefore[_tokenIds[i]], "Can't Restake A Token");
            uint256 index = getIndexForId(_tokenIds[i]);
            require(
                nftCollection.ownerOf(_tokenIds[i]) == _msgSender(),
                "Can't Stake Token You Don't Own!"
            );

            require(
                nftCollection.isApprovedForAll(_msgSender(), address(this)),
                "Approve Staker For The Nft"
            );

            nftCollection.transferFrom(
                _msgSender(),
                address(this),
                _tokenIds[i]
            );

            // Mint extra reward token
            rewardsToken.mint(address(this), extraMintAmount[index - 1]);

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
        stakers[_msgSender()].amountStaked += len;
        stakers[_msgSender()].timeOfLastUpdate = block.timestamp;
        emit Staked(_tokenIds, _msgSender());
    }

    // Check if user has any ERC721 Tokens Staked and if he tried to withdraw,
    // calculate the rewards and store them in the unclaimedRewards and for each
    // ERC721 Token in param: check if msg.sender is the original staker, decrement
    // the amountStaked of the user and transfer the ERC721 token back to them
    function withdraw(uint256[] calldata _tokenIds) external nonReentrant {
        Staker storage __staker = stakers[_msgSender()];

        require(__staker.amountStaked > 0, "You Have No Tokens Staked");
        uint256 rewards = calculateRewards(_msgSender());
        updateUserPool(_msgSender());
        uint256 userFunds = __staker.fundsDeposited;

        // Check if whale txn and deduce tax accordingly
        uint256 whaleFee = getWhaleFee(userFunds);
        uint256 len = _tokenIds.length;
        __staker.unclaimedRewards += (rewards -
            ((basicWithdrawalFee * rewards * len) / 100) -
            ((whaleFee * rewards * len) / 100));

        for (uint256 i; i < len; ++i) {
            require(stakerAddress[_tokenIds[i]] == _msgSender());
            stakerAddress[_tokenIds[i]] = address(0);
            nftCollection.transferFrom(
                address(this),
                _msgSender(),
                _tokenIds[i]
            );
        }

        __staker.amountStaked -= len;
        __staker.timeOfLastUpdate = block.timestamp;
        if (__staker.amountStaked == 0) {
            for (uint256 i; i < stakersArray.length; ++i) {
                if (stakersArray[i] == _msgSender()) {
                    stakersArray[i] = stakersArray[stakersArray.length - 1];
                    stakersArray.pop();
                }
            }
        }

        emit Withdrawn(_tokenIds, _msgSender());
    }

    // Calculate rewards for the msg.sender, check if there are any rewards
    // claim, set unclaimedRewards to 0 and transfer the ERC20 Reward token
    // to the user.
    function claimRewards() external {
        uint256 rewards = calculateRewards(_msgSender()) +
            stakers[_msgSender()].unclaimedRewards;
        updateUserPool(_msgSender());

        require(rewards > 0, "You have no rewards to claim");
        stakers[_msgSender()].timeOfLastUpdate = block.timestamp;
        stakers[_msgSender()].unclaimedRewards = 0;
        rewardsToken.transfer(_msgSender(), rewards);
    }

    function claimReferralRewards() external {
        require(
            nftCollection.balanceOf(_msgSender()) > 0,
            "You Need To Have ZOO Nft"
        );

        if (refwithdrawalTime[_msgSender()] > 0) {
            require(
                (block.timestamp - refwithdrawalTime[_msgSender()]) >= 1 days,
                "Referral Reward Is Only Claimed Per Day"
            );
        }
        uint256 refRewards = usersReferralRewards[_msgSender()];
        usersReferralRewards[_msgSender()] = 0;
        rewardsToken.transfer(_msgSender(), refRewards);
        refwithdrawalTime[_msgSender()] = block.timestamp;
    }

    function feedYourAnimal(uint256 _tokenId) external nonReentrant {
        uint256 nftIndex = getIndexForId(_tokenId);
        uint256 foodPrice = foodPrices[nftIndex - 1];
        require(
            feeToken.allowance(_msgSender(), address(this)) >= foodPrice,
            "Approve Staking Contract"
        );
        feeToken.transferFrom(_msgSender(), address(this), foodPrice);

        StakedNft[] storage userStakedNfts = stakedNfts[_msgSender()];
        uint256 len = userStakedNfts.length;

        for (uint256 i; i < len; i++) {
            if (userStakedNfts[i].id == _tokenId) {
                userStakedNfts[i].feedCounter += 1;
                userStakedNfts[i].lastTimeFed = block.timestamp;

                emit AnimalFed(nftIndex, _msgSender(), foodPrice);
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
        require(_nftIndex > 0 && _nftIndex < 4, "Invalid Index");
        address[] memory _stakers = stakersArray;
        uint256 len = _stakers.length;
        for (uint256 i; i < len; ++i) {
            address user = _stakers[i];
            stakers[user].unclaimedRewards += calculateRewards(user);
            updateUserPool(user);
            stakers[user].timeOfLastUpdate = block.timestamp;
        }
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

    function getWhaleFee(uint256 _userFunds) internal view returns (uint256) {
        uint256 rewardTokenBalance = rewardsToken.balanceOf(address(this));
        uint256 ratio = (_userFunds * MULTIPLIER) / rewardTokenBalance;
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

    function isHungry(uint256 _tokenId) public view returns (bool) {
        bool _isHungry;
        address _staker = stakerAddress[_tokenId];
        require(_staker != address(0), "Nft Is Not Staked");
        Staker memory staker = stakers[_staker];
        StakedNft[] memory _stakedNfts = stakedNfts[_staker];
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
        Staker memory staker = stakers[staker_];
        StakedNft[] memory _stakedNfts = stakedNfts[staker_];

        uint256 accRewards;
        for (uint256 i; i < staker.amountStaked; i++) {
            uint256 _index = getIndexForId(_stakedNfts[i].id);
            if (!_stakedNfts[i].expired) {
                if (
                    stakerAddress[_stakedNfts[i].id] == staker_ &&
                    (block.timestamp - _stakedNfts[i].timeStaked <=
                        rewardDays[_index - 1])
                ) {
                    // Check if NFT has NOT expired
                    if (
                        (block.timestamp - _stakedNfts[i].lastTimeFed) <=
                        30 days
                    ) {
                        accRewards +=
                            ((block.timestamp - staker.timeOfLastUpdate) *
                                rewardsPerDay[_index - 1] *
                                nftPrices[_index - 1]) /
                            (1000 * 86400);
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
        return accRewards;
    }

    /////////////
    // Internal//
    /////////////

    function updateUserPool(address staker_) internal {
        Staker storage staker = stakers[staker_];
        StakedNft[] storage _stakedNfts = stakedNfts[staker_];

        for (uint256 i; i < staker.amountStaked; i++) {
            uint256 _index = getIndexForId(_stakedNfts[i].id);
            if (!_stakedNfts[i].expired) {
                if (
                    stakerAddress[_stakedNfts[i].id] == staker_ &&
                    (block.timestamp - _stakedNfts[i].timeStaked <=
                        rewardDays[_index - 1])
                ) {
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

    function _runReferralSystem(
        address _minter,
        address _referral1,
        address _referral2,
        address _referral3,
        uint256 _nftPriceToPay
    ) internal {
        if (referrers[_minter][0] == address(0) && _referral1 != address(0)) {
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
