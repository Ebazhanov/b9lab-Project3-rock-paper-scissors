pragma solidity ^0.4.4;

import "./Ownable.sol";
import "./Stoppable.sol";

contract Destroyable is Stoppable {

  function destroy() onlyOwner onlyIfStopped public {
    selfdestruct(getOwner());
  }
}