describe("AIGovernanceFraudDetection", function () {
    let fraudDetection, owner, voter;

    beforeEach(async function () {
        [owner, voter] = await ethers.getSigners();
        const FraudDetection = await ethers.getContractFactory("AIGovernanceFraudDetection");
        fraudDetection = await FraudDetection.deploy();
    });

    it("Should flag a voter for fraud", async function () {
        await expect(fraudDetection.flagVoter(voter.address, "Vote Manipulation"))
            .to.emit(fraudDetection, "VoterFlagged")
            .withArgs(voter.address, "Vote Manipulation");
    });

    it("Should clear a flagged voter", async function () {
        await fraudDetection.flagVoter(voter.address, "Vote Manipulation");
        await expect(fraudDetection.clearVoter(voter.address))
            .to.emit(fraudDetection, "VoterCleared")
            .withArgs(voter.address);
    });
});
