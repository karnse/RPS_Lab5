
// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import './CommitReveal.sol';
import './TimeUnit.sol';

contract RPS is CommitReveal, TimeUnit {
    uint public numPlayer = 0;
    uint public numReveal = 0;
    uint public reward = 0;
    mapping (address => uint) public player_choice; // 0 - Rock, 1 - Paper , 2 - Scissors
    mapping(address => bool) public player_not_played;
    mapping(address => bool) public player_not_revaled;
    address[] public players;

    uint public numInput = 0;
    uint public limitTime = 10 minutes;

    function cleardata() private {
        numInput = 0;
        numPlayer = 0;
        numReveal = 0;
        reward = 0;

        for (uint i = 0; i < players.length; i++)
        {
            delete commits[players[i]];
            delete player_choice[players[i]];
            delete player_not_played[players[i]];
            delete player_not_revaled[players[i]];
        }

        delete players;
    }

    function addPlayer() public payable {
        require(numPlayer < 2);
        require(
            msg.sender == 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
            || msg.sender == 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
            || msg.sender == 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db
            || msg.sender == 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB
        );
        if (numPlayer > 0) {
            require(msg.sender != players[0]);
        }
        require(msg.value == 1 ether);
        reward += msg.value;
        player_not_played[msg.sender] = true;
        players.push(msg.sender);
        numPlayer++;

        setStartTime();
    }

    function choiceHash(uint choice, bytes32 password) public pure returns(bytes32) {
        require(choice == 0 || choice == 1 || choice == 2 || choice == 3 || choice == 4);
        return getHash(keccak256(abi.encodePacked(choice, password)));
    }


    function input(bytes32 hashedChoice) public  {
        require(numPlayer == 2);
        require(player_not_played[msg.sender]);
        commit(hashedChoice);
        player_not_played[msg.sender] = false;
        player_not_revaled[msg.sender] = false;
        numInput++;
    }

    function revealsChoice(uint choice, bytes32 password) public {
        require(numInput == 2);
        require(choice == 0 || choice == 1 || choice == 2 || choice == 3 || choice == 4);

        reveal(choiceHash(choice, password));

        player_choice[msg.sender] = choice;
        player_not_revaled[msg.sender] = true;
        
        numReveal++;
        if (numReveal == 2) {
            _checkWinnerAndPay();
        }
    }

    function checkTimeOut() public {
        
        require(elapsedMinutes() > limitTime, "in time");
        if(numPlayer==1)
        {
            payable(players[0]).transfer(reward);
            cleardata();
        }
        else if(numPlayer==2 && numInput==0)
        {
            payable(players[0]).transfer(reward/2);
            payable(players[1]).transfer(reward/2);
            cleardata();
        }
        else if(numPlayer==2 && numInput==1)
        {
            if (commits[players[1]].commit == 0)
            {
                payable(players[0]).transfer(reward);
            }
            else
            {
                payable(players[1]).transfer(reward);
            }
            cleardata();
        }
        else if (numPlayer == 2 && numInput == 2 && numReveal==0)
        {
            payable(players[0]).transfer(reward/2);
            payable(players[1]).transfer(reward/2);
            cleardata();
        }
        else if (numPlayer == 2 && numInput == 2 && numReveal==1)
        {
            if (commits[players[1]].revealed)
            {
                payable(players[1]).transfer(reward);
            }
            else
            {
                payable(players[0]).transfer(reward);
            }
            cleardata();
        }
    }

    function _checkWinnerAndPay() private {
        uint p0Choice = player_choice[players[0]];
        uint p1Choice = player_choice[players[1]];
        address payable account0 = payable(players[0]);
        address payable account1 = payable(players[1]);
        if ((p0Choice + 1) % 5 == p1Choice || (p0Choice + 2) % 5 == p1Choice) {
            // to pay player[1]
            account1.transfer(reward);
        }
        else if ((p1Choice + 1) % 5 == p0Choice || (p1Choice + 2) % 5 == p0Choice) {
            // to pay player[0]
            account0.transfer(reward);    
        }
        else {
            // to split reward
            account0.transfer(reward / 2);
            account1.transfer(reward / 2);
        }
        cleardata();
    }
}
