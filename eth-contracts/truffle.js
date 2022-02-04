const HDWalletProvider = require('truffle-hdwallet-provider');
const infuraKey = "b20ea9f751b1442dbe5f2d1257d00bc5";

const mnemonic = "globe crystal hood calm concert inside dream strike dice crew input basket";

module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",
      port: 7545,
      network_id: "*" // Match any network id
    },
    rinkeby: {
      provider: () => new HDWalletProvider(mnemonic, `https://rinkeby.infura.io/v3/${infuraKey}`),
        network_id: 4,       // rinkeby's id
        gas: 4500000,        // rinkeby has a lower block limit than mainnet
        gasPrice: 10000000000
    }
  },
  compilers: {
    solc: {
      version: "^0.8.0"
    }
  }
};