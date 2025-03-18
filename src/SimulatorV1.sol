// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;


import "./protocols/uniswap/UniswapV2Library.sol";
import "./protocols/uniswap/IQuoterV2.sol";
import "./protocols/curve/ICurvePool.sol";


contract SimulatorV1 {

    address public UNISWAP_V2_FACTORY = 0xF62c03E08ada871A0bEb309762E260a7a6a880E6;
    address public UNISWAP_V3_QUOTER2 = 0xEd1f6473345F45b75F8179591dd5bA1888cf2FB3;

    struct SwapParams {
        uint8 protocol;
        address pool;
        address tokenIn;
        address tokenOut;
        uint24 fee;
        uint256 amount;
    }

    constructor() {}

    function simulateSwapIn(SwapParams[] memory paramsArray) public returns (uint256) {
        uint256 amountOut = 0;
        uint256 paramsArrayLength = paramsArray.length;

        for (uint256 i = 0; i < paramsArrayLength;) {
            SwapParams memory params = paramsArray[i];

            if (amountOut == 0) {
                amountOut = params.amount;
            } else {
                params.amount = amountOut;
            }


            if (params.protocol == 0) {
                amountOut = simulateUniSwapV2SwapIn(params);
            } else if (params.protocol == 1) {
                amountOut = simulateUniSwapV3SwapIn(params);
            } else if (params.protocol == 2) {
                amountOut = simulateCurveSwapIn(params);
            }

            unchecked {
                i++;
            }
        }
        return amountOut;

    }

    function simulateUniSwapV2SwapIn(SwapParams memory params) public view returns (uint256 amountOut) {
        (uint reserveIn, uint reserveOut) = UniswapV2Library.getReserves(
            UNISWAP_V2_FACTORY,
            params.tokenIn,
            params.tokenOut

        );
        amountOut = UniswapV2Library.getAmountOut(
            params.amount, 
            reserveIn, 
            reserveOut
        );



    }

    function simulateUniSwapV3SwapIn(SwapParams memory params) public returns (uint256 amountOut) {
        IQuoterV2 quoter = IQuoterV2(UNISWAP_V3_QUOTER2);
        IQuoterV2.QuoteExactInputSingleParams memory quoterParams;
        quoterParams.tokenIn = params.tokenIn;
        quoterParams.tokenOut = params.tokenOut;
        quoterParams.amountIn = params.amount;
        quoterParams.fee = params.fee;
        quoterParams.sqrtPriceLimitX96 = 0;
        (amountOut,,,) = quoter.quoteExactInputSingle(quoterParams);
    }



    function simulateCurveSwapIn(SwapParams memory params) public returns (uint256 amountOut) {
        ICurvePool pool = ICurvePool(params.pool);

        int128 i = 0;
        int128 j = 1;

        int128 coinIdx = 0;

        while (i == j) {
            address coin = pool.coins(coinIdx);

            if (coin == params.tokenIn) {
                i = coinIdx;
            } else if (coin == params.tokenOut) {
                j = coinIdx;
            }

            if (i != j) {
                break;
            }

            unchecked {
                coinIdx++;
            }

        }

        amountOut = ICurvePool(params.pool).get_dy(
            i,
            j,
            params.amount       
        );


    }

}
