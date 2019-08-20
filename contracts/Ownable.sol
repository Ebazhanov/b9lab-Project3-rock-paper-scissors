pragma solidity ^0.4.4;

contract Ownable {
  address private owner;

  function Ownable() public {
    owner = msg.sender;
  }

  function getOwner() public returns(address){
    return owner;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
}