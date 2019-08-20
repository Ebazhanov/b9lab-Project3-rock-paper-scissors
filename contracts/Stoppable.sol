pragma solidity ^0.4.4;

import "./Ownable.sol";

contract Stoppable is Ownable {
  bool private stopped;

  event LogStopContract(bool, address);
  event LogResumeContract(bool, address);

  constructor(bool isStopped){
    stopped = isStopped;
  }

  function stopContract() public onlyOwner onlyIfRunning returns (bool success) {
    LogStopContract(true, msg.sender);
    stopped = true;
    return true;
  }

  function resumeContract() public onlyOwner onlyIfStopped returns (bool success) {
    LogResumeContract(true, msg.sender);
    stopped = false;
    return true;
  }

  modifier onlyIfRunning {
    require(!stopped);
    _;
  }
  modifier onlyIfStopped {
    require(stopped);
    _;
  }

}
