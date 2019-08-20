import Web3 from 'web3';
export const initWeb3 = async () => {
    var web3 = window.web3
    console.log('Injected web3 detected.');
    var provider = new Web3.providers.HttpProvider('http://127.0.0.1:8545')
    web3 = new Web3(provider)
    return web3;
}