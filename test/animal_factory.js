var AnimalFactory = artifacts.require("./AnimalFactory.sol");

contract('AnimalFactory', (accounts) => {
    var contract;
    var owner = "0xF4B99E8d0841DF74A694F591293331C32E530D9B";

    it('should deployed contract', async ()  => {
        assert.equal(undefined, contract);
        contract = await AnimalFactory.deployed();
        assert.notEqual(undefined, contract);
    });

    it('get address contract', async ()  => {
        assert.notEqual(undefined, contract.address);
    });

    it('verification owner contract', async ()  => {
        var contractOwner = await contract.owner.call();
        //console.log("contractOwner = " + contractOwner);
        assert.equal(owner.toUpperCase(), contractOwner.toUpperCase());
    });


});



