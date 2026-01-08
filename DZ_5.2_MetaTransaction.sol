//Метатранзакции позволяют пользователям взаимодействовать со смарт-контрактом, 
//не оплачивая газ напрямую. Вместо этого, кто-то другой (Relayer) оплачивает газ за них.  
//Это достигается путем подписи сообщения вне сети (off-chain), содержащего данные транзакции.  
//Затем Relayer отправляет эту подписанную транзакцию в контракт. 
// Контракт проверяет подпись и выполняет транзакцию от имени пользователя.
//Пользователям не нужно иметь ETH для оплаты газа - основное преимущество метатранзакций.
//Пользователи должны доверять Relayer

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//Импортируем библиотеку ECDSA из OpenZeppelin для проверки подписей.

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract MyToken is ERC20, AccessControl {
    using ECDSA for bytes32;

    bytes32 public constant MODIFIER_ROLE = keccak256("MODIFIER_ROLE");
    bytes32 public constant VIEW_ROLE = keccak256("VIEW_ROLE");

    uint256 public myVariable;

    // Определяем имя домена и версию для EIP-712
    string public constant EIP712_DOMAIN = "MyTokenMetaTx"; //имя домена
    string public constant VERSION = "1"; //версия протокола
    bytes32 public DOMAIN_SEPARATOR;

    // Структура для метатранзакции setVariable
    struct MetaTransactionSetVariable {
        uint256 newValue;
        uint256 nonce;
        address target;
        uint256 deadline;
    }

    // Хеш типа MetaTransactionSetVariable
    bytes32 public constant SET_VARIABLE_TYPEHASH = keccak256(
        "SetVariable(uint256 newValue,uint256 nonce,address target,uint256 deadline)"
    );

    // Отображение для отслеживания nonce каждого пользователя, 
    //чтобы предотвратить повторное воспроизведение транзакций
    mapping(address => uint256) public nonces;

    // Конструктор который инициализирует DOMAIN_SEPARATOR
    constructor(uint256 initialValue, address modifier, address viewer) ERC20("MyToken", "MTK") {
        myVariable = initialValue;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MODIFIER_ROLE, modifier);
        _setupRole(VIEW_ROLE, viewer);

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(EIP712_DOMAIN)),
                keccak256(bytes(VERSION)),
                block.chainid,
                address(this)
            )
        );
    }

    function viewVariable() public view returns (uint256) {
        require(hasRole(VIEW_ROLE, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not a viewer or admin");
        return myVariable;
    }

      //Основная функция setVariable, которая может быть вызвана напрямую или через метатранзакцию.
    function setVariable(uint256 newValue) public {
        require(hasRole(MODIFIER_ROLE, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not a modifier or admin");
        _setVariable(newValue, msg.sender);
    }

    function ModifierFunction() public {
        require(hasRole(MODIFIER_ROLE, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not a modifier or admin");
        myVariable ++;
    }


    function grantModifierRole(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(MODIFIER_ROLE, account);
    }

    function revokeModifierRole(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(MODIFIER_ROLE, account);
    }

    function grantViewerRole(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(VIEW_ROLE, account);
    }

    function revokeViewerRole(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(VIEW_ROLE, account);
    }

   //Функция для выполнения метатранзакции setVariable  
   //Принимает структуру MetaTransactionSetVariable и подпись

    function executeSetVariable(
        MetaTransactionSetVariable calldata req,
        bytes calldata signature
    ) external {
        require(block.timestamp <= req.deadline, "Deadline expired"); // проверка валидности
        require(req.target == address(this), "invalid target"); //проверка адреса контракта
        bytes32 hash = hashSetVariable(req); //создаем хеш сообщения

        //проверить подпись
        address signer = hash.recover(signature);

        require(signer != address(0) && signer == msg.sender, "Invalid signature"); //подпись должна быть валидной

        require(req.nonce == nonces[msg.sender], "Invalid nonce"); //проверяем nonce
        nonces[msg.sender]++;

        _setVariable(req.newValue, msg.sender);
    }

    //Внутренняя функция для фактического изменения переменной, вызывается из обычной setVariable и executeSetVariable.
    function _setVariable(uint256 newValue, address sender) internal {
        myVariable = newValue;
    }

    //Эта функция возвращает хеш сообщения, которое нужно подписать.
    function hashSetVariable(MetaTransactionSetVariable memory req)
        internal
        view
        returns (bytes32)
    {
        return _hashTyped(
            keccak256(
                abi.encode(
                    SET_VARIABLE_TYPEHASH,
                    req.newValue,
                    req.nonce,
                    req.target,
                    req.deadline
                )
            )
        );
    }

    //Внутренняя функция для расчета хеша EIP712.
    function _hashTyped(bytes32 dataHash) internal view returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, dataHash));
    }
}
