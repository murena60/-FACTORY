// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//Базовый контракт, который будет клонироваться
//Этот контракт является базовым контрактом, 
//экземпляры которого будут создаваться с помощью фабрики


contract Clonable {
    uint256 public value;
    address public creator;

    constructor(uint256 _initialValue, address _creator) {
        value = _initialValue;
        creator = _creator;
    }

    function setValue(uint256 _newValue) public {//Функция setValue позволяет изменять значение value
        value = _newValue;
    }
}
