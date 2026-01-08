// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//установили библиотеку OpenZeppelin
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract MyToken is ERC20, AccessControl {

   //Пользователи с ролью MODIFIER_ROLE  могут изменять значение переменной myVariable.
    bytes32 public constant MODIFIER_ROLE = keccak256("MODIFIER_ROLE");

    //Пользователи с ролью VIEW_ROLE  могут просматривать значение переменной myVariable.
    bytes32 public constant VIEW_ROLE = keccak256("VIEW_ROLE");

    uint256 public myVariable;//Задаем переменную myVariable

    constructor(uint256 initialValue, address modifier, address viewer) ERC20("MyToken", "MTK") {
        myVariable = initialValue;

        // Назначается администратор DEFAULT_ADMIN_ROLE, который может назначать/отзывать другие роли.
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender); 
        _setupRole(MODIFIER_ROLE, modifier);
        _setupRole(VIEW_ROLE, viewer);
    }

  //Функция, доступная только для ролей VIEW(для тех кто смотрит), которая показывает значение myVariable.
    function viewVariable() public view returns (uint256){
        require(hasRole(VIEW_ROLE, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not a viewer or admin/Вы не зритель и не админ");
        return myVariable;
    }
    //Функция, доступная только для ролей MODIFIER(те кто меняет значение), устанавливает новое значение myVariable.
    function setVariable(uint256 newValue) public {
        require(hasRole(MODIFIER_ROLE, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not a modifier or admin/");
        myVariable = newValue;
    }
    //Функция, доступная только для ролей MODIFIER, увеличивает значение myVariable на 1.
    function ModifierFunction() public {
        require(hasRole(MODIFIER_ROLE, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not a modifier or admin");
        myVariable ++;
    }

    //Функции для выдачи и отзыва ролей.  Только администратор может это делать onlyRole(DEFAULT_ADMIN_ROLE).


    // grantModifierRole предоставляет  роль MODIFIER_ROLE через админа
    function grantModifierRole(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(MODIFIER_ROLE, account);
    }
    // revokeModifierRole отзывает  роль MODIFIER_ROLE через админа
    function revokeModifierRole(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(MODIFIER_ROLE, account);
    }
     // grantViewerRole предоставляет  роль VIEW_ROLE через админа
    function grantViewerRole(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(VIEW_ROLE, account);
    }
    // revokeViewerRole  отзывает роль VIEW_ROLE через админа
    function revokeViewerRole(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(VIEW_ROLE, account);
    }
}
