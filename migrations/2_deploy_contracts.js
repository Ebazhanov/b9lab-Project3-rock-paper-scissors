var RockPaperScissors = artifacts.require("./RockPaperScissors.sol");

module.exports = function(deployer) {
  deployer.deploy(RockPaperScissors,'0x51f3a99e7cee69cb037a0bb02b7cfad1753a01c4','0xdf67bf75053459740bfecd5deb5fac760c8a7bca');
};
