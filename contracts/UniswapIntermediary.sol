// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";

import "hardhat/console.sol";

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

interface IUniswapV3Factory {
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );
}

interface IERC20ZooToken {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external;

    function transferFrom(address _from, address _to, uint256 _value) external;

    function _calculateFee(
        address user,
        uint256 value
    ) external view returns (uint256, uint256, uint256, uint256);

    function _shareFee(
        uint256 _feeNftStaking,
        uint256 _feeMarketing,
        uint256 _feeReferrer,
        address _user
    ) external;

    function getFeeCollectors(
        address user
    ) external returns (address, address, address);

    function approve(address spender, uint256 amount) external returns (bool);
}

interface IERC20Mock {
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

contract UniswapIntermediary {
    using SafeMath for uint256;

    address public RouterAddress;
    address public Zoo ;
    address public Factory ;
    address public QuoterAddress;
    mapping(address => bool) public OtherTokens;

    // For this example, we will set the pool fee to 0.3%.
    uint24 public poolFee;
    uint256 public _amountOutMinimum = 0;

    event _SellingZooToken(uint256 amountOut);
    event _SellingOtherToken(uint256 amountOut);
    event _ByingZoo(bool);
    event _setZooToken(address Zoo);
    event _setRouterAddress(address routerAddress);
    event _setOwner(address owner);
    event _setOtherToken(address _Other);
    event _setPoolFee(uint24 poolFee);
    event _setAmountOutMinimum(uint256 _amountOutMinimum);

    address public owner;
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor(address _routerAddress, address _Zoo, address _factory, address _QuoterAddress, uint24 _poolFee) {
        owner = msg.sender;
        RouterAddress = _routerAddress;
        Zoo = _Zoo;
        Factory = _factory;
        QuoterAddress = _QuoterAddress;
        poolFee = _poolFee;
    }

    //for selling token
    function swapExactInputSingle(
        uint256 amountIn,
        address tokenToGive,
        address TokenToTake
    ) internal returns (uint256 amountOut) {
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: tokenToGive,
                tokenOut: TokenToTake,
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp + 120,
                amountIn: amountIn,
                amountOutMinimum: _amountOutMinimum,
                sqrtPriceLimitX96: 0
            });

