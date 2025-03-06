describe("AITreasuryAdjuster", function () {
    let treasuryAdjuster, owner;

    beforeEach(async function () {
        [owner] = await ethers.getSigners();
        const TreasuryAdjuster = await ethers.getContractFactory("AITreasuryAdjuster");
        treasuryAdjuster = await TreasuryAdjuster.deploy();
    });

    it("Should adjust treasury contribution rate", async function () {
        await expect(treasuryAdjuster.adjustTreasuryContribution(6))
            .to.emit(treasuryAdjuster, "ContributionRateUpdated")
            .withArgs(6);
    });

    it("Should get the treasury contribution rate", async function () {
        expect(await treasuryAdjuster.getTreasuryContribution()).to.equal(5);
    });
});
