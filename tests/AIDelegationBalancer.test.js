const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("AIDelegationBalancer", function () {
    let balancer, validatorSelection, validatorContract, owner, delegator;

    beforeEach(async function () {
        [owner, delegator] = await ethers.getSigners();
        const ValidatorSelection = await ethers.getContractFactory("AIValidatorSelection");
        validatorSelection = await ValidatorSelection.deploy();

        const ValidatorContract = await ethers.getContractFactory("NovaNetValidator");
        validatorContract = await ValidatorContract.deploy();

        const Balancer = await ethers.getContractFactory("AIDelegationBalancer");
        balancer = await Balancer.deploy(validatorSelection.address, validatorContract.address);
    });

    it("Should reassign delegator to best validator", async function () {
        await expect(balancer.autoReassignDelegation(delegator.address, 1000))
            .to.emit(balancer, "DelegationReassigned");
    });
});
