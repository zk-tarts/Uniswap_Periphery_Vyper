// SPDX-License-Identifier: MIT;
pragma solidity =0.7.0;

import '../libraries/UniswapV2Library.sol';

interface IUniswapV2Factory{
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface UniswapPair {
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;
}

interface IERC20 {
    function balanceOf(address guy) external view returns (uint256);
    function transfer(address dst, uint256 wad) external returns (bool);
    function transferFrom(address src, address dst, uint256 wad) external returns (bool);
    function approve(address guy, uint256 wad) external returns (bool);
    function allowance(address src, address dst) external view returns (uint256);
}

// takes a flash loan ONLY WORKS ON WETH PAIRS
contract LoanWrapper {
    address private janitor;
    address public weth;
    address public uniswap;

    constructor(address _weth, address _uniswap) {
        janitor = msg.sender;
		weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
		uniswap = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    }
    
	function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }	

    function borrow(
        address pair_token,
        uint256 amount_out,
        address to,
		bool wethloan
    ) external returns (bool) {
		require(isContract(msg.sender), "LoanWrapper: Only call this contract from another contract");
        IERC20 token = IERC20(pair_token);
		address memory pair = IUniswapV2Factory(uniswap).getPair(weth,token);
		if (wethloan) {
			UniswapPair(pair).swap(amount_out,0,msg.sender,1); // taking out the weth passed in as 1
		}
		else {
			UniswapPair(pair).swap(0,amount_out,msg.sender,2); // taking out the other token passed in as 2
		}
        return true;
    }
	function repay(uint256 _amount, address token) external returns (bool) {
		uint256 amountRequired  = UniswapV2Library.getAmountsIn(factory, amountETH, path)[0];
		assert(_amount > amountRequired);
		assert(token.transfer(msg.sender,amountRequired));
		return true;
	}


    function dust(address _token) external returns (bool) {
        IERC20 token = IERC20(_token);
        return token.transfer(janitor, token.balanceOf(address(this)));
    }
}
