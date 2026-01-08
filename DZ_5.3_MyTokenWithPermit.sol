// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


 // ERC20 токен с поддержкой функции permit (ERC2612).  
 //Позволяет владельцам утверждать траты токенов без прямой транзакции (метатранзакции).

contract MyTokenWithPermit is ERC20, Ownable {
    using ECDSA for bytes32;
    using Counters for Counters.Counter;

    // Константы и переменные для EIP-712 
    string public constant name = "MyTokenWithPermit";           // Имя токена для EIP-712
    string public constant version = "1";                        // Версия протокола
    bytes32 public immutable DOMAIN_SEPARATOR;                   // Уникальный идентификатор домена
    bytes32 public constant PERMIT_TYPE_HASH = keccak256(        // Хеш типа для структуры Permit
        "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
    );

    // Управление nonce .Nonce для каждого владельца чтобы не безобразничал и не повторял транзакцию
    mapping(address => Counters.Counter) private _nonces;      

   // Конструктор.  Инициализирует DOMAIN_SEPARATOR.
   //Переменная _initialSupply определяет общее количество токенов для выпуска.
  
    constructor(uint256 _initialSupply) ERC20(name, "MTP") {
        _mint(msg.sender, _initialSupply);                       // Выпускаем токены создателю контракта
        DOMAIN_SEPARATOR = _calculateDomainSeparator();           // Вычисляем DOMAIN_SEPARATOR
    }

   //Функция permit, реализующая стандарт ERC2612. 
   //Позволяет владельцу токенов подписать сообщение, разрешающее другому адресу (spender) тратить
   //определенное количество токенов от его имени до указанного срока.
   //Подпись может быть передана on-chain любым пользователем,
   //чтобы фактически утвердить трату.
    
    function permit(
        address owner, // Адрес владельца токенов, дающего разрешение
        address spender,//Адрес, которому предоставляется разрешение тратить токены
        uint256 value,//Количество токенов, разрешенных к трате
        uint256 deadline,//Время, до которого действует разрешение 
        //Части ECDSA-подписи
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(deadline >= block.timestamp, "Deadline expired");   // Проверяем, не истек ли срок действия

        // Получаем текущий nonce владельца
        uint256 currentNonce = _nonces[owner].current();

        // Вычисляем хеш структуры Permit для проверки подписи
        bytes32 digest = _hashPermit(
            owner,
            spender,
            value,
            currentNonce,
            deadline
        );

        // Восстанавливаем адрес подписавшего сообщение
        address recoveredAddress = digest.recover(v, r, s);

        require(recoveredAddress == owner, "Invalid signature");   // Подпись должна принадлежать владельцу

        // Увеличиваем nonce (чтобы предотвратить повторное использование подписи)
        _nonces[owner].increment();

        // Утверждаем трату токенов 
        _approve(owner, spender, value);
    }
   
    //Вспомогательная функция для расчета хеша структуры Permit

    function _hashPermit(
        address owner,//Адрес владельца токенов
        address spender,//Адрес, которому разрешено тратить токены
        uint256 value,//Количество токенов, разрешенных к трате
        uint256 nonce,//Nonce владельца
        uint256 deadline//Время, до которого действует разрешение

    ) private view returns (bytes32) {//Хеш структуры Permit
        return keccak256(
            abi.encode(
                PERMIT_TYPE_HASH,
                owner,
                spender,
                value,
                nonce,
                deadline
            )
        );
    }


   //Вспомогательная функция для расчета DOMAIN_SEPARATOR (для EIP-712).
    
    function _calculateDomainSeparator() private view returns (bytes32) {
        return keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                block.chainid,
                address(this)
            )
        );
    }

 
     // Возвращение текущий nonce для заданного адреса.
     
    function nonces(address owner) public view returns (uint256) {
        return _nonces[owner].current();
    }

  
    // Переопределяем _approve, чтобы не выбрасывать событие Approval при вызове из permit. 
   
    function _approve(address owner, address spender, uint256 amount) internal virtual override {
        super._approve(owner, spender, amount);
    }

   
    // Функция для минта токенов(чеканки), доступна только владельцу контракта.
    
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    //Функция для уничтоженисожжения токенов, доступна только владельцу контракта.
   
    function burn(address from, uint256 amount) public onlyOwner {
        _burn(from, amount);
    }
}