        amountOut = ISwapRouter(RouterAddress).exactInputSingle(params);
    }

    function SellingZooToken(uint256 amountIn, address OtherToken) public {
        require(OtherTokens[OtherToken], "token is undefined");

        //transfering Zoo token to this contract
        IERC20ZooToken(Zoo).transferFrom(msg.sender, address(this), amountIn);

        //calculating
        (   
            uint256 _StakingFees,
            uint256 _MarketingFee,
            uint256 _ReferrerFee,
            uint256 _fee
        ) = IERC20ZooToken(Zoo)._calculateFee(msg.sender, amountIn);

        TransferHelper.safeApprove(Zoo, RouterAddress, amountIn - _fee);

        uint256 amountOut = swapExactInputSingle(
            amountIn - _fee,
            Zoo,
            OtherToken
        );

        //sharing fees
        IERC20ZooToken(Zoo)._shareFee(
            _StakingFees,
            _MarketingFee,
            _ReferrerFee,
            msg.sender
        );

        //transfering other token to user
        IERC20Mock(OtherToken).transfer(msg.sender, amountOut);

        emit _SellingZooToken(amountOut);
    }

    function SellingOtherToken(uint256 amountIn, address OtherToken) public {
        require(OtherTokens[OtherToken], "token is undefined");

        //transfering Other token to this contract
        IERC20Mock(OtherToken).transferFrom(
            msg.sender,
            address(this),
            amountIn
        );

        TransferHelper.safeApprove(OtherToken, RouterAddress, amountIn);

        uint256 amountOut = swapExactInputSingle(amountIn, OtherToken, Zoo);

        //calculating
        (
            uint256 _StakingFees,
            uint256 _MarketingFee,
            uint256 _ReferrerFee,
            uint256 _fee
        ) = IERC20ZooToken(Zoo)._calculateFee(msg.sender, amountOut);

        //sharing fees
        IERC20ZooToken(Zoo)._shareFee(
            _StakingFees,
            _MarketingFee,
            _ReferrerFee,
            msg.sender
        );

        //transfering Zoo token to user
        IERC20ZooToken(Zoo).transfer(msg.sender, amountOut - _fee);

        emit _SellingOtherToken(amountOut);
    }

    function TokenSwapBYPressure(uint256 amountIn, address OtherToken) public returns(uint256) {
        require(OtherTokens[OtherToken], "token is undefined");

        //transfering Other token to this contract
        IERC20Mock(OtherToken).transferFrom(
            msg.sender,
            address(this),
            amountIn
        );

        TransferHelper.safeApprove(OtherToken, RouterAddress, amountIn);

        uint256 amountOut = swapExactInputSingle(amountIn, OtherToken, Zoo);

        //transfering Zoo token to user
        IERC20ZooToken(Zoo).transfer(msg.sender, amountOut);

        emit _SellingOtherToken(amountOut);

        return amountOut;
    }

    function swapExactOutputSingle(
        uint256 amountOut,
        uint256 amountInMaximum,
        address tokenToGive,
        address TokenToTake
    ) internal returns (uint256 amountIn) {
        ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter
            .ExactOutputSingleParams({
                tokenIn: tokenToGive,
                tokenOut: TokenToTake,
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp + 60,
                amountOut: amountOut,
                amountInMaximum: amountInMaximum,
                sqrtPriceLimitX96: 0
            });

        amountIn = ISwapRouter(RouterAddress).exactOutputSingle(params);
    }

    function ByingZoo(
        uint256 amountOut,
        uint256 amountInMaximum,
        address OtherToken
    ) public returns (bool) {
        require(OtherTokens[OtherToken], "token is undefined");

        IERC20Mock(OtherToken).transferFrom(
            msg.sender,
            address(this),
            amountInMaximum
        );

        TransferHelper.safeApprove(OtherToken, RouterAddress, amountInMaximum);

        uint256 spendAmount = swapExactOutputSingle(
            amountOut,
            amountInMaximum,
            OtherToken,
            Zoo
        );

        if (spendAmount < amountInMaximum) {
            IERC20Mock(OtherToken).approve(RouterAddress, 0);
            IERC20Mock(OtherToken).transfer(
                msg.sender,
                amountInMaximum - spendAmount
            );
        }

        //calculating
        (
            uint256 _StakingFees,
            uint256 _MarketingFee,
            uint256 _ReferrerFee,
            uint256 _fee
        ) = IERC20ZooToken(Zoo)._calculateFee(msg.sender, amountOut);

        //sharing fees
        IERC20ZooToken(Zoo)._shareFee(
            _StakingFees,
            _MarketingFee,
            _ReferrerFee,
            msg.sender
        );

        IERC20ZooToken(Zoo).transfer(msg.sender, amountOut - _fee);

        emit _ByingZoo(true);

        return true;
    }
    function setZooToken(address _Zoo) public onlyOwner {
        Zoo = _Zoo;
        emit _setZooToken(Zoo);
    }
    function setOtherToken(address _Other, bool _value) public onlyOwner {
        OtherTokens[_Other] = _value;
        emit _setOtherToken(_Other);
    }
    function setRouterAddress(address _routerAddress) public onlyOwner {
        RouterAddress = _routerAddress;
        emit _setRouterAddress(RouterAddress);
    }
    function setOwner(address _owner) public onlyOwner {
        owner = _owner;
        emit _setOwner(owner);
    }
    function setFactory(address _uniswapAddress) public returns (bool) {
        require(_uniswapAddress != address(0), "0 address is not acceptable");
        Factory = _uniswapAddress;
        return true;
    }

    function setAmountOutMinimum(uint256 __amountOutMinimum) public onlyOwner {
        _amountOutMinimum = __amountOutMinimum;
        emit _setAmountOutMinimum(_amountOutMinimum);
    }

    function setPoolFee(uint24 _poolFee) public onlyOwner {
        poolFee = _poolFee;
        emit _setPoolFee(poolFee);
    }
    
    function getQuote_AmountReceived(uint256 amountIn, address tokenIn, address tokenOut)public returns(uint256 amountOut){
        amountOut = IQuoter(QuoterAddress).quoteExactInputSingle(tokenIn, tokenOut, poolFee, amountIn, 0); 
    }
    function getQuote_AmountRequired(uint256 amountOut, address tokenIn, address tokenOut)public returns(uint256 amountIn){
        amountIn = IQuoter(QuoterAddress).quoteExactOutputSingle(tokenIn, tokenOut, poolFee, amountOut, 0); 
    }
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) public view returns (address) {
        return IUniswapV3Factory(Factory).getPool(tokenA, tokenB, fee);
    }

    function CurrentPrice(
        address tokenA,
        address tokenB,
        uint24 fee
    ) public view returns (uint256) {
        address poolAddress = getPool(tokenA, tokenB, fee);
        IUniswapV3Factory pool = IUniswapV3Factory(poolAddress);
        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();
        uint256 sqrtPrice = sqrtPriceX96;
        uint256 price = sqrtPrice.mul(sqrtPrice).div(1 << 192);
        return price;
    }

    function calculateTotalPrice(
        uint256 pricePerToken,
        uint256 numberOfZooTokens
    ) public pure returns (uint256) {
        uint256 totalPriceIn12Decimals = pricePerToken * numberOfZooTokens;
        uint256 totalPriceIn6Decimals = totalPriceIn12Decimals / (10 ** 6);
        return totalPriceIn6Decimals;
    }

    
    function getRouterAddress() public view returns (address) {
        return RouterAddress;
    }

    function getZooToken() public view returns (address) {
        return Zoo;
    }

    function getPoolFee() public view returns (uint256) {
        return poolFee;
    }

    function checkOtherToken(
        address _Other
    ) public view onlyOwner returns (bool) {
        return OtherTokens[_Other];
    }

    function getAmountOutMinimum () public view returns(uint256) {
        return _amountOutMinimum;
    }

    function getOwner() public view returns (address) {
        return owner;
    }


}

