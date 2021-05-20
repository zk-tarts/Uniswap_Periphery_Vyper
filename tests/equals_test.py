import brownie
import pytest




@pytest.fixture(scope="session")
def contract0 (accounts, UniswapV2LibraryContract):
	yield UniswapV2LibraryContract.deploy({'from': accounts[0]})


@pytest.fixture(scope="session")
def contract1 (accounts, UniswapV2LibraryVyper):
	yield UniswapV2LibraryVyper.deploy({'from': accounts[0]})



#def test_quote(contract0, contract1, accounts):
#	x= contract0.quote(522,9849841,489498151561,{"from": accounts[0]})
#	y= contract1.quote(522,9849841,489498151561,{"from": accounts[0]})
#	assert x==y


def test_getamountsout(contract0, contract1, accounts):
	x= contract0.amountsout("0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f",100000000,["0x6B175474E89094C44Da98b954EedeAC495271d0F","0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2","0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"],{"from": accounts[0]})
	y= contract1.getAmountsOut("0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f",100000000,["0x6B175474E89094C44Da98b954EedeAC495271d0F","0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2","0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"],{"from": accounts[0]})
	assert x==y
	

def test_getamountsin(contract0, contract1, accounts):
	x= contract0.amountsin("0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f",100000000,["0x6B175474E89094C44Da98b954EedeAC495271d0F","0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2","0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"],{"from": accounts[0]})
	y= contract1.getAmountsIn("0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f",100000000,["0x6B175474E89094C44Da98b954EedeAC495271d0F","0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2","0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"],{"from": accounts[0]})
	assert x==y
