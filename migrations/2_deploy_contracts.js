const AnimalFactory = artifacts.require('./AnimalFactory.sol');

module.exports = (deployer) => {
    //http://www.onlineconversion.com/unix_time.htm
    var owner = "0xF4B99E8d0841DF74A694F591293331C32E530D9B";

    deployer.deploy(AnimalFactory, owner);

};
