# @version 0.2.12


interface IUniSwapV2Pair:
	def getReserves() -> (uint256, uint256, uint256): view


# returns sorted token addresses, used to handle return values from pairs sorted in this order
@view
@internal
def sortTokens(tokenA: address, tokenB: address) -> (address, address):
	assert tokenA != tokenB, "UniSwapV2Library: IDENTICAL_ADDRESSES"
	uintA: uint256 = convert(tokenA,uint256)
	uintB: uint256 = convert(tokenB,uint256)
	if uintA < uintB:
		assert tokenA != ZERO_ADDRESS, "UniSwapV2Library: ZERO_ADDRESS"
		return tokenA, tokenB
	else:
		assert tokenB != ZERO_ADDRESS, "UniSwapV2Library: ZERO_ADDRESS"
		return tokenB, tokenA


# calculates the CREATE2 address for a pair without making any external calls
@view
@internal
def pairFor(factory: address, tokenA: address, tokenB: address) -> (address):
	ff: Bytes[1] = 0xff
	_factory: Bytes[20] = slice(convert(factory, bytes32),12,20)
	token0: address = empty(address)
	token1: address = empty(address)
	(token0, token1) = self.sortTokens(tokenA, tokenB)
	_token0: Bytes[20] = slice(convert(token0, bytes32),12,20)
	_token1: Bytes[20] = slice(convert(token1, bytes32),12,20)
	initcode: bytes32 = 0x96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f
	hash: bytes32 =keccak256(concat(
		ff,
		_factory,
		keccak256(concat(_token0,_token1)),
		initcode
	))
	pair: address = convert((convert(hash,uint256) % (256**20)), address)
	return pair
	

# fetches and sorts the reserves for a pair
@view
@internal
def getReserves(factory: address, tokenA: address,tokenB: address) -> (uint256,uint256):
	token0: address = empty(address)
	junk: address = empty(address) # vyper can't declare unfinished tuples
	(token0,junk) = self.sortTokens(tokenA,tokenB)
	
	reserve0: uint256 = empty(uint256)
	reserve1: uint256 = empty(uint256)
	junk2: uint256 = empty(uint256) # more junk to fill tuple
	pair: address = self.pairFor(factory, tokenA, tokenB) # for some reason this needs to be declared before not inline
	(reserve0,reserve1,junk2) = IUniSwapV2Pair(pair).getReserves()

	if tokenA == token0:
		return (reserve0,reserve1)
	else:
		return (reserve1,reserve0)


#  given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
@pure
@external
def quote(amountA: uint256, reserveA: uint256, reserveB: uint256) -> (uint256):
	assert(amountA > 0), 'UniswapV2Library: INSUFFICIENT_AMOUNT'
	assert(reserveA > 0 and reserveB > 0), 'UniswapV2Library: INSUFFICIENT_LIQUIDITY'
	amountB: uint256 = amountA * reserveB / reserveA
	return amountB


#  given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
@pure
@internal
def getAmountOut(amountIn: uint256, reserveIn: uint256, reserveOut: uint256) -> (uint256):
	assert(amountIn > 0), 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT'
	assert(reserveIn > 0 and reserveOut > 0), 'UniswapV2Library: INSUFFICIENT_LIQUIDITY'
	amountInWithFee: uint256 = amountIn *997
	numerator: uint256 = amountInWithFee * reserveOut
	denominator: uint256  = (reserveIn * 1000) +amountInWithFee
	amountOut: uint256 = numerator / denominator
	return amountOut


# given an output amount of an asset and pair reserves, returns a required input amount of the other asset
@pure
@internal
def getAmountIn(amountOut: uint256, reserveIn: uint256, reserveOut: uint256) -> (uint256):
	assert(amountOut > 0), 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT'
	assert(reserveIn > 0 and reserveOut > 0), 'UniswapV2Library: INSUFFICIENT_LIQUIDITY'    
	numerator: uint256 = reserveIn * amountOut * 1000
	denominator: uint256 = (reserveOut -amountOut) * 997
	amountIn: uint256 = (numerator / denominator) +1
	return amountIn



# performs chained getAmountOut calculations on AT MOST SOME NUMBER pairs (if u need more just edit the code) vyper has no dynamic arrays
@view
@external
def getAmountsOut(factory: address, amountIn: uint256, path: address[3]) -> (uint256[3]):
	"""
	@dev instead of passing a small fixed sized address array(path: address[3]), you could pass in a larger one 
		with the unused indices being set to the zero address. uncomment the two lines in the 2 next functions
		change the output and input array size to something large like Bytes[20]
		and then you could slice the array down to proper size whereever you need it
	"""  
	amounts: uint256[3] = empty(uint256[3])
	amounts[0] = amountIn
	reserveIn: uint256 = empty(uint256)
	reserveOut: uint256 = empty(uint256)
	for i in range(0,2): # range from 0 index to last index of array
		#if path[i] == ZERO_ADDRESS: 
		#	break						 
		(reserveIn,reserveOut) = self.getReserves(factory,path[i],path[i+1])
		amounts[i+1] = self.getAmountOut(amounts[i],reserveIn,reserveOut)
	return amounts


# performs chained getAmountIn calculations on AT MOST SOME NUMBER pairs (if u need more just edit the code) vyper has no dynamic arrays
@view
@external
def getAmountsIn(factory: address, amountOut: uint256, path: address[3]) -> (uint256[3]):
	amounts: uint256[3] = empty(uint256[3])
	amounts[2] = amountOut # length of array -1
	reserveIn: uint256 = empty(uint256)
	reserveOut: uint256 = empty(uint256)
	for i in range(0,2): # range from 0 index to last index of array
		#if path[2-i] == ZERO_ADDRESS: # same thing as above 
		#	break
		(reserveIn,reserveOut) = self.getReserves(factory,path[1-i],path[2-i]) # path[max size-1 minus i], path[max size minus i]
		amounts[1-i] = self.getAmountIn(amounts[2-i],reserveIn,reserveOut) # path[max size minus i], path[max size-1 minus i]
	return amounts