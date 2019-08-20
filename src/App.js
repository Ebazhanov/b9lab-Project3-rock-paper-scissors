import React, {Component} from 'react'
import * as services from './config/contract-services'
import {initWeb3} from "./utils/getWeb3";

import './css/oswald.css'
import './css/open-sans.css'
import './css/pure-min.css'
import './App.css'

var contractInstance;
var userList;
var web3Instance;

class App extends Component {
  constructor(props) {
    super(props)

    this.state = {
      storageValue: 0,
      web3: null,
      firstPlayerScore: 0,
      secondPlayerScore: 0
    }
    this.handleChange = this.handleChange.bind(this);
  }


  async componentWillMount() {
    web3Instance = await  initWeb3();
    contractInstance = await  services.getContract(web3Instance);
    userList = await  services.getAccounts(web3Instance);
  }


  handleChange(event) {
    console.log(event.target.id)
    if (event.target.id == 1) {
      this.setState({value: event.target.value})
    } else if (event.target.id == 2) {
      this.setState({passw: event.target.value})
    }
  }


  async checkWinner() {
    let result =  await services.isEveryoneChoose(contractInstance, userList[0]);
    if (!result){
      alert("Wait for second player");
      return;
    }


    await services.checkWinner(contractInstance, userList[0]);
    let first = await services.getFirstAccScore(contractInstance, userList[0]);
    let second = await services.getSecondAccScore(contractInstance, userList[0]);
    this.setState({
      firstPlayerScore: first,
      secondPlayerScore: second
    })
  }





  makeChoice(e) {

    services.makeChoice(this.state.passw, e.target.id, this.state.value, contractInstance, userList[0], web3Instance);
  }


  async destroy() {
    await  services.destroyContract(contractInstance, userList[0]);
  }

  render() {


    return (
      <div className="App">


        <main className="container">
          <div className="pure-g">
            <div className="pure-u-1-1">
              <h1>RockPaperScissors application</h1>

              <label>
                Your bid:
                <input id="1" type="number" value={this.state.value} onChange={this.handleChange}/>
              </label>
              <label>
                Your password:
                <input id="2" type="password" value={this.state.passw} onChange={this.handleChange}/>
              </label>
              <br/>
              <button id='1' onClick={this.makeChoice.bind(this)}>I choose Rock</button>
              <button id='2' onClick={this.makeChoice.bind(this)}>I choose Paper</button>
              <button id='3' onClick={this.makeChoice.bind(this)}>I choose Scissors</button>
              <br/>
              <button onClick={this.checkWinner.bind(this)}>Check winner</button>
              <h2>First player score: {this.state.firstPlayerScore}</h2>
              <h2>Second player score: {this.state.secondPlayerScore}</h2>

            </div>
          </div>
        </main>
      </div>
    );
  }
}

export default App
