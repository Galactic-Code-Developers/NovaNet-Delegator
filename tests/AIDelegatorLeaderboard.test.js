describe("AIDelegatorLeaderboard", function () {
    let leaderboard, owner, delegator1, delegator2;

    beforeEach(async function () {
        [owner, delegator1, delegator2] = await ethers.getSigners();
        const Leaderboard = await ethers.getContractFactory("AIDelegatorLeaderboard");
        leaderboard = await Leaderboard.deploy();
    });

    it("Should update leaderboard with delegator scores", async function () {
        await expect(leaderboard.updateLeaderboard(delegator1.address, 1000, 5))
            .to.emit(leaderboard, "LeaderboardUpdated")
            .withArgs(delegator1.address, 1000);
    });

    it("Should retrieve leaderboard data", async function () {
        await leaderboard.updateLeaderboard(delegator1.address, 1000, 5);
        const data = await leaderboard.getLeaderboard();
        expect(data.length).to.equal(1);
    });
});
