const DexfToken = artifacts.require('DEXF');
const dexfTokenABI = require('./abis/DEXF.json');
const truffleAssert = require('truffle-assertions');
const BigNumber = require('bignumber.js');

const {
  callMethod,
  moveAtEpoch
}  =  require('./utils');

const FIRST_DAY_REWARD = 34000;
const SECOND_DAY_REWARD = 33983;
const THIRD_DAY_REWARD = 33966.0085;

contract("DEXF", async (accounts) => {
  const deployer = accounts[0];
  const Alice = accounts[1];
  const Bob = accounts[2];
  const Christian = accounts[3];

  let dexfTokenInstance;
  let dexfToken;

  let _treasury;
  let _team;
  let _stakingPool;

  before(async () => {
    dexfTokenInstance = await DexfToken.at(dexfTokenABI.address);
    dexfToken = await new web3.eth.Contract(dexfTokenABI.abi, dexfTokenInstance.address);

    _treasury = await callMethod(
      dexfToken.methods._treasury,
      []
    );
    _team = await callMethod(
      dexfToken.methods._team,
      []
    );
    _stakingPool = await callMethod(
      dexfToken.methods._stakingPool,
      []
    );
  });

  describe("Owner setting", async function () {
    it('Change allocation is accessible only by owner', async() => {
      await truffleAssert.reverts(
        dexfTokenInstance.changeAllocation(
          new BigNumber(10000000E18).toString(10),
          0,
          1,
          { from: Alice }
        ),
        "Ownable: caller is not the owner"
      );
    });

    it('Change allocation from treasury to team', async() => {
      let balanceOfTreasury = await callMethod(
        dexfToken.methods.balanceOf,
        [_treasury]
      );
      let balanceOfTeam = await callMethod(
        dexfToken.methods.balanceOf,
        [_team]
      );

      expect(new BigNumber(balanceOfTreasury).eq(new BigNumber(72000000E18))).to.be.equal(true);
      expect(new BigNumber(balanceOfTeam).eq(new BigNumber(20000000E18))).to.be.equal(true);

      await dexfTokenInstance.changeAllocation(
        new BigNumber(10000000E18).toString(10),
        0,
        1,
        { from: deployer }
      );

      balanceOfTreasury = await callMethod(
        dexfToken.methods.balanceOf,
        [_treasury]
      );
      balanceOfTeam = await callMethod(
        dexfToken.methods.balanceOf,
        [_team]
      );

      expect(new BigNumber(balanceOfTreasury).eq(new BigNumber(62000000E18))).to.be.equal(true);
      expect(new BigNumber(balanceOfTeam).eq(new BigNumber(30000000E18))).to.be.equal(true); 
    });

    it('Change allocation from treasury to staking pool', async() => {
      await dexfTokenInstance.changeAllocation(
          new BigNumber(10000000E18).toString(10),
          0,
          2,
          { from: deployer }
      );

      let balanceOfTreasury = await callMethod(
        dexfToken.methods.balanceOf,
        [_treasury]
      );
      let balanceOfStakingPool = await callMethod(
        dexfToken.methods.balanceOf,
        [_stakingPool]
      );

      expect(new BigNumber(balanceOfTreasury).eq(new BigNumber(52000000E18))).to.be.equal(true);
      expect(new BigNumber(balanceOfStakingPool).eq(new BigNumber(78000000E18))).to.be.equal(true);

      const stakingRewardRemaining = await callMethod(
        dexfToken.methods._stakingRewardRemaining,
        []
      );
      expect(new BigNumber(stakingRewardRemaining).eq(new BigNumber(78000000E18))).to.be.equal(true);
    });

    it('Change allocation from staking pool to team', async() => {
      await dexfTokenInstance.changeAllocation(
          new BigNumber(30000000E18).toString(10),
          2,
          1,
          { from: deployer }
      );

      balanceOfTeam = await callMethod(
        dexfToken.methods.balanceOf,
        [_team]
      );
      balanceOfStakingPool = await callMethod(
        dexfToken.methods.balanceOf,
        [_stakingPool]
      );

      expect(new BigNumber(balanceOfTeam).eq(new BigNumber(60000000E18))).to.be.equal(true);
      expect(new BigNumber(balanceOfStakingPool).eq(new BigNumber(48000000E18))).to.be.equal(true);

      const stakingRewardRemaining = await callMethod(
        dexfToken.methods._stakingRewardRemaining,
        []
      );
      expect(new BigNumber(stakingRewardRemaining).eq(new BigNumber(48000000E18))).to.be.equal(true);
    });

    it('Revert Set treasury1 from Alice', async function () {
      await truffleAssert.reverts(
        dexfTokenInstance.setTreasury1(
          "0xA629E14908F5cE17F3AFA3BAF5F7318d06091362",
          { from: Alice }
        ),
        "Ownable: caller is not the owner"
      );
    });

    it('Set treasury1 and allocate dexf', async function () {
      await dexfTokenInstance.setTreasury1(
        "0xA629E14908F5cE17F3AFA3BAF5F7318d06091362",
        { from: deployer }
      );

      await dexfTokenInstance.changeAllocation(
        new BigNumber(1000),
        1,
        3,
        { from: deployer }
      );

      const balance = await callMethod(
        dexfToken.methods.balanceOf,
        ["0xA629E14908F5cE17F3AFA3BAF5F7318d06091362"]
      );

      expect(new BigNumber(balance).eq(1000)).to.be.equal(true);
    });
  });

});
