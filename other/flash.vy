# @version 0.2.12

from vyper.interfaces import ERC20


interface ILoanWrapper:
	def borrow(pair_token: address, amount_out: uint256, to: address,	wethloan: bool ) -> bool: nonpayable
	def repay(amount: uint256, token: address) -> bool: nonpayable

interface UniswapCallee:
	def uniswapV2Call(sender: address, amount0: address, amount1: address, data: bytes32): nonpayable


implements UniswapCallee

janitor = public(address)
weth = public(address)
uniswap = public(address)
wrapper = public(address)

def __init__(_wrapper: address):
	self.janitor = msg.sender
	self.weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
	self.uniswap = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f
	self.wrapper = _wrapper

@external
def flashLoan(pair_token: address, amount_out: uint256, to: address, wethloan: bool) -> bool:
	ILoanWrapper(wrapper).borrow(pair_token,amount_out,to,wethloan)
	

@external
def uniswapV2Call(sender: address, amount0: uint256, amount1: uint256, data: bytes32):
	assert(data==1 or data==2) # dev: some wrong data
	if data == 1:
		ILoanWrapper(wrapper).repay(amount0,weth)
	else:
		ILoanWrapper(wrapper).repay(amount1,)
		

@external
def dust(_token: address) -> bool:
	return ERC20(_token).transfer(self.janitor, ERC20(_token).balanceOf(self))