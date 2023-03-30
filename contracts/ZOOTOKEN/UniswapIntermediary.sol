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
    ) external returns (bool);

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
    function approve(address spender, uint256 amount) external returns (bool);
}

contract SingleSwap {
    address public constant routerAddress =
        0xE592427A0AEce92De3Edee1F18E0157C05861564;
    ISwapRouter public immutable swapRouter = ISwapRouter(routerAddress);

    address public constant Zoo = 0x6e813403bD2DFA6c7f095fBF6C1CF7E23d998498;
    address public constant Matic = 0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889;

    IERC20ZooToken public ZooToken = IERC20ZooToken(Zoo);
    IERC20Matic public MaticToken = IERC20Matic(Zoo);
    // For this example, we will set the pool fee to 0.3%.
    uint24 public constant poolFee = 3000;

    constructor() {}

    //for selling token
    function swapExactInputSingle(uint256 amountIn,address tokenToGive,address TokenToTake)
        internal
        returns (uint256 amountOut)
    {
        ZooToken.approve(address(swapRouter), amountIn);

        ZooToken.transferFrom(msg.sender, address(this), amountIn);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: tokenToGive,
                tokenOut: TokenToTake,
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        amountOut = swapRouter.exactInputSingle(params);

        // //calculate fees
        // (
        //     uint256 fee,
        //     uint256 feeMarketing,
        //     uint256 feeNftStaking
        // ) = ZooToken._calculateFee(msg.sender,address(this), amountOut);
        // //get address
        // (address StakingAddress,address MarketWalletAddress,address referralAddress) = ZooToken.getFeeCollectors(msg.sender);
        //distribute fees
        address StakingAddress = 0x41720b3277f5eE1Af42FB56fb0C3a0d6F8046365;
        payable(StakingAddress).transfer(amountOut);
        // payable(MarketWalletAddress).transfer(feeNftStaking);
    }

    function SellingMatic(uint256 amountIn)public returns (uint256 amountOut){
        amountOut = swapExactInputSingle(amountIn,Matic,Zoo);
    }
    function SellingZooToken(uint256 amountIn)public returns (uint256 amountOut){
        amountOut = swapExactInputSingle(amountIn,Zoo,Matic);
    }



    //for buying token
    function swapExactOutputSingle(uint256 amountOut, uint256 amountInMaximum,address tokenToGive,address TokenToTake)
        internal
        returns (uint256 amountIn)
    {
        
        TransferHelper.safeTransferFrom(MATIC, msg.sender, address(this), amountInMaximum);
        // Approve the router to spend the specifed `amountInMaximum` of DAI.
        TransferHelper.safeApprove(MATIC, address(swapRouter), amountInMaximum);

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

        if (amountIn < amountInMaximum) {
            ZooToken.approve(address(swapRouter), 0);
            ZooToken.transfer(address(this), amountInMaximum - amountIn);
        }
    }

    function ByingMatic(uint256 amountOut,uint256 amountInMaximum)public returns (uint256 amountIn){
        amountIn = swapExactOutputSingle(amountOut,amountInMaximum,Zoo,Matic);
    }
    function ByingZooToken(uint256 amountOut,uint256 amountInMaximum)public payable returns (uint256 amountIn){
        //calculating the amount with taxes
        require(amountOut > 0,"you forget to set the number of tokens");
        uint256 totalBeforeTax  = getCurrentPrice() * amountOut;
        (uint256 fee,uint256 feeMarketing,uint256 feeNftStaking)  = ZooToken._calculateFee(address(this),msg.sender,totalBeforeTax);
        (address nftStakingContractAddress,address addressmarketingWallet,address referral) = ZooToken.getFeeCollectors(msg.sender);
        uint256 referralFee = 0; 
        if(referral!=address(0)){
            referralFee = fee;
        }
        uint256 AmountWithTax = referralFee + fee + totalBeforeTax;  
        require(msg.value > AmountWithTax,"you don't have sufficient Matics");
        amountIn = swapExactOutputSingle(amountOut,amountInMaximum,Matic,Zoo);
    }
//check msg.value
//referral

    // @notice Returns the current price of Zoo in terms of Matic.
    function getCurrentPrice() public view returns (uint256 price) {
        IUniswapV3Pool pool = IUniswapV3Pool(Zoo);
        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();

        // Convert the square root price to a regular price with 18 decimals.
        uint256 sqrtPrice = uint256(sqrtPriceX96);
        price = sqrtPrice * sqrtPrice / (1 << 192);
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