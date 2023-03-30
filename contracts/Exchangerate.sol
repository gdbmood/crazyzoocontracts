//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract check {
    using SafeMath for uint256;
    address public feeNftStaking;
    address public feeMarketing;
    address public liquidtyPoolContract;
    AggregatorV3Interface public Price;

    uint256 public MarketingFee;
    uint256 public StakingFee;
    uint256 public referralFee;
    mapping(address => address) public referral;

    uint256 public TokenPrice = 1;

    constructor(
        // address _feeNftStaking,
        // address _feeMarketing,
        // address _liquidtyPoolContract
    ) {
        // feeNftStaking = _feeNftStaking;
        // feeMarketing = _feeMarketing;
        // liquidtyPoolContract = _liquidtyPoolContract;
        Price = AggregatorV3Interface(
            0x0715A7794a1dc8e42615F059dD6e406A6594651A
        );
    }

    function SetReferral(address _referral) public returns (bool) {
        require(referral[msg.sender] != address(0),"You are Setting undefined address");
        referral[msg.sender] = _referral;
        return true;
    }

    function setFees(
        uint256 _marketingFee,
        uint256 _stakingFee,
        uint256 _referralFee
    ) public {
        require(_marketingFee > 0, "Marketing fee must be greater than 0");
        require(_stakingFee > 0, "Staking fee must be greater than 0");
        require(_referralFee > 0, "Referral fee must be greater than 0");
        MarketingFee = _marketingFee;
        StakingFee = _stakingFee;
        referralFee = _referralFee;
    }

    function LastestPrice() public view returns (uint256) {
        (, int256 price, , , ) = Price.latestRoundData(); // Get the latest price data from the price feed
        // uint256 usdToEthPrice = uint256(1e36/ price); // Calculate the USD to ETH conversion rate
        uint256 EthToUsd = uint256(price);
        uint256 UsdToEth = (1 ether * 1e8) / EthToUsd;
        return UsdToEth;
    }

    function totalExcludingTax(uint256 _tokens) public view returns (uint256) {
        uint256 ValuePrice = LastestPrice();
        uint256 Totaldollars = TokenPrice * _tokens;
        uint256 TotalPrice = ValuePrice * Totaldollars;
        return TotalPrice;
    }

    function check(uint256 _tokens) public returns(uint256){
        uint256 actualAmount = totalExcludingTax(_tokens);
    }

    function totalInludingTax(uint256 _tokens) public view returns (uint256) {
        uint256 actualAmount = totalExcludingTax(_tokens);
        uint256 Marketing = actualAmount.mul(MarketingFee).div(1000);
        uint256 Staking = actualAmount.mul(StakingFee).div(1000);
        
        uint256 _TotalAmount = Staking +
            Marketing +
            actualAmount;
        return _TotalAmount;
    }

    function calculateFees(uint256 totalAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {   
        uint256 _refferal;
        uint256 Marketing = totalAmount.mul(MarketingFee).div(1000);
        uint256 Staking = totalAmount.mul(StakingFee).div(1000);

        if (referral[msg.sender] != address(0)) {
            _refferal = totalAmount.mul(referralFee).div(1000);
        } else {
            _refferal = 0;
        }

        uint256 liquidityContractAmount = totalAmount
            .sub(Marketing)
            .sub(Staking)
            .sub(_refferal);
        return (
            Marketing,
            Staking,
            _refferal,
            liquidityContractAmount
        );
    }

    function transferFees(uint256 _tokens) external payable {
        uint256 total = totalInludingTax(_tokens);
        require(msg.value >= total, "Insufficient amount");
        (
            uint256 _feeMarketingAmount,
            uint256 _feeNftStakingAmount,
            uint256 _referral,
            uint256 _liquidityContractAmount
        ) = calculateFees(msg.value);
        payable(feeMarketing).transfer(_feeMarketingAmount);
        payable(feeNftStaking).transfer(_feeNftStakingAmount);
        payable(liquidtyPoolContract).transfer(_liquidityContractAmount);
        if(_referral > 0){
            payable(referral[msg.sender]).transfer(_referral);
        }
    }

}


