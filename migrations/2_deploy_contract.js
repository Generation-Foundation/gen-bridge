var bridge = artifacts.require("Bridge");
var bridgeDeposit = artifacts.require("BridgeDeposit");
const coffeeToken = artifacts.require('CoffeeToken');

module.exports = async function(deployer) {
  await deployer.deploy(bridge)
    .then(() => bridge.deployed())
    .then(async instance => {
      console.log("Bridge Contract Address: ", instance.address);

      // mint and send to msg.sender 1M
      let coffeeTokenContract;
      await deployer.deploy(coffeeToken, 'Coffee Token', 'COFFEE', '1000000000000000000000000')
        .then(() => coffeeToken.deployed())
        .then(async instance => {
          console.log("coffeeToken Contract Address: ", instance.address);
          coffeeTokenContract = instance.address;
        });

      let bridgeDepositContractAddress;
      await deployer.deploy(bridgeDeposit)
        .then(() => bridgeDeposit.deployed())
        .then(async instance => {
          console.log("bridgeDeposit Contract Address: ", instance.address);
          bridgeDepositContractAddress = instance.address;
        });  

      // TODO: COFFEE transfer to bridgeDepositContractAddress
      
      await instance.createGateKeeper(
        "0x6d8f4b0792c2351dca54eab85e453e47c6026b1a",
        "Gate Keeper 1",
        "",
        "",
        10,
        10
      );

      console.log("createGateKeeper done");
        
      await instance.createReport(
        "0x17eba4846d5af4011fd08286ed994a6656b24c637de7da026d6d27d03e1f1896",
        "0x6d8f4b0792c2351dca54eab85e453e47c6026b1a",
        "123000000000000000000",
        "ethereum",
        "0x95ad61b0a150d79219dcf64e1e6cc01f0b64c4ce",
        "generation",
        "0x95ad61b0a150d79219dcf64e1e6cc01f0b64c4ce"
      );

      console.log("createReport done");

      // After transfer
      await instance.setCompletedReport("0x17eba4846d5af4011fd08286ed994a6656b24c637de7da026d6d27d03e1f1896");

      console.log("setCompletedReport done");
      
      let resultForGetCompletedReport = await instance.getCompletedReport("0x17eba4846d5af4011fd08286ed994a6656b24c637de7da026d6d27d03e1f1896");
      console.log("getCompletedReport: ", resultForGetCompletedReport);

    });

  

  
};