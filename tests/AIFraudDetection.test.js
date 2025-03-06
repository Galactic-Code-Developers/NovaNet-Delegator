describe("AIFraudDetection", function () {
    let fraudDetection, owner, delegator;

    beforeEach(async function () {
        [owner, delegator] = await ethers.getSigners();
        const FraudDetection = await ethers.getContractFactory("AIFraudDetection");
        fraudDetection = await FraudDetection.deploy();
    });

    it("Should flag a delegator for fraud", async function () {
        await expect(fraudDetection.flagDelegator(delegator.address, "Suspicious Activity"))
            .to.emit(fraudDetection, "DelegatorFlagged")
            .withArgs(delegator.address, "Suspicious Activity");
    });

    it("Should clear a flagged delegator", async function () {
        await fraudDetection.flagDelegator(delegator.address, "Suspicious Activity");
        await expect(fraudDetection.clearDelegator(delegator.address))
            .to.emit(fraudDetection, "DelegatorCleared")
            .withArgs(delegator.address);
    });
});
