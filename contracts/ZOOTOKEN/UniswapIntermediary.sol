// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

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
interface IERC20Matic {
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
    address public constant routerAddress   = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    ISwapRouter public immutable swapRouter = ISwapRouter(routerAddress);

    address public constant Zoo = 0x477c14FfD2dC6b4b706C3fC062fb2045D12Cf35A;
    address public constant Matic = 0x61601A166b86365c0d03a2555a1b3E41b9455cb7;
    IERC20ZooToken public ZooToken = IERC20ZooToken(Zoo);
    IERC20Matic public MaticToken = IERC20Matic(Matic);
    
    // For this example, we will set the pool fee to 0.3%.
    uint24 public constant poolFee = 3000;

    constructor() {}

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

    function SellingZooToken(uint256 amountIn)public returns (bool){
        
        ZooToken.transferFrom(msg.sender, address(this), amountIn);
        
        TransferHelper.safeApprove(Zoo, address(swapRouter), amountIn);

        swapExactInputSingle(amountIn,Zoo,Matic);

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
                recipient: msg.sender,
                deadline: block.timestamp,
                amountOut: amountOut,
                amountInMaximum: amountInMaximum,
                sqrtPriceLimitX96: 0
            });

        amountIn = swapRouter.exactOutputSingle(params);

    }

    function ByingZoo(uint256 amountOut,uint256 amountInMaximum)public returns (bool){
        
        MaticToken.transferFrom(msg.sender, address(this), amountInMaximum);

        TransferHelper.safeApprove(Matic, address(swapRouter), amountInMaximum);

        uint256 spendAmount = swapExactOutputSingle(amountOut,amountInMaximum,Matic,Zoo);

        if (spendAmount < amountInMaximum) {
            MaticToken.approve(address(swapRouter), 0);
            MaticToken.transfer(msg.sender, amountInMaximum - spendAmount);
        }

        return true;
    }

}
