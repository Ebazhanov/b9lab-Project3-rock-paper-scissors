var RockPapperScissors = artifacts.require("RockPaperScissors");
var hash1;
var hash2;
var acc1;
var acc2;
var contractInstance;
var gameIndex;
var bet = 10;
contract('RockPapperScissors', function (accounts) {
  acc1 = accounts[0];
  acc2 = accounts[1];
  it("Getting of contract instance ", function () {
    return RockPapperScissors.deployed().then(function (instance) {
      console.log(instance)
      contractInstance = instance;
    })
  });

  it("Getting of first hash", async function () {
    hash1 = await contractInstance.returnHash.call('aaa', 1);
    console.log(hash1)
  });
  it("Getting of second hash", async function () {
    hash2 = await contractInstance.returnHash.call('bbb', 2);
    console.log(hash2)
  });


  describe('Game flow', function () {
    describe('Game starting', function () {
      it('returns not zero', async function () {
        const {logs} = await contractInstance.createGame(acc1, acc2, {from: acc1, gas: 3000000});
        assert.equal(logs.length, 1);
        assert.equal(logs[0].event, 'LogNewGameCreation');
        assert(logs[0].args.gameId.toString() != 0);
        gameIndex = logs[0].args.gameId.toString();
      });
    });
    describe('First Choice', function () {
      it('returns true', async function () {
        const res = await contractInstance.makeChoice(hash1, gameIndex, {from: acc1, value: bet});
        assert(res);
      });
    });
    describe('Second Choice', function () {
      it('returns true', async function () {
        const res = await contractInstance.makeChoice(hash2, gameIndex, {from: acc2, value: bet});
        assert(res);

      });
    });
    describe('Submit First  Pass', function () {
      it('returnstrue', async function () {
        const res = await contractInstance.submitPassword('aaa', gameIndex, {from: acc1});
        assert(res);
      });
    });
    describe('Submit Second Pass', function () {
      it('returns true', async function () {
        const res = await contractInstance.submitPassword('bbb', gameIndex, {from: acc2});
        assert(res);
      });
    });
    describe('Check Winner', function () {
      it('returns status', async function () {
        const gameRes = await contractInstance.checkWinner(gameIndex, {from: acc1});
        assert(gameRes.logs[0].args.winnedChoice.eq(1));
        assert.equal(gameRes.logs[0].event, 'LogWinnedChoice');
        assert.equal(gameRes.logs[1].event, 'LogBenefits');
        assert(gameRes.logs[1].args.winnedAmount.eq(bet + bet));
      });
    });


  });
});