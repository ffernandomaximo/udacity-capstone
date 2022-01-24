var SolnSquareVerifier = artifacts.require('./SolnSquareVerifier');
var Verifier = artifacts.require('./verifier');
var Proof1 = require('../../zokrates/code/square/proof.json');

contract('SOLNSQUAREVERIFIER', accounts => {
    beforeEach(async () => {
        this.verifier = await Verifier.new();
        this.contract = await SolnSquareVerifier.new(this.verifier.address);
    });

    it('A NEW SOLUTION CAN BE ADDED FOR CONTRACT', async () => {
        await this.contract.addSolution(accounts[0], 1);

        let events = await this.contract.getPastEvents('SolutionAdded');    
        assert.equal(events.length, 1);
    
    })

    it('AN ERC721 TOKEN CAN BE MINTED FOR CONTRACT', async () => {
        const tokenId = 1902;
        await this.contract.mintNFT(tokenId, Proof1.proof, Proof1.inputs);
        
        let data = (await this.contract.getPastEvents('Transfer'))[0].returnValues;
        let totalSupply = await this.contract.totalSupply();

        assert.equal(data.tokenId, tokenId.toString());
        assert.equal(data.to, accounts[0]);
        assert.equal(totalSupply, 1);
    
    })

});