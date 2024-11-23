// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title SimpleDEX
 * @dev A simple decentralized exchange (DEX) for swapping two ERC20 tokens.
 */
contract SimpleDEX {
    /// @notice The first token supported by SimpleDEX.
    IERC20 public tokenA;
    /// @notice The second token supported by SimpleDEX.
    IERC20 public tokenB;
    /// @notice The reserve of TokenA in the DEX.
    uint256 public reserveA;
    /// @notice The reserve of TokenB in the DEX.
    uint256 public reserveB;
    /// @notice The address of the DEX owner.
    address public owner;

    /**
     * @dev Emitted when liquidity is added to the DEX.
     * @param provider The address adding liquidity.
     * @param amountA The amount of TokenA added.
     * @param amountB The amount of TokenB added.
     */
    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB);

    /**
     * @dev Emitted when liquidity is removed from SimpleDEX.
     * @param provider The address removing liquidity.
     * @param amountA The amount of TokenA removed.
     * @param amountB The amount of TokenB removed.
     */
    event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB);

    /**
     * @dev Emitted when tokens are swapped.
     * @param user The address executing the swap.
     * @param tokenIn The token being swapped in.
     * @param tokenOut The token being swapped out.
     * @param amountIn The amount of tokens inputted.
     * @param amountOut The amount of tokens outputted.
     */
    event TokensSwapped(address indexed user, address indexed tokenIn, address indexed tokenOut, uint256 amountIn, uint256 amountOut);

    /**
     * @notice Initializes the SimpleDEX with two tokens.
     * @param _tokenA The address of TokenA.
     * @param _tokenB The address of TokenB.
     */
    constructor(address _tokenA, address _tokenB) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
        owner = msg.sender;
    }

    /**
     * @notice Modifier to restrict functions to only the owner of SimpleDEX.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can use this function");
        _;
    }

    /**
     * @notice Adds liquidity to SimpleDEX.
     * @dev Can only be called by the owner.
     * @param amountA The amount of TokenA to add.
     * @param amountB The amount of TokenB to add.
     */
    function addLiquidity(uint256 amountA, uint256 amountB) external onlyOwner {
        require(amountA > 0 && amountB > 0, "Amounts must be greater than 0");

        reserveA += amountA;
        reserveB += amountB;

        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);

        emit LiquidityAdded(msg.sender, amountA, amountB);
    }

    /**
     * @notice Swaps TokenA for TokenB.
     * @param amountAIn The amount of TokenA to swap.
     */
    function swapAforB(uint256 amountAIn) external {
        require(amountAIn > 0, "Amount must be greater than 0");

        uint256 amountBOut = calculateSwap(amountAIn, reserveA, reserveB);
        require(amountBOut > 0, "Insufficient output amount");

        uint256 allowance = tokenA.allowance(msg.sender, address(this));
        require(allowance >= amountAIn, "Insufficient allowance");

        tokenA.transferFrom(msg.sender, address(this), amountAIn);
        tokenB.transfer(msg.sender, amountBOut);

        reserveA += amountAIn;
        reserveB -= amountBOut;

        emit TokensSwapped(msg.sender, address(tokenA), address(tokenB), amountAIn, amountBOut);
    }

    /**
     * @notice Swaps TokenB for TokenA.
     * @param amountBIn The amount of TokenB to swap.
     */
    function swapBforA(uint256 amountBIn) external {
        require(amountBIn > 0, "Amount must be greater than 0");

        uint256 amountAOut = calculateSwap(amountBIn, reserveB, reserveA);
        require(amountAOut > 0, "Insufficient output amount");

        uint256 allowance = tokenB.allowance(msg.sender, address(this));
        require(allowance >= amountBIn, "Insufficient allowance");

        tokenB.transferFrom(msg.sender, address(this), amountBIn);
        tokenA.transfer(msg.sender, amountAOut);

        reserveB += amountBIn;
        reserveA -= amountAOut;

        emit TokensSwapped(msg.sender, address(tokenB), address(tokenA), amountBIn, amountAOut);
    }

    /**
     * @notice Removes liquidity from SimpleDEX.
     * @dev Can only be called by the owner.
     * @param amountA The amount of TokenA to remove.
     * @param amountB The amount of TokenB to remove.
     */
    function removeLiquidity(uint256 amountA, uint256 amountB) external onlyOwner {
        require(amountA > 0 && amountB > 0, "Amounts must be greater than 0");
        require(amountA <= reserveA && amountB <= reserveB, "Insufficient liquidity");

        reserveA -= amountA;
        reserveB -= amountB;

        tokenA.transfer(msg.sender, amountA);
        tokenB.transfer(msg.sender, amountB);

        emit LiquidityRemoved(msg.sender, amountA, amountB);
    }

    /**
     * @notice Retrieves the price of a given token.
     * @param _token The address of the token.
     * @return The price of the token in terms of the other token.
     */
    function getPrice(address _token) external view returns (uint256) {
        require(_token == address(tokenA) || _token == address(tokenB), "Invalid token");

        if (_token == address(tokenA)) {
            return (reserveB * 1e18) / reserveA; // Price of TokenA in terms of TokenB
        } else {
            return (reserveA * 1e18) / reserveB; // Price of TokenB in terms of TokenA
        }
    }

    /**
     * @notice Calculates the output amount for a swap.
     * @dev This function implements a constant product formula.
     * @param inputAmount The input token amount.
     * @param inputReserve The reserve of the input token.
     * @param outputReserve The reserve of the output token.
     * @return The output token amount.
     */
    function calculateSwap(uint256 inputAmount, uint256 inputReserve, uint256 outputReserve) internal pure returns (uint256) {
        uint256 numerator = inputAmount * outputReserve;
        uint256 denominator = inputReserve + inputAmount;
        return numerator / denominator;
    }
}
