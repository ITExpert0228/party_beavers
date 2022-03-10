const colors = require('colors')
const PartyBeaver = artifacts.require('PartyBeaverUpgradeable')
const { deployProxy } = require('@openzeppelin/truffle-upgrades')

module.exports = async deployer => {
  const app = await deployProxy(PartyBeaver, { deployer, initializer: 'initialize' })
  const owner = await app.owner()
  console.log(colors.grey(`PartyBeaver contract owner: ${owner}`))
  console.log(colors.green('PartyBeaver contract address:'))
  console.log(colors.yellow(app.address))
}
