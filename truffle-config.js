module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",
      port: 8545,
      network_id: "*",
    },
  },
  compilers: {
    solc: {
      version: "0.8.10", // Use the same Solidity version as your smart contract
      settings: {
        optimizer: {
          enabled: true,
          runs: 200, // Adjust the number of runs as needed for your contract
        },
      },
    },
  },
};
