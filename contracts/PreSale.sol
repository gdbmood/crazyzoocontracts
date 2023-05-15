// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {
    address public owner;

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
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

    function myReferrer(address _myAddress) external view returns (address);
}

interface IUSDTToken {
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

contract PreSale is Pausable {
    using SafeMath for uint256;

    IZooToken public ZooToken;
    IUSDTToken public UsdtToken;

    address public collectorWallet;

    uint256 public USDTRaised;

    uint256 public cap;

    uint256 public mintedTokens;

    uint256 public minInvestment;

    uint256 public maxInvestment;

    uint256 public rate;

    uint256 public reffererFee;

    uint256 public ZooTokenDecimal = 1000000;

    uint256 public startTime;

    uint256 public endTime;

    mapping(address => uint256) public userBalance;

    event _startPreSale(
        address collectorWallet,
        uint256 cap,
        uint256 rate,
        uint256 minInvestment,
        uint256 maxInvestment,
        uint256 reffererFee,
        uint256 startTime,
        uint256 endTime
    );
    event _changeMinInvestment(uint256 minInvestment);
    event _changeMaxInvestment(uint256 maxInvestment);
    event _changeCap(uint256 cap);
    event _changeReffererFee(uint256 reffererFee);
    event _buyZooTokens(
        address indexed purchaser,
        address indexed beneficiary,
        uint256 amount,
        uint256 investorsTokens,
        uint256  tokens,
        uint256 reffererTokens
    );
    event _changeZooTokenDecimal(uint256 ZooTokenDecimal);
    event _changeCollectorWallet(address collectorWallet);
    event _x(uint256 tokens);

    function startPreSale(
        address _collectorWallet,
        uint256 _cap,
        uint256 _rate,
        uint256 _minInvestment,
        uint256 _maxInvestment,
        uint256 _reffererFee,
        uint256 _endTime,
        IZooToken _ZooToken,
        IUSDTToken _UsdtToken
    ) public onlyOwner {
        require(_collectorWallet != address(0));
        require(_ZooToken != IZooToken(address(0)));
        require(_UsdtToken != IUSDTToken(address(0)));
        require(_rate > 0);
        require(
            _minInvestment >= _rate,
            "minimum investment should be greater than or equal to rate of token"
        );
        require(
            _minInvestment < _maxInvestment,
            "maximum investment should be greater than or equal to rate of token"
        );
        require(_reffererFee > 0);
        require(_endTime > block.timestamp, "endtime is incorrect");

        collectorWallet = _collectorWallet;
        rate = _rate;
        minInvestment = _minInvestment; //minimum investment in wei  (=10 ether)
        maxInvestment = _maxInvestment;
        cap = _cap; //cap in tokens base units (=295257 tokens)
        reffererFee = _reffererFee;
        startTime = block.timestamp;
        endTime = _endTime;
        ZooToken = _ZooToken;
        UsdtToken = _UsdtToken;

        emit _startPreSale(
            collectorWallet,
            cap,
            rate,
            minInvestment,
            maxInvestment,
            reffererFee,
            startTime,
            endTime
        );
    }

    /**
     * Low level token purchse function
     * @param beneficiary will recieve the tokens.
     */
    function buyZooTokens(
        address beneficiary,
        uint256 _inputAmount
    ) public whenNotPaused {
        //checking address and minimum investment
        require(beneficiary != address(0));
        require(_inputAmount >= minInvestment);
        require(block.timestamp < endTime,"sale has ended");

        //checking cap
        uint256 tokens = ((_inputAmount * ZooTokenDecimal) / rate);
        require(tokens + mintedTokens <= cap,"you are exceeding the cap");

        // checking maximum
        require(userBalance[beneficiary] <= maxInvestment, "you have purchased maximum tokens");
        
        UsdtToken.transferFrom(beneficiary, address(this), _inputAmount);

        // update USDTRaised
        USDTRaised = USDTRaised.add(_inputAmount);
        mintedTokens += tokens;

        //updating user balance
        userBalance[beneficiary] += _inputAmount ;

        //tokens for referrer
        uint256 reffererTokens;
        address refferer = ZooToken.myReferrer(beneficiary);
        if (refferer != address(0)) {
            reffererTokens = ((reffererFee / 100) * tokens) / ZooTokenDecimal;
            ZooToken.mint(refferer, reffererTokens);
        }

        // tokens for beneficiary
        uint256 investorsTokens = tokens - reffererTokens;
        
        ZooToken.mint(beneficiary, investorsTokens);

        UsdtToken.transfer(collectorWallet, _inputAmount);

        emit _buyZooTokens(msg.sender, beneficiary, _inputAmount, investorsTokens,tokens,reffererTokens);
    }
     
    function changeReffererFee(uint256 fee) public onlyOwner {
        require(fee > 0);
        reffererFee = fee;
        emit _changeReffererFee(reffererFee);
    }

    function changeCap(uint256 _cap) public onlyOwner {
        require(_cap > 0);
        require(_cap > mintedTokens);
        cap = _cap;
        emit _changeCap(cap);
    }

    function changeMinInvestment(uint256 _minInvestment) public onlyOwner {
        require(_minInvestment >= rate);

        minInvestment = _minInvestment;
        emit _changeMinInvestment(minInvestment);
    }

    function changeMaxInvestment(uint256 _maxInvestment) public onlyOwner {
        require(_maxInvestment > minInvestment);

        maxInvestment = _maxInvestment;
        emit _changeMaxInvestment(maxInvestment);
    }
    function changeCollectorWallet(address _CollectorWallet) public onlyOwner {
        require(_CollectorWallet != address(0));
        collectorWallet = _CollectorWallet;
        emit _changeCollectorWallet(collectorWallet);
    }

    function hasEnded() public view returns (bool) {
        bool capReached = (mintedTokens >= cap) || block.timestamp > endTime;
        return capReached;
    }

    function getEndTime() public view returns (uint256) {
        return endTime;
    }

    function getTotalMinted() public view returns (uint256) {
        return mintedTokens;
    }
    function getPriceOfToken() public view returns (uint256) {
        return rate;
    }
    function getMinInvestment() public view returns (uint256) {
        return minInvestment;
    }
    function getMaxInvestment() public view returns (uint256) {
        return maxInvestment;
    }
    function getUserBalance(address user) public view returns (uint256) {
        return userBalance[user];
    }
    function getCap() public view returns (uint256) {
        return cap;
    }

}
