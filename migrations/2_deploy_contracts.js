const fs = require('fs');
const dexfToken = artifacts.require("./DEXF.sol");
const lpFarm = artifacts.require("./LPFarming.sol");
const erc20 = artifacts.require("./ERC20Mock.sol");
const governor = artifacts.require("./Governance/GovernorAlpha.sol");
const timelock = artifacts.require("./Governance/Timelock.sol");

function expertContractJSON(contractName, instance) {
  const path = "./test/abis/" + contractName + ".json";
  const data = {
    contractName,
    "address": instance.address,
    "abi": instance.abi
  }

  fs.writeFile(path, JSON.stringify(data), (err) => {
    if (err) throw err;
    console.log('Contract data written to file');
  });
};

module.exports = async function (deployer) {
  console.log("Contract deploy started.");

  await deployer.deploy(dexfToken);
  await deployer.deploy(lpFarm, dexfToken.address);
  await deployer.deploy(erc20);

  console.log("Contract deploy finished.");

  expertContractJSON('DEXF', dexfToken);
  expertContractJSON('lpFarm', lpFarm);
  expertContractJSON('erc20', erc20);
};
