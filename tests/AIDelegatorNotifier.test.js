describe("AIDelegatorNotifier", function () {
    let notifier, owner, delegator;

    beforeEach(async function () {
        [owner, delegator] = await ethers.getSigners();
        const Notifier = await ethers.getContractFactory("AIDelegatorNotifier");
        notifier = await Notifier.deploy();
    });

    it("Should send notification to a delegator", async function () {
        await expect(notifier.sendNotification(delegator.address, "Validator Underperforming"))
            .to.emit(notifier, "NotificationSent")
            .withArgs(delegator.address, "Validator Underperforming");
    });
});