// swapExactInputSingle:
// This function is swapping the LINK token for WETH token using the swapRouter contract.
// The first line of the function is linkToken.approve(address(swapRouter), amountIn). This line is calling the approve function of the LINK token contract to allow the swapRouter contract to transfer amountIn of LINK tokens from the user's account.

// The next line of the function creates a memory variable named params of type ISwapRouter.ExactInputSingleParams. This is a struct that is used as an input to the exactInputSingle function of the swapRouter contract. The struct is being populated with the following values:

//     tokenIn: LINK: the token being swapped in, in this case the LINK token.
//     tokenOut: WETH: the token being swapped out, in this case the WETH token.
//     fee: poolFee: the pool fee for the swap, in this case it is set to 0.3%.
//     recipient: address(this): the recipient of the swapped tokens, in this case it is the SingleSwap contract itself.
//     deadline: block.timestamp: the deadline for the swap, in this case it is set to the current block timestamp.
//     amountIn: amountIn: the amount of LINK token to be swapped, it is the input argument amountIn.
//     amountOutMinimum: 0: the minimum amount of WETH token to be received in the swap, in this case it is set to 0.
//     sqrtPriceLimitX96: 0: the square root of the price limit, in this case it is set to 0.

// The final line of the function calls the exactInputSingle function of the swapRouter contract, passing in the params struct as the input. The result of this function call is stored in the amountOut variable and returned by the function.

// step-by-step explanation of the swapExactInputSingle function:

//     The function takes in the amountIn argument, which is the exact amount of DAI that will be swapped for WETH9.
//     The first step is to transfer the specified amount of DAI from the caller's address (msg.sender) to the smart contract's address (address(this)) using the TransferHelper.safeTransferFrom function. This ensures that the smart contract holds the necessary DAI to execute the swap.
//     The next step is to approve the swap router (swapRouter) to spend the specified amountIn of DAI using the TransferHelper.safeApprove function. This is necessary for the swap router to be able to transfer the DAI on behalf of the smart contract.
//     The function then creates an ExactInputSingleParams struct that specifies the swap details, including the token input (DAI), the token output (WETH9), the swap fee, the recipient of the output tokens (the caller's address), the deadline for the swap, the exact input amount (amountIn), the minimum output amount (set to 0 in this example), and the square root price limit (set to 0 to ensure that the exact input amount is swapped).
//     The final step is to call the exactInputSingle function of the swapRouter interface, passing in the params struct as an argument. This executes the swap and returns the amount of WETH9 received in the swap.

// step-by-step explanation of the swapExactOutputSingle function:

//     The function takes in two arguments: amountOut, which is the exact amount of WETH9 that will be received from the swap, and amountInMaximum, which is the maximum amount of DAI that the caller is willing to spend to receive amountOut.
//     The first step is to transfer the maximum specified amount of DAI (amountInMaximum) from the caller's address (msg.sender) to the smart contract's address (address(this)) using the TransferHelper.safeTransferFrom function. This ensures that the smart contract holds the maximum amount of DAI that the caller is willing to spend for the swap.
//     The next step is to approve the swap router (swapRouter) to spend the specified amountInMaximum of DAI using the TransferHelper.safeApprove function. This is necessary for the swap router to be able to transfer the DAI on behalf of the smart contract.
//     The function then creates an ExactOutputSingleParams struct that specifies the swap details, including the token input (DAI), the token output (WETH9), the swap fee, the recipient of the output tokens (the caller's address), the deadline for the swap, the exact output amount (amountOut), the maximum input amount (amountInMaximum), and the square root price limit (set to 0 to ensure that the exact output amount is received).
//     The final step is to call the exactOutputSingle function of the swapRouter interface, passing in the params struct as an argument. This executes the swap and returns the amount of DAI actually spent in the swap to receive the desired amountOut.
//     If the amount of DAI actually spent in the swap (amountIn) is less than the specified maximum amount of DAI (amountInMaximum), the function refunds the difference to the caller using the TransferHelper.safeTransfer function and revokes the approval for the swap router to spend the DAI by calling TransferHelper.safeApprove with a value of 0.
// In summary, the swapExactOutputSingle function swaps a minimum possible amount of DAI for a fixed amount of WETH9

// Polygon Mainnet: 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270
// Polygon Testnet (Mumbai): 0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889
