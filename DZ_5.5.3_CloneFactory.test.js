const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("CloneFactory", function () {
  it("Should deploy a clone and predict its address correctly", async function () {
    const [deployer, otherAccount] = await ethers.getSigners();

    const CloneFactory = await ethers.getContractFactory("CloneFactory");
    const cloneFactory = await CloneFactory.deploy();
    await cloneFactory.deployed();

    const initialValue = 123;
    const salt = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("mySalt")); 

    const bytecode = await cloneFactory.getBytecode(initialValue, otherAccount.address);
    const bytecodeHash = await cloneFactory.getBytecodeHash(initialValue, otherAccount.address);

    const predictedAddress = await cloneFactory.predictAddress(salt, bytecodeHash);

    const tx = await cloneFactory.deployClone(bytecode, salt);
    const receipt = await tx.wait();

    const cloneCreatedEvent = receipt.events.find(event => event.event === 'CloneCreated');
    expect(cloneCreatedEvent.args.cloneAddress).to.equal(predictedAddress);

    const Clonable = await ethers.getContractFactory("Clonable");
    const clone = Clonable.attach(predictedAddress); 

    expect(await clone.value()).to.equal(initialValue);
    expect(await clone.creator()).to.equal(otherAccount.address);

    // проверяем независимость клона
    await clone.setValue(456);
    expect(await clone.value()).to.equal(456);
  });
});
