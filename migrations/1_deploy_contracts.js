const DVotev2 = artifacts.require("./contracts/DVotev1.sol");

module.exports = function (deployer) {

  const initialElectionAdmin = "0xc484F151a6569698D2DF28d12E9ee7DD83429540";

  deployer.deploy(DVotev2, initialElectionAdmin);
};
