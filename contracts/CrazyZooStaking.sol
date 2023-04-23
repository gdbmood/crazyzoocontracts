// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

// import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface INftCollection is IERC721 {
    function mintLemur(address to) external;

    function mintRhino(address to) external;

    function mintGorilla(address to) external;

    function getIndexForId(uint256 _id) external pure returns (uint256);

    function getFeeForId(uint256 _id) external view returns (uint256);

    function getExtraAmount(uint256 _id) external view returns (uint256);
}

interface IERC20USDC {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface ISingleSwap {
    function SellingUSDCToken(
        uint256 amountIn
    ) external returns (uint256 amountOut);
}

interface IZooToken {
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external;

    function mint(address to, uint256 amount) external;

    function transferFrom(address from, address to, uint256 value) external;

    function transfer(address to, uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);
}

contract CrazyZooStaking {
    address public _USDCToken;

    INftCollection public nftCollection;
    ISingleSwap public swap;
    IZooToken public ZooToken;
    IERC20USDC public immutable USDCToken = IERC20USDC(_USDCToken);

    //staking storage
    struct StakedNft {
        uint256 id;
        uint256 feedCounter;
        uint256 lastTimeFed;
        uint256 timeStaked;
        bool expired;
    }
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
    address[] public stakersArray;
    // Mapping of User Address to Staker info
    mapping(address => Staker) public stakers;
    // Mapping of User Address to StakedNft
    mapping(address => StakedNft[]) public stakedNfts;
    // Mapping of Token Id to staker. Made for the SC to remember
    // who to send back the ERC721 Token to.
    mapping(uint256 => address) public stakerAddress;
    mapping(uint256 => bool) public stakedBefore;

    // food price
    uint256[3] public foodPrices = [3.5 * 1e18, 7.5 * 1e18, 15 * 1e18];

    //rewards
    // 0 for Lemur, 1 for Rhino, 2 for Gorilla
    // 0.6 = 6/10, 0.7 = 7/10, 0.8 = 8/10
    uint256[3] public rewardsPerDay = [600000, 700000, 800000];
    // 0 for Lemur, 1 for Rhino, 2 for Gorilla
    uint256[3] public rewardDays = [500 days, 500 days, 500 days];

    address public owner;
    uint256 public ZooTokenDecimal = 1000000;
    uint256 public whalesWithdrawalExtraFee = 2500000;

    bool private locked;
    modifier nonReentrant() {
        require(!locked, "Reentrant call detected!");
        locked = true;
        _;
        locked = false;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor(
        INftCollection _nftCollection,
        address __USDCToken,
        ISingleSwap _SingleSwap,
        IZooToken _ZooToken,
        address _owner
    ) {
        nftCollection = _nftCollection;
        _USDCToken = __USDCToken;
        swap = _SingleSwap;
        owner = _owner;
        ZooToken = _ZooToken;
    }

    event Withdrawn(uint256[] indexed _tokenIds, address _to);
    event NewRewardsPerDay(uint256 _nftIndex, uint256 _newValue);

    // // TokenId parameter in the feedYourAnimal function is used to specify the ID of the NFT that the user wants to feed
    function feedYourAnimal(uint256 _tokenId) external nonReentrant {
        // returns the index of the NFT based on the _tokenId parameter.
        uint256 nftIndex = nftCollection.getIndexForId(_tokenId);
        // fetches the price of food for the NFT at the given nftIndex.
        uint256 foodPrice = foodPrices[nftIndex - 1];
        // checks if the contract has been approved to spend the required amount of feeToken tokens by the caller
        require(
            USDCToken.allowance(msg.sender, address(this)) >= foodPrice,
            "Approve Staking Contract"
        );

        // transfers the foodPrice amount of feeToken tokens from the caller to the contract.
        USDCToken.transferFrom(msg.sender, address(this), foodPrice);

        // fetches the array of StakedNft structs for the caller from the stakedNfts mapping.
        StakedNft[] storage userStakedNfts = stakedNfts[msg.sender];

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

                // emits the AnimalFed event with the nftIndex, msg.sender, and foodPrice parameters.
                // emit AnimalFed(nftIndex, msg.sender, foodPrice);

                // exits the function once the if condition is met, meaning that the appropriate StakedNft struct has been found and updated.
                return;
            }
        }
    }

    // function calculateRewards(address staker_) public view returns (uint256) {
    //     Staker memory staker = stakers[staker_];
    //     StakedNft[] memory _stakedNfts = stakedNfts[staker_];

    //     uint256 accRewards;
    //     for (uint256 i; i < staker.amountStaked; i++) {
    //         uint256 _index = nftCollection.getIndexForId(_stakedNfts[i].id);

    //         if (
    //             !_stakedNfts[i].expired &&
    //             stakerAddress[_stakedNfts[i].id] == staker_ &&
    //             (block.timestamp - _stakedNfts[i].timeStaked <= rewardDays[_index - 1])
    //         ) {

    //             uint256 TimeSinceLastFed = block.timestamp - _stakedNfts[i].lastTimeFed;
    //             uint256 daysOfRewards;

    //             if (TimeSinceLastFed <= 30 days) {
    //                     daysOfRewards = block.timestamp - staker.timeOfLastUpdate;

    //             } else {
    //                 uint256 timeNFTexpired = _stakedNfts[i].lastTimeFed + 30 days;
    //                 if(staker.timeOfLastUpdate < timeNFTexpired){
    //                     daysOfRewards = timeNFTexpired - staker.timeOfLastUpdate;
    //                 }
    //             }

    //             if(daysOfRewards > 1 days){
    //                 uint256 rewardRatePerDay = ((rewardsPerDay[_index - 1] / 100) * nftCollection.getFeeForId(_index))/ZooTokenDecimal;
    //                 accRewards += (daysOfRewards * rewardRatePerDay) / 86400;
    //             }
    //         }
    //     }
    //     return accRewards;
    // }

    function calculateRewards(address staker_) public view returns (uint256) {
        Staker memory staker = stakers[staker_];
        StakedNft[] memory _stakedNfts = stakedNfts[staker_];

        uint256 accRewards;
        for (uint256 i; i < staker.amountStaked; i++) {
            uint256 _index = nftCollection.getIndexForId(_stakedNfts[i].id);
            uint256 daysOfRewards;

            if (
                !_stakedNfts[i].expired &&
                stakerAddress[_stakedNfts[i].id] == staker_ &&
                (block.timestamp - _stakedNfts[i].timeStaked <=
                    rewardDays[_index - 1])
            ) {
                uint256 timeNFTexpired = _stakedNfts[i].lastTimeFed + 30 days;

                if (timeNFTexpired > block.timestamp) {
                    daysOfRewards = block.timestamp - staker.timeOfLastUpdate;
                } else {
                    daysOfRewards = timeNFTexpired - staker.timeOfLastUpdate;
                }

                if (daysOfRewards > 1 days) {
                    uint256 rewardRatePerDay = ((rewardsPerDay[_index - 1] /
                        100) * nftCollection.getFeeForId(_index)) /
                        ZooTokenDecimal;
                    accRewards += (daysOfRewards * rewardRatePerDay) / 86400;
                }
            }
        }
        return accRewards;
    }

    function updateUserPool(address staker_) internal {
        Staker storage staker = stakers[staker_];
        StakedNft[] storage _stakedNfts = stakedNfts[staker_];

        for (uint256 i; i < staker.amountStaked; i++) {
            uint256 _index = nftCollection.getIndexForId(_stakedNfts[i].id);
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

    function stakeNFT(uint256[] calldata _tokenIds) external nonReentrant {
        if (stakers[msg.sender].amountStaked > 0) {
            uint256 rewards = calculateRewards(msg.sender);
            stakers[msg.sender].unclaimedRewards += rewards;
            updateUserPool(msg.sender);
        } else {
            stakersArray.push(msg.sender);
        }

        uint256 len = _tokenIds.length;

        //  The loop iterates over the array of _tokenIds
        for (uint256 i; i < len; ++i) {
            //For each ERC721 token ID in the input array, it checks if the token has been staked before. If yes, it throws an error. as a token can only be staked once
            require(!stakedBefore[_tokenIds[i]], "Can't Restake A Token");
            uint256 index = nftCollection.getIndexForId(_tokenIds[i]);

            // It also checks if the caller is the owner of the token
            require(
                nftCollection.ownerOf(_tokenIds[i]) == msg.sender,
                "Can't Stake Token You Don't Own!"
            );
            require(
                nftCollection.isApprovedForAll(msg.sender, address(this)),
                "Approve Staker For The Nft"
            );

            nftCollection.transferFrom(msg.sender, address(this), _tokenIds[i]);

            //here we will swap zootoken from 250 usdc
            USDCToken.approve(
                _USDCToken,
                nftCollection.getFeeForId(index - 1) * 1e18
            );
            uint256 zoo_tokens = swap.SellingUSDCToken(
                nftCollection.getFeeForId(index - 1) * 1e18
            );

            stakerAddress[_tokenIds[i]] = msg.sender;
            StakedNft memory _stakedNft;
            _stakedNft.id = _tokenIds[i];
            _stakedNft.feedCounter = 0;
            _stakedNft.lastTimeFed = block.timestamp;
            _stakedNft.timeStaked = block.timestamp;
            stakedNfts[msg.sender].push(_stakedNft);
            stakers[msg.sender].fundsDeposited += zoo_tokens;
            stakedBefore[_tokenIds[i]] = true;
        }

        // the amountStaked variable of the staker's struct is incremented by the number of tokens being staked (len), indicating that the staker has staked additional tokens
        stakers[msg.sender].amountStaked += len;

        // setting the current time
        stakers[msg.sender].timeOfLastUpdate = block.timestamp;
    }

    function claimRewards() external {
        uint256 rewards = calculateRewards(msg.sender) +
            stakers[msg.sender].unclaimedRewards;
        updateUserPool(msg.sender);

        require(rewards > 0, "You have no rewards to claim");
        stakers[msg.sender].timeOfLastUpdate = block.timestamp;
        stakers[msg.sender].unclaimedRewards = 0;
        ZooToken.transfer(msg.sender, rewards * 1e6);
    }

    function getWhaleFee(uint256 _userFunds) public view returns (uint256) {
        uint256 rewardTokenBalance = ZooToken.balanceOf(address(this));
        if (
            _userFunds <
            ((((1 * ZooTokenDecimal) / 100) * rewardTokenBalance) /
                ZooTokenDecimal)
        ) {
            return 0;
        } else if (
            _userFunds <
            ((((2 * ZooTokenDecimal) / 100) * rewardTokenBalance) /
                ZooTokenDecimal)
        ) {
            return
                ((_userFunds / 100) * whalesWithdrawalExtraFee) /
                ZooTokenDecimal;
        } else if (
            _userFunds <
            ((((3 * ZooTokenDecimal) / 100) * rewardTokenBalance) /
                ZooTokenDecimal)
        ) {
            return
                ((_userFunds / 100) * (whalesWithdrawalExtraFee * 2)) /
                ZooTokenDecimal;
        } else if (
            _userFunds <
            ((((4 * ZooTokenDecimal) / 100) * rewardTokenBalance) /
                ZooTokenDecimal)
        ) {
            return
                ((_userFunds / 100) * (whalesWithdrawalExtraFee * 3)) /
                ZooTokenDecimal;
        } else if (
            _userFunds <
            ((((5 * ZooTokenDecimal) / 100) * rewardTokenBalance) /
                ZooTokenDecimal)
        ) {
            return
                ((_userFunds / 100) * (whalesWithdrawalExtraFee * 4)) /
                ZooTokenDecimal;
        } else if (
            _userFunds <
            ((((6 * ZooTokenDecimal) / 100) * rewardTokenBalance) /
                ZooTokenDecimal)
        ) {
            return
                ((_userFunds / 100) * (whalesWithdrawalExtraFee * 5)) /
                ZooTokenDecimal;
        } else if (
            _userFunds <
            ((((7 * ZooTokenDecimal) / 100) * rewardTokenBalance) /
                ZooTokenDecimal)
        ) {
            return
                ((_userFunds / 100) * (whalesWithdrawalExtraFee * 6)) /
                ZooTokenDecimal;
        } else if (
            _userFunds <
            ((((8 * ZooTokenDecimal) / 100) * rewardTokenBalance) /
                ZooTokenDecimal)
        ) {
            return
                ((_userFunds / 100) * (whalesWithdrawalExtraFee * 7)) /
                ZooTokenDecimal;
        } else {
            return
                ((_userFunds / 100) * (whalesWithdrawalExtraFee * 8)) /
                ZooTokenDecimal;
        }
    }

    function withdraw(uint256[] calldata _tokenIds) external nonReentrant {
        Staker storage __staker = stakers[msg.sender];

        require(__staker.amountStaked > 0, "You Have No Tokens Staked");
        uint256 rewards = calculateRewards(msg.sender);
        updateUserPool(msg.sender);
        uint256 userFunds = __staker.fundsDeposited;

        // Check if whale txn and deduce tax accordingly
        uint256 whaleFee = getWhaleFee(userFunds);
        uint256 len = _tokenIds.length;
        __staker.unclaimedRewards += rewards - (whaleFee * len);

        for (uint256 i; i < len; ++i) {
            require(stakerAddress[_tokenIds[i]] == msg.sender);
            stakerAddress[_tokenIds[i]] = address(0);
            nftCollection.transferFrom(address(this), msg.sender, _tokenIds[i]);
        }

        __staker.amountStaked -= len;
        __staker.timeOfLastUpdate = block.timestamp;

        //poping out user's tokens from stakersArray if it exist.
        if (__staker.amountStaked == 0) {
            for (uint256 i; i < stakersArray.length; ++i) {
                if (stakersArray[i] == msg.sender) {
                    stakersArray[i] = stakersArray[stakersArray.length - 1]; //swapping
                    stakersArray.pop();
                }
            }
        }

        emit Withdrawn(_tokenIds, msg.sender);
    }

    function setSwapAddress(address _swapAddress) public onlyOwner {
        require(_swapAddress != address(0), "address is undefined");
        swap = ISingleSwap(_swapAddress);
    }

    function setUsdcAddress(address usdcToken) public onlyOwner {
        require(usdcToken != address(0), "address is undefined");
        _USDCToken = usdcToken;
    }

    function setNFTAddress(address nftAddress) public onlyOwner {
        require(nftAddress != address(0), "address is undefined");
        nftCollection = INftCollection(nftAddress);
    }

    function setZooAddress(address ZooAddress) public onlyOwner {
        require(ZooAddress != address(0), "address is undefined");
        ZooToken = IZooToken(ZooAddress);
    }

    function setZooTokenDecimal(uint256 tokenDecimal) public onlyOwner {
        require(tokenDecimal >= 10, "should be atleast 1 decimal");
        ZooTokenDecimal = tokenDecimal;
    }

    function setwhalesWithdrawalExtraFee(uint256 fees) public onlyOwner {
        require(fees > 0, "value is undefined");
        whalesWithdrawalExtraFee = fees;
    }

    function getSwapAddress() public view returns (ISingleSwap) {
        return swap;
    }

    function getUsdcAddress() public view returns (address) {
        return _USDCToken;
    }

    function getNFTAddress() public view returns (INftCollection) {
        return nftCollection;
    }

    function getZooAddress() public view returns (IZooToken) {
        return ZooToken;
    }

    function getZooTokenDecimal() public view returns (uint256) {
        return ZooTokenDecimal;
    }

    function getwhalesWithdrawalExtraFee() public view returns (uint256) {
        return whalesWithdrawalExtraFee;
    }

    function setRewardsPerDay(
        uint256 _nftIndex,
        uint256 _newValue
    ) public onlyOwner {
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

    function getRewardsPerDay()
        public
        view
        returns (uint256, uint256, uint256)
    {
        return (rewardsPerDay[0], rewardsPerDay[0], rewardsPerDay[0]);
    }

    function setRewardDays(
        uint256 _nftIndex,
        uint256 _newDays
    ) public onlyOwner {
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
        // emit NewRewardDays(_nftIndex, _newDays);
    }

    function getRewardDays()
        public
        view
        returns (uint256, uint256, uint256)
    {
        return (rewardDays[0], rewardDays[0], rewardDays[0]);
    }

    function userStakeInfo(
        address _user
    ) public view returns (uint256 _tokensStaked, uint256 _availableRewards) {
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
}
// address public constant USDC_address = 0x0FA8781a83E46826621b3BC094Ea2A0212e71B23;
