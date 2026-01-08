// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//Это контракт реализации, который  хранит и управляет данными

contract ValueHolder {
    uint256 private value;

    function getValue() public view returns (uint256) {//Возвращает текущее значение value
        return value;
    }

    function setValue(uint256 _newValue) public {//Обновляет значение value
        value = _newValue;
    }

     function version() public pure returns (string memory) {//Возвращает номер версии контракта
        return "ValueHolder V1";
    }
}
