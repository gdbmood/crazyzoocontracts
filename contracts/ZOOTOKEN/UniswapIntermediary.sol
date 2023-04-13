// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;
// address(this) = 0xf243BEcF7851acA2bE4aFF61ec321c110E4c9205
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

interface IERC20ZooToken {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external;

    function _calculateFee(
        address _from,
        address _to,
        uint256 _value
    )
        external
        returns (
            uint256,
            uint256,
            uint256
        );

    function getFeeCollectors(address user)
        external
        returns (
            address,
            address,
            address
        );

    function approve(address spender, uint256 amount) external returns (bool);
}
interface IERC20Other {
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
    event Approval(address indexed owner, address indexed spender, uint256 value);

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
    function allowance(address owner, address spender) external view returns (uint256);

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}
contract SingleSwap {
    address public  routerAddress   = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address public  Zoo = 0x477c14FfD2dC6b4b706C3fC062fb2045D12Cf35A;
    address public  Other = 0xEE87056d493149d76b9b7BBd117Ea9A088F71249;

    ISwapRouter public immutable swapRouter = ISwapRouter(routerAddress);
    IERC20ZooToken public ZooToken = IERC20ZooToken(Zoo);
    IERC20Other public OtherToken = IERC20Other(Other);
    
    // For this example, we will set the pool fee to 0.3%.
    uint24 public constant poolFee = 3000;

    event _SellingZooToken(uint256 amountOut);
    event _SellingOtherToken(uint256 amountOut);
    event _ByingZoo(bool);
    event _setZooToken(address Zoo);
    event _setOtherToken(address Other);
    event _setRouterAddress(address routerAddress);
    event _setOwner(address owner);

    address public owner;
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    constructor( address _owner) {
        owner = _owner;
    }

    //for selling token
    function swapExactInputSingle(uint256 amountIn,address tokenToGive,address TokenToTake)
        internal
        returns (uint256 amountOut)
    {
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: tokenToGive,
                tokenOut: TokenToTake,
                fee: poolFee,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        amountOut = swapRouter.exactInputSingle(params);
    }

    function SellingOtherToken(uint256 amountIn)public returns (uint256){
        
        OtherToken.transferFrom(msg.sender, address(this), amountIn);
        
        TransferHelper.safeApprove(Other, address(swapRouter), amountIn);

        uint256 amountOut = swapExactInputSingle(amountIn,Other,Zoo);
        
        emit _SellingOtherToken(amountOut);

        return amountOut;

    }

    function SellingZooToken(uint256 amountIn)public returns (bool){
        
        ZooToken.transferFrom(msg.sender, address(this), amountIn);
            
        TransferHelper.safeApprove(Zoo, address(swapRouter), amountIn);

        uint256 amountOut = swapExactInputSingle(amountIn,Zoo,Other);

        emit _SellingZooToken(amountOut);

        return true;
    }
    
    function swapExactOutputSingle(uint256 amountOut, uint256 amountInMaximum,address tokenToGive,address TokenToTake)
        internal
        returns (uint256 amountIn)
    {
        

        ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter
            .ExactOutputSingleParams({
                tokenIn: tokenToGive,
                tokenOut: TokenToTake,
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountOut: amountOut,
                amountInMaximum: amountInMaximum,
                sqrtPriceLimitX96: 0
            });

        amountIn = swapRouter.exactOutputSingle(params);

    }

    function ByingZoo(uint256 amountOut,uint256 amountInMaximum)public returns (bool){
        
        OtherToken.transferFrom(msg.sender, address(this), amountInMaximum);

        TransferHelper.safeApprove(Other, address(swapRouter), amountInMaximum);

        uint256 spendAmount = swapExactOutputSingle(amountOut,amountInMaximum,Other,Zoo);

        if (spendAmount < amountInMaximum) {
            OtherToken.approve(address(swapRouter), 0);
            OtherToken.transfer(msg.sender, amountInMaximum - spendAmount);
        }

        emit _ByingZoo(true);
        return true;
    }

    function setRouterAddress(address _routerAddress) public onlyOwner{
            routerAddress = _routerAddress;
            emit _setRouterAddress(routerAddress);
    }
    function setZooToken(address _Zoo) public onlyOwner{
            Zoo = _Zoo;
            emit _setZooToken(Zoo);
    }
    function setOtherToken(address _Other) public onlyOwner{
            Other = _Other;
            emit _setOtherToken(Other);
    }
    function setOwner(address _owner) public onlyOwner {
        owner =_owner;
        emit _setOwner(owner);
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