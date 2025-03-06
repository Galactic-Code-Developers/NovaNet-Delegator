describe("AISlashingAdjuster", function () {
    let slashingAdjuster, slashingMonitor, owner, delegator;

    beforeEach(async function () {
        [owner, delegator] = await ethers.getSigners();
        const SlashingMonitor = await ethers.getContractFactory("AISlashingMonitor");
        slashingMonitor = await SlashingMonitor.deploy();

        const SlashingAdjuster = await ethers.getContractFactory("AISlashingAdjuster");
        slashingAdjuster = await SlashingAdjuster.deploy(slashingMonitor.address);
    });

    it("Should adjust slashing penalties based on history", async function () {
        expect(await slashingAdjuster.getAdjustedSlashingPenalty(delegator.address, 5))
            .to.equal(5);
    });
});
