const { expectEvent, shouldFail } = require('openzeppelin-test-helpers');

const Election = artifacts.require('Election');

const { calculateHash, compareFn, calculateLowerHash, checkIfEqual } = require('./utils.js');

const {
    START_VALIDATORS,
    END_VALIDATORS,
    CYCLE_VALIDATORS
} = process.env;

contract('Election', (accounts) => {
    const publicKeys = [
        '115434628280228012381862380887561447423853081038375933689188940723037860889995',
        '8186326775388394783136067162174741017941982912050343718338878780655254853254',
        '80080390151569735403994316323463067956866497482808386072378025647129452626940',
        '68630921641858559169526762297188427038475883292130005674946233300156192554548',
        '76705234693771336309645220631926529393964869066999850012018539473567479866530',
        '68647644622464110327210607889559284420776271828084297090082270068081112718761',
        '96180695489023479175883571415173746118074062530299790369616145247017650185845',
        '109595722358039830379858391128487275133037869347420215341164378831308260445922'
    ];

    const nonce = 0;

    beforeEach(async () => {
        this.election = await Election.new(
            START_VALIDATORS,
            CYCLE_VALIDATORS,
            END_VALIDATORS
        );
        this.elects = [];
        for (let i = 0; i < publicKeys.length; i++) {
            this.elects.push({
                hash: calculateHash(publicKeys[i], 0, this.election.address),
                publicKey: publicKeys[i]
            });
        }

        this.elects.sort(compareFn);
    });

    describe('Electing person A - electMe', () => {
        describe('when their is no elected persons', () => {
            it('person A is elected', async () => {
                const publicKey = this.elects[0].publicKey;

                await this.election.electMe(publicKey, nonce, this.elects[0].hash, { from: accounts[0] });
                const head = await this.election.head();
                assert(checkIfEqual(head, publicKey));
            });

            it('wrongly calculated hash', async () => {
                const publicKey = this.elects[0].publicKey;

                const hash = calculateHash(publicKey, nonce + 1, this.election.address);

                await shouldFail.reverting(this.election.electMe(publicKey, nonce, hash, { from: accounts[0] }));
            });
        });

        describe('when A is only elected person', () => {
            it('sending bigger hash', async () => {
                const publicKey = this.elects[0].publicKey;

                await this.election.electMe(publicKey, nonce, this.elects[0].hash, { from: accounts[0] });

                const data = await calculateLowerHash(this.elects[0].hash, publicKey, nonce, this.election.address);
                await this.election.electMe(publicKey, data.nonce, data.hash);

                const head = await this.election.head();
                assert(checkIfEqual(head, publicKey));
            });

            it('sending lower hash', async () => {
                const nonce = 0;

                const data = await calculateLowerHash(this.elects[0].hash, this.elects[0].publicKey, nonce, this.election.address);
                await this.election.electMe(this.elects[0].publicKey, data.nonce, data.hash, { from: accounts[0] });

                await shouldFail.reverting(this.election.electMe(this.elects[0].publicKey, nonce, this.elects[0].hash, { from: accounts[0] }));
            });
        });

        describe('when person B is electing himself', async () => {
            it('person A has smaller hash then person B', async () => {
                await this.election.electMe(this.elects[0].publicKey, nonce, this.elects[0].hash, { from: accounts[0] });
                await this.election.electMe(this.elects[1].publicKey, nonce, this.elects[1].hash, { from: accounts[1] });
                const head = await this.election.head();
                assert(checkIfEqual(head, this.elects[0].publicKey));
            });

            it('person A has bigger hash then person B', async () => {
                await this.election.electMe(this.elects[1].publicKey, nonce, this.elects[1].hash, { from: accounts[1] });
                await this.election.electMe(this.elects[0].publicKey, nonce, this.elects[0].hash, { from: accounts[0] });
                const head = await this.election.head();
                assert(checkIfEqual(head, this.elects[0].publicKey));
            });

            it('person B relect himself with lower hash, and his previus hash was larger then A', async () => {
                await this.election.electMe(this.elects[1].publicKey, nonce, this.elects[1].hash, { from: accounts[1] });
                await this.election.electMe(this.elects[0].publicKey, nonce, this.elects[0].hash, { from: accounts[0] });

                const data = await calculateLowerHash(this.elects[0].hash, this.elects[1].publicKey, nonce, this.election.address);
                await this.election.electMe(this.elects[1].publicKey, data.nonce, data.hash, { from: accounts[1] });

                const head = await this.election.head();
                assert(checkIfEqual(head, this.elects[1].publicKey));
            });
        });

        describe('when person B & C are elected persons', async () => {
            it('person A hash is between ', async () => {
                await this.election.electMe(this.elects[1].publicKey, nonce, this.elects[1].hash, { from: accounts[1] });

                const dataA = await calculateLowerHash(this.elects[1].hash, this.elects[0].publicKey, nonce, this.election.address);
                const dataC = await calculateLowerHash(dataA.hash, this.elects[2].publicKey, nonce, this.election.address);

                await this.election.electMe(this.elects[2].publicKey, dataC.nonce, dataC.hash, { from: accounts[2] });
                await this.election.electMe(this.elects[0].publicKey, dataA.nonce, dataA.hash, { from: accounts[0] });

                const head = await this.election.head();
                assert(checkIfEqual(head, this.elects[2].publicKey));
            });

            it('person A is relecting himself with hash that is lower and old one was betwean B & C ', async () => {
                await this.election.electMe(this.elects[1].publicKey, nonce, this.elects[1].hash, { from: accounts[1] });

                const dataA = await calculateLowerHash(this.elects[1].hash, this.elects[0].publicKey, nonce, this.election.address);
                const dataC = await calculateLowerHash(dataA.hash, this.elects[2].publicKey, nonce, this.election.address);

                await this.election.electMe(this.elects[2].publicKey, dataC.nonce, dataC.hash, { from: accounts[2] });
                await this.election.electMe(this.elects[0].publicKey, dataA.nonce, dataA.hash, { from: accounts[0] });

                const newDataA = await calculateLowerHash(dataC.hash, this.elects[0].publicKey, nonce, this.election.address);

                await this.election.electMe(this.elects[0].publicKey, newDataA.nonce, newDataA.hash, { from: accounts[0] });

                const head = await this.election.head();
                assert(checkIfEqual(head, this.elects[0].publicKey));
            });
        });
    });
    describe('PublishGenesisSigs()', () => {
        describe('publishing genesis block', async () => {
            it('with 3 validators and validator[0] is publishing genesis', async () => {
                await this.election.electMe(this.elects[3].publicKey, nonce, this.elects[3].hash, { from: accounts[2] });
                await this.election.electMe(this.elects[2].publicKey, nonce, this.elects[2].hash, { from: accounts[0] });
                await this.election.electMe(this.elects[1].publicKey, nonce, this.elects[1].hash, { from: accounts[1] });

                await this.election.publishGenesisSigs({ from: accounts[1]});
                const head = await this.election.head();
                assert(checkIfEqual(head, 0));
            });

            describe('with 3 validators and validator[0] is NOT publishing genesis', async () => {
                it('should revert', async () => {
                    await this.election.electMe(this.elects[3].publicKey, nonce, this.elects[3].hash, {from: accounts[2]});
                    await this.election.electMe(this.elects[2].publicKey, nonce, this.elects[2].hash, {from: accounts[0]});
                    await this.election.electMe(this.elects[1].publicKey, nonce, this.elects[1].hash, {from: accounts[1]});

                    await shouldFail.reverting(this.election.publishGenesisSigs({from: accounts[0]}));
                });
            });

            describe('insufficient number of validators', () => {
                it('should revert', async () => {
                    await this.election.electMe(this.elects[3].publicKey, nonce, this.elects[3].hash, {from: accounts[2]});
                    await this.election.electMe(this.elects[2].publicKey, nonce, this.elects[2].hash, {from: accounts[0]});

                    await shouldFail.reverting(this.election.publishGenesisSigs({from: accounts[0]}));
                });
            });
        });
    });

    describe('PublishGenesis()', () => {
        describe('publishing new set of validators', () => {
            it('when their are 3 validators and their are 3 new validators incoming', async () => {
                await this.election.electMe(this.elects[3].publicKey, nonce, this.elects[3].hash, { from: accounts[2] });
                await this.election.electMe(this.elects[2].publicKey, nonce, this.elects[2].hash, { from: accounts[0] });
                await this.election.electMe(this.elects[1].publicKey, nonce, this.elects[1].hash, { from: accounts[1] });

                await this.election.publishGenesisSigs({ from: accounts[1]});


                await this.election.electMe(this.elects[0].publicKey, nonce, this.elects[0].hash, { from: accounts[3] });
                await this.election.electMe(this.elects[4].publicKey, nonce, this.elects[4].hash, { from: accounts[4] });
                await this.election.electMe(this.elects[5].publicKey, nonce, this.elects[5].hash, { from: accounts[5] });

                await this.election.publishSigs({ from: accounts[5]});
            })
        });
    });
});
