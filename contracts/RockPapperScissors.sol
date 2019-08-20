pragma solidity ^0.4.4;


contract RockPaperScissors {
  enum StatusesData {STARTED, ALL_CHOOSED, ALL_PASS_DECODED, GAME_ENDED, CHOICE_TIMEOUT}

  struct Game {
    address firstPlayerAddr;
    address secondPlayerAddr;
    uint gameId;
    uint winningChoince;
    uint firstPlayerScore;
    uint secondPlayerScore;
    uint deadLine;
    bool isGameEnded;
    bool everyoneChoose;
    bool everyChooseDecoded;

    StatusesData currStatus;
    mapping(address => GameMetainfo) gameInfo;
  }

  struct GameMetainfo {
    bytes32 choicesHashed;
    uint choices;
    uint balances;
  }

  uint gamesId = 1;
  uint daySeconds = 86400;

  mapping(uint => Game) gamesMap;

  event LogNewGameCreation(address player1, address player2, uint gameId);
  event LogGameStopped(address whoStops, uint deadline, bool success);
  event LogChoice(address player, bytes32 choiceHashed, uint gameId, uint bet);
  event LogChoicesDecoding(address player, uint choice);
  event LogWinnedChoice(uint winnedChoice);
  event LogBenefits(address winner, uint winnedAmount);
  event LogMoneyTransfering(uint amount, address receiver);
  event LogAllPassDeconded(bool success);
  event LogPassSubmited(string passw, address from, uint gameId);
  //0 step - receive hashedPassword + choice
  function returnHash(string pass, uint choice) pure returns (bytes32){
    return keccak256(pass, choice);
  }

  //1 step - player should create New Game;
  function createGame(address firstPlayer, address secondPlayer)  returns (uint yourGameId){
    require(firstPlayer != 0);
    require(secondPlayer != 0);


    Game tempGameData;
    tempGameData.firstPlayerAddr = firstPlayer;
    tempGameData.secondPlayerAddr = secondPlayer;
    tempGameData.gameId = gamesId;
    tempGameData.currStatus = StatusesData.STARTED;
    tempGameData.deadLine = now + daySeconds;
    gamesMap[gamesId] = tempGameData;

    gamesId++;
    emit LogNewGameCreation(tempGameData.firstPlayerAddr, tempGameData.secondPlayerAddr, tempGameData.gameId);
    return tempGameData.gameId;
  }

  //2 step - player should make his choice;
  function makeChoice(bytes32 choice, uint gameId) payable returns (bool result){
    Game tempGameData = gamesMap[gameId];

    require(tempGameData.currStatus != StatusesData.ALL_CHOOSED);
    require(tempGameData.currStatus != StatusesData.GAME_ENDED);
    require(msg.value != 0);
    require(msg.sender == tempGameData.firstPlayerAddr || msg.sender == tempGameData.secondPlayerAddr);
    tempGameData.gameInfo[msg.sender].choicesHashed = choice;
    tempGameData.gameInfo[msg.sender].balances = msg.value;
    tempGameData.deadLine = tempGameData.deadLine + daySeconds;
    if (tempGameData.gameInfo[tempGameData.firstPlayerAddr].choicesHashed != 0 && tempGameData.gameInfo[tempGameData.secondPlayerAddr].choicesHashed != 0) {
      tempGameData.currStatus = StatusesData.ALL_CHOOSED;
    }
    gamesMap[gameId] = tempGameData;
    emit LogChoice(msg.sender, choice, gameId, msg.value);
    return true;
  }

  //3 step - player should check is everybody choose;
  function isEveryoneChoose(uint gameId) public view returns (bool){
    if (gamesMap[gameId].currStatus == StatusesData.ALL_CHOOSED) {
      return true;
    }
  }

  //4 step - Submit and decode password
  function submitPassword(string password, uint gameId) public returns (bool succes){
    require(gameId != 0);
    Game tempGameData = gamesMap[gameId];
    require(tempGameData.currStatus == StatusesData.ALL_CHOOSED);
    require(bytes(password).length != 0);
    require(msg.sender == tempGameData.firstPlayerAddr || msg.sender == tempGameData.secondPlayerAddr);
    checkSelection(password, msg.sender, gameId);
    emit LogPassSubmited(password, msg.sender, gameId);
    return true;
  }


  //5 step - check who wins;
  function checkWinner(uint gameId) public returns (uint status){
    require(gameId != 0);
    Game tempGameData = gamesMap[gameId];
    require(gamesMap[gameId].currStatus != StatusesData.GAME_ENDED || gamesMap[gameId].currStatus != StatusesData.CHOICE_TIMEOUT);
    require(msg.sender == tempGameData.firstPlayerAddr || msg.sender == tempGameData.secondPlayerAddr);
    if (tempGameData.currStatus == StatusesData.ALL_PASS_DECODED) {
      if (checkConditions(gameId)) {
        if (tempGameData.currStatus != StatusesData.GAME_ENDED) {
          setWinnerBenefits(gameId);
          return 1;
        }
      }
    } else {
      return 0;
    }
  }

  function getFirstScore(uint gameId) public view returns (uint){
    return gamesMap[gameId].firstPlayerScore;
  }


  function getSecondScore(uint gameId) public view returns (uint){
    return gamesMap[gameId].secondPlayerScore;
  }

  function stopGame(uint gameId) public returns (bool success){
    Game tempGameData = gamesMap[gameId];
    address firstPlayer = tempGameData.firstPlayerAddr;
    address secondPlayer = tempGameData.secondPlayerAddr;
    if (tempGameData.currStatus == StatusesData.STARTED && tempGameData.deadLine < now) {
      tempGameData.currStatus = StatusesData.CHOICE_TIMEOUT;
      emit LogGameStopped( msg.sender,  tempGameData.deadLine, true);
    } else if (tempGameData.currStatus == StatusesData.ALL_CHOOSED && tempGameData.deadLine < now) {
      if (tempGameData.gameInfo[firstPlayer].choices != 0 && tempGameData.gameInfo[secondPlayer] .choices == 0) {
        tempGameData.gameInfo[firstPlayer].balances += tempGameData.gameInfo[secondPlayer].balances;
        tempGameData.gameInfo[secondPlayer].balances = 0;
        tempGameData.currStatus = StatusesData.CHOICE_TIMEOUT;
        emit LogGameStopped( msg.sender,  tempGameData.deadLine, true);
      } else if (tempGameData.gameInfo[firstPlayer].choices == 0 && tempGameData.gameInfo[secondPlayer].choices != 0) {
        tempGameData.gameInfo[secondPlayer].balances += tempGameData.gameInfo[firstPlayer].balances;
        tempGameData.gameInfo[firstPlayer].balances = 0;
        tempGameData.currStatus = StatusesData.CHOICE_TIMEOUT;
        emit LogGameStopped( msg.sender,  tempGameData.deadLine, true);
      }
    }else {
      emit LogGameStopped( msg.sender,  tempGameData.deadLine, false);
    }
    gamesMap[gameId] = tempGameData;
    return true;
  }

  //decode choices
  function checkSelection(string userPass, address userAddr, uint gameId) private returns (bool success){
    require(bytes(userPass).length != 0);
    require(userAddr != 0);
    require(gameId != 0);
    Game tempGameData = gamesMap[gameId];
    require(tempGameData.currStatus == StatusesData.ALL_CHOOSED);
    require(tempGameData.gameInfo[userAddr].choicesHashed != 0);

    for (uint i = 0; i < 3; i++) {
      if (tempGameData.gameInfo[userAddr].choicesHashed == keccak256(userPass, i)) {
        tempGameData.gameInfo[userAddr].choices = i;
        emit LogChoicesDecoding(userAddr, i);
      }
    }
    if (tempGameData.gameInfo[tempGameData.firstPlayerAddr].choices != 0 && tempGameData.gameInfo[tempGameData.secondPlayerAddr].choices != 0) {
      tempGameData.currStatus = StatusesData.ALL_PASS_DECODED;
      emit LogAllPassDeconded(true);
    }
    gamesMap[gameId] = tempGameData;
    return true;
  }


  //check winned combination
  function checkConditions(uint gameId) private returns (bool success){
    require(gameId != 0);
    Game tempGameData = gamesMap[gameId];
    require(tempGameData.currStatus == StatusesData.ALL_PASS_DECODED);
    uint firstChoice = tempGameData.gameInfo[tempGameData.firstPlayerAddr].choices;
    uint secondChoice = tempGameData.gameInfo[tempGameData.secondPlayerAddr].choices;
    if (firstChoice == secondChoice) {
      tempGameData.winningChoince = 4;
      //In case of draw we should stop game
      tempGameData.currStatus = StatusesData.GAME_ENDED;
    } else if ((firstChoice == 1 || secondChoice == 1) &&
      (firstChoice == 2 || secondChoice == 2)) {
      tempGameData.winningChoince = 1;
    } else if ((firstChoice == 2 || secondChoice == 2) &&
      (firstChoice == 3 || secondChoice == 3)) {
      tempGameData.winningChoince = 2;
    } else {
      tempGameData.winningChoince = 3;
    }
    emit LogWinnedChoice(tempGameData.winningChoince);
    gamesMap[gameId] = tempGameData;
    return true;
  }


  function setWinnerBenefits(uint gameId) private returns (bool success){
    require(gameId != 0);
    Game tempGameData = gamesMap[gameId];
    require(tempGameData.winningChoince != 0);
    tempGameData.currStatus = StatusesData.ALL_PASS_DECODED;

    if (tempGameData.winningChoince == tempGameData.gameInfo[tempGameData.firstPlayerAddr].choices) {
      tempGameData.firstPlayerScore = tempGameData.firstPlayerScore + 1;
      tempGameData.gameInfo[tempGameData.firstPlayerAddr].balances += tempGameData.gameInfo[tempGameData.secondPlayerAddr].balances;
      tempGameData.gameInfo[tempGameData.secondPlayerAddr].balances = 0;
      emit LogBenefits(tempGameData.firstPlayerAddr, tempGameData.gameInfo[tempGameData.firstPlayerAddr].balances);
    } else if (tempGameData.winningChoince == tempGameData.gameInfo[tempGameData.secondPlayerAddr].choices) {
      tempGameData.secondPlayerScore = gamesMap[gameId].secondPlayerScore + 1;
      tempGameData.gameInfo[gamesMap[gameId].secondPlayerAddr].balances += tempGameData.gameInfo[tempGameData.firstPlayerAddr].balances;
      tempGameData.gameInfo[gamesMap[gameId].firstPlayerAddr].balances = 0;
      emit LogBenefits(tempGameData.secondPlayerAddr, tempGameData.gameInfo[tempGameData.secondPlayerAddr].balances);
    }
    tempGameData.currStatus = StatusesData.GAME_ENDED;
    gamesMap[gameId] = tempGameData;
    return true;
  }


  function withdrawFunds(uint gameId) public {
    require(gamesMap[gameId].currStatus == StatusesData.GAME_ENDED || gamesMap[gameId].currStatus == StatusesData.CHOICE_TIMEOUT);
    require(gamesMap[gameId].gameInfo[msg.sender].balances > 0);
    emit LogMoneyTransfering(gamesMap[gameId].gameInfo[msg.sender].balances, msg.sender);
    msg.sender.transfer(gamesMap[gameId].gameInfo[msg.sender].balances);
    gamesMap[gameId].gameInfo[msg.sender].balances = 0;
  }


}