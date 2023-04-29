// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

import "./CrazyZooStaking.sol";

contract TestingStakingContract is CrazyZooStaking {
    constructor(
        INftCollection _nftCollection,
        address __USDCToken,
        ISingleSwap _SingleSwap,
        IZooToken _ZooToken,
        address _owner
    )
        CrazyZooStaking(
            _nftCollection,
            __USDCToken,
            _SingleSwap,
            _ZooToken,
            _owner
        )
    {}

    event _testfeedYourAnimal(uint256 feedCounter, uint256 lastTimeFed);

    //when  user has feed animal within 30 days.
    function _1_testCalculateRewards(address _address, uint256 _days) public {
        for (uint256 i = 1; i < 2; i += 1) {
            StakedNft memory _stakedNft;
            _stakedNft.id = i;
            _stakedNft.feedCounter = 0;
            _stakedNft.lastTimeFed = block.timestamp - (25 days + i * 1 days);
            _stakedNft.timeStaked = block.timestamp - 365 days;
            stakedNfts[_address].push(_stakedNft);
            stakers[_address].fundsDeposited += 250000000;
            stakerAddress[i] = _address;
        }
        stakers[_address].amountStaked += 1;
        stakers[_address].timeOfLastUpdate = block.timestamp - _days * 1 days;
        stakersArray.push(_address);
    }

    //when it has 30 days since the user didn't feed animal.
    function _2_testCalculateRewards(address _address, uint256 _days) public {
        for (uint256 i = 1; i < 2; i += 1) {
            StakedNft memory _stakedNft;
            _stakedNft.id = i;
            _stakedNft.feedCounter = 0;
            _stakedNft.lastTimeFed = block.timestamp - (29 days + i * 1 days);
            _stakedNft.timeStaked = block.timestamp - 365 days;
            stakedNfts[_address].push(_stakedNft);
            stakers[_address].fundsDeposited += 250000000;
            stakerAddress[i] = _address;
        }
        stakers[_address].amountStaked += 1;
        stakers[_address].timeOfLastUpdate = block.timestamp - _days * 1 days;
    }

    //when timestaked has exceed reward days
    function _3_testCalculateRewards(address _address, uint256 _days) public {
        for (uint256 i = 1; i < 2; i += 1) {
            StakedNft memory _stakedNft;
            _stakedNft.id = i;
            _stakedNft.feedCounter = 0;
            _stakedNft.lastTimeFed = block.timestamp - (29 days + i * 1 days);
            _stakedNft.timeStaked = block.timestamp - 600 days;
            stakedNfts[_address].push(_stakedNft);
            stakers[_address].fundsDeposited += 250000000;
            stakerAddress[i] = _address;
        }
        stakers[_address].amountStaked += 1;
        stakers[_address].timeOfLastUpdate = block.timestamp - _days * 1 days;
    }

    function testUpdateUserPool(address _address) public {
        updateUserPool(_address);
    }

    //less than 30 days.
    function testSetRewardsPerDay(address _address) public {
        _1_testCalculateRewards(_address, 15);
        setRewardsPerDay(1, 5);
    }

    function testSetRewardDays(address _address) public {
        _1_testCalculateRewards(_address, 15);
        // Staker memory staker = stakers[_address];
        if (stakers[_address].unclaimedRewards == 0) {
            setRewardDays(2, 500);
        }
    }

    function _1_testIsHungry(address _address) public {
        for (uint256 i = 0; i < 1; i += 1) {
            StakedNft memory _stakedNft;
            _stakedNft.id = i;
            _stakedNft.lastTimeFed = block.timestamp - (28 days + i * 1 days);
            stakedNfts[_address].push(_stakedNft);
            stakerAddress[i] = _address;
        }
        stakers[_address].amountStaked += 1;
    }

    function _2_testIsHungry(address _address) public {
        for (uint256 i = 0; i < 1; i += 1) {
            StakedNft memory _stakedNft;
            _stakedNft.id = i;
            _stakedNft.lastTimeFed = block.timestamp - (31 days + i * 1 days);
            stakedNfts[_address].push(_stakedNft);
            stakerAddress[i] = _address;
        }
        stakers[_address].amountStaked += 1;
    }

    function _1_testfeedYourAnimal(address _address) public {
        StakedNft memory _stakedNft;
        for (uint256 i = 1; i < 2; i += 1) {
            _stakedNft.id = i;
            _stakedNft.feedCounter = 0;
            _stakedNft.lastTimeFed = block.timestamp - 25 days;
            stakedNfts[_address].push(_stakedNft);
        }
        StakedNft[] storage userStakedNfts = stakedNfts[_address];
        emit _testfeedYourAnimal(
            userStakedNfts[0].feedCounter,
            userStakedNfts[0].lastTimeFed
        );
    }

    function _1_1_testfeedYourAnimal(
        address _address
    ) public view returns (uint256, uint256) {
        StakedNft[] storage userStakedNfts = stakedNfts[_address];
        return (userStakedNfts[0].feedCounter, userStakedNfts[0].lastTimeFed);
    }

    function _1_testClaimReward(address _address, uint256 _days) public {
        for (uint256 i = 1; i < 2; i += 1) {
            StakedNft memory _stakedNft;
            _stakedNft.id = i;
            _stakedNft.feedCounter = 0;
            _stakedNft.lastTimeFed = block.timestamp - (25 days + i * 1 days);
            _stakedNft.timeStaked = block.timestamp - 365 days;
            stakedNfts[_address].push(_stakedNft);
            stakers[_address].fundsDeposited += 250000000;
            stakerAddress[i] = _address;
        }
        stakers[_address].amountStaked += 1;
        stakers[_address].timeOfLastUpdate = block.timestamp - _days * 1 days;
        stakers[_address].unclaimedRewards = 1000000;
        stakersArray.push(_address);
    }

    
}
