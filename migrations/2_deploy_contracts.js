
const tDai = artifacts.require("tDai");
const BasicCredit = artifacts.require("BasicCredit");



module.exports = async function(deployer, network, accounts) {


  //Deploy test Dai Token

  await deployer.deploy(tDai)
  const tdai = await TDai.deployed()


  //Deploy Token Farm
  
  await deployer.deploy(BasicCredit)
  const basicCredit = await BasicCredit.deployed()

  

};