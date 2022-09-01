var bridge = artifacts.require("Bridge");

module.exports = async function(deployer) {
  deployer.deploy(bridge)
    .then(() => bridge.deployed())
    .then(async instance => {
      console.log("Bridge Contract Address: ", instance.address);
      
      await instance.createGateKeeper(
        "0x6D8F4B0792c2351DCa54EAB85E453E47C6026b1a",
        "gk1",
        "",
        "",
        10,
        10
      );

      console.log("createGateKeeper done");

      await instance.createReport(
        "0x17eba4846d5af4011fd08286ed994a6656b24c637de7da026d6d27d03e1f1896",
        "0x6D8F4B0792c2351DCa54EAB85E453E47C6026b1a",
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