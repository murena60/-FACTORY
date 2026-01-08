// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//Factory Contract - контракт с применением фабрики

contract CloneFactory {
    event CloneCreated(address cloneAddress, bytes32 salt);

    //Развертывает новый контракт с использованием CREATE2
    //Принимаем байткод и соль. Возвращаем адрес созданного клона.

    function deployClone(bytes memory bytecode, bytes32 salt) external returns (address cloneAddress) {
        assembly {
            cloneAddress := create2(
                0,                              //  ETH, отправленные вместе с вызовом
                add(bytecode, 0x20),           // байт-код и префикс длины
                mload(bytecode),               // длина байт-кода
                salt                           // соль
            )
        }
        require(cloneAddress != address(0), "CREATE2 failed");
        emit CloneCreated(cloneAddress, salt);
    }
     //функция возвращает адрес, который будет иметь контракт, 
     //если его развернуть с данными salt и bytecodeHash
    function predictAddress(bytes32 salt, bytes32 bytecodeHash) external view returns (address) {
        return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, bytecodeHash)))));
    }
    
    //функция возвращает байткод для развертывания Clonable 
    //с заданными параметрами конструктора: initialValue и address creator.
    function getBytecode(uint256 initialValue, address creator) external pure returns (bytes memory) {
        return abi.encodePacked(type(Clonable).creationCode, abi.encode(initialValue, creator));
    }

    //функция  возвращает хеш байткода.
    function getBytecodeHash(uint256 initialValue, address creator) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(type(Clonable).creationCode, abi.encode(initialValue, creator)));
    }
}
