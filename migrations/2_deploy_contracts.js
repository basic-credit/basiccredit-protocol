
const TDai = artifacts.require("TDai");
const BasicCredit = artifacts.require("BasicCredit");


module.exports = function (deployer) {
  deployer.deploy(greeting);
};



module.exports = async function(deployer, network, accounts) {


  //Deploy test Dai Token

  await deployer.deploy(TDai)
  const tdai = await TDai.deployed()


  //Deploy Token Farm
  
  await deployer.deploy(BasicCredit, tdai.address)
  const basicCredit = await BasicCredit.deployed()

  
  // Transfer 1000 test Dai to Investor (i.e to 2nd account in Ganache)

  await tdai.MintToken(accounts[1], '1000000000000000000000') 


};