var REERC721Token = artifacts.require('REERC721Token');

contract('REERC721Token', accounts => {

    let contract;

    const account_one = accounts[0];
    const account_two = accounts[1];

    describe("MATCH ERC721 SPEC", function () {
        beforeEach(async function () {

            contract = await REERC721Token.new({from: account_one});

            await contract.mint(account_one, 1, { from: account_one });
            await contract.mint(account_one, 2, { from: account_one });
            await contract.mint(account_one, 3, { from: account_one });
            await contract.mint(account_two, 4, { from: account_one });
            await contract.mint(account_two, 5, { from: account_one });
        
        })

        it("SHOULD RETURN TOTAL SUPPLY", async function () { 
            
            let totalSupply = await contract.totalSupply.call();
            
            assert.equal(5, totalSupply, "FIVE TOKENS MINTED ARE EXPECTED");

        })

        it("SHOULD GET TOKEN BALANCE", async function () { 
        
            let balanceOne = await contract.balanceOf.call(account_one);
            assert.equal(3, balanceOne, "account_one HAS THREE TOKENS");
        
            let balanceTwo = await contract.balanceOf.call(account_two);
            assert.equal(2, balanceTwo, "account_two HAS TWO TOKENS");
        
        })

        it("SHOULD RETURN TOKEN URI", async function () { 

            let tokenUriOne = await contract.tokenURI.call(1);
            assert.equal("https://s3-us-west-2.amazonaws.com/udacity-blockchain/capstone/1", tokenUriOne,   "URI OF TOKEN WITH ID = 1 IS NOT CORRECT");

            let tokenUriTwo = await contract.tokenURI.call(2);
            assert.equal("https://s3-us-west-2.amazonaws.com/udacity-blockchain/capstone/2", tokenUriTwo,   "URI OF TOKEN WITH ID = 2 IS NOT CORRECT");

            let tokenUriThree = await contract.tokenURI.call(3);
            assert.equal("https://s3-us-west-2.amazonaws.com/udacity-blockchain/capstone/3", tokenUriThree, "URI OF TOKEN WITH ID = 3 IS NOT CORRECT");

            let tokenUriFour = await contract.tokenURI.call(4);
            assert.equal("https://s3-us-west-2.amazonaws.com/udacity-blockchain/capstone/4", tokenUriFour,  "URI OF TOKEN WITH ID = 4 IS NOT CORRECT");

            let tokenUriFive = await contract.tokenURI.call(5);
            assert.equal("https://s3-us-west-2.amazonaws.com/udacity-blockchain/capstone/5", tokenUriFive,  "URI OF TOKEN WITH ID = 5 IS NOT CORRECT");

        })

        it("SHOULD TRANSFER TOKEN FROM ONE OWNER TO ANOTHER", async function () { 
            
            try 
            {
                await contract.transferFrom(account_one, account_two, 2, { from: account_one });
            }
            catch(e) {
                console.log("TransferFrom FAILED", e);
            }
            
            let ownerOfOne = await contract.ownerOf.call(1);
            assert.equal(account_one, ownerOfOne,   "OWNER OF TOKEN WITH ID = 1 IS NOT CORRECT");
            
            let ownerOfTwo = await contract.ownerOf.call(2);
            assert.equal(account_two, ownerOfTwo,   "OWNER OF TOKEN WITH ID = 2 IS NOT CORRECT");
            
            let ownerOfThree = await contract.ownerOf.call(3);
            assert.equal(account_one, ownerOfThree, "OWNER OF TOKEN WITH ID = 3 IS NOT CORRECT");

        })

    });

    describe("HAVE OWNERSHIP PROPERTIES", function () {
        beforeEach(async function () { 
            contract = await REERC721Token.new({from: account_one});
        })

        it('SHOULD FAIL WHEN MINTING WITH ADDRESS THAT IS NOT CONTRACT OWNER', async function () { 
            
            let accessDenied = false;

            try
            {
                await contract.mint(account_one, 4, { from: account_two });
            } catch(e) 
            {
                accessDenied = true;
            }
            assert.equal(true, accessDenied, "ADDRESS NOT ALLOWED TO MINT");
            
            let balanceTwo = await contract.balanceOf.call(account_two);
            assert.equal(0, balanceTwo, "Account_two HAS NO TOKENS");
        
        })

        it('SHOULD RETURN CONTRACT OWNER', async function () { 

            let owner = await contract.checkOwner.call();
            assert.equal(account_one, owner, "account_one EXPECTED");
        
        })
    });

})