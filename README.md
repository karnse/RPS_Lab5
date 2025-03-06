อธิบายโค้ดที่ป้องกันการ lock เงินไว้ใน contract

อธิบายโค้ดส่วนที่จัดการกับความล่าช้าที่ผู้เล่นไม่ครบทั้งสองคนเสียที

(ทำรวมกันเลย)
```solidity
function checkTimeOut() public {
    // ตรวจสอบเวลาว่าเกินกำหนดไหม (ในที่นี้กำหนดไว้ที่ 10 นาที)
    require(elapsedMinutes() > limitTime, "in time");
    // ถ้ามีผู้เล่นเพียงคนเดียว จะนำเงินคืนให้ผู้เล่นนั้น
    if(numPlayer==1)
    {
        payable(players[0]).transfer(reward);
        cleardata();
    }
    // ถ้ามีผู้เล่นสองคน และยังไม่มีการประกาศตัวเลือก
    // จะนำเงินคืนให้ผู้เล่นสองคนคนละครึ่ง
    else if(numPlayer==2 && numInput==0)
    {
        payable(players[0]).transfer(reward/2);
        payable(players[1]).transfer(reward/2);
        cleardata();
    }
    // ถ้ามีผู้เล่นสองคน และมีการประกาศตัวเลือก 1 คน
    // จะให้เงินรางวัลทั้งหมดกับคนประกาศตัวเลือก
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
    // ถ้ามีผู้เล่นสองคน และมีการประกาศตัวเลือก 2 คน แต่ยังไม่มีการเปิดเผยตัวเลือก
    // จะนำเงินคืนให้ผู้เล่นสองคนคนละครึ่ง
    else if (numPlayer == 2 && numInput == 2 && numReveal==0)
    {
        payable(players[0]).transfer(reward/2);
        payable(players[1]).transfer(reward/2);
        cleardata();
    }
    // ถ้ามีผู้เล่นสองคน และมีการประกาศตัวเลือก 2 คน และมีการเปิดเผยตัวเลือก 1 คน
    // จะให้เงินรางวัลทั้งหมดกับคนที่เปิดเผยตัวเลือก
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
```
อธิบายโค้ดส่วนที่ทำการซ่อน choice และ commit
```solidity
// ทำการซ่อนช้อยด้วย password(complex เพราะ bytes32)
function choiceHash(uint choice, bytes32 password) public pure returns(bytes32) {
    require(choice == 0 || choice == 1 || choice == 2 || choice == 3 || choice == 4);
    return getHash(keccak256(abi.encodePacked(choice, password)));
}

// ทำการ commit ช้อยด้วย hashedChoice แทนการใส่ choice เลย
function input(bytes32 hashedChoice) public  {
    require(numPlayer == 2);
    require(player_not_played[msg.sender]);
    commit(hashedChoice);
    player_not_played[msg.sender] = false;
    player_not_revaled[msg.sender] = false;
    numInput++;
}
```
อธิบายโค้ดส่วนทำการ reveal และนำ choice มาตัดสินผู้ชนะ
```solidity
// หลังจากที่ผู้เล่นทั้งสองคนทำการ commit แล้ว
// จะทำการ reveal ช้อยด้วย choice และ password ที่ซ่อนไว้
// จะต้องมีการเปิดเผยตัวเลือกทั้งสองคนจึงจะสามารถตัดสินผู้ชนะได้
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

// ทำการตัดสินผู้ชนะและจ่ายเงิน
function _checkWinnerAndPay() private {
    uint p0Choice = player_choice[players[0]];
    uint p1Choice = player_choice[players[1]];
    address payable account0 = payable(players[0]);
    address payable account1 = payable(players[1]);
    // ถ้าผู้เล่นคนที่ 1 ชนะ
    if ((p0Choice + 1) % 5 == p1Choice || (p0Choice + 2) % 5 == p1Choice) {
        // to pay player[1]
        account1.transfer(reward);
    }
    // ถ้าผู้เล่นคนที่ 0 ชนะ
    else if ((p1Choice + 1) % 5 == p0Choice || (p1Choice + 2) % 5 == p0Choice) {
        // to pay player[0]
        account0.transfer(reward);    
    }
    // ถ้าเสมอก็แบ่งเงินรางวัลกัน
    else {
        // to split reward
        account0.transfer(reward / 2);
        account1.transfer(reward / 2);
    }
    cleardata();
}
```


