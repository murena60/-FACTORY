// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TransparentProxy {
    address public implementation;
    address public admin; // Добавлен адрес администратора

    constructor(address _implementation, address _admin) {
        implementation = _implementation;
        admin = _admin;
    }

    // Модификатор для ограничения доступа только для администратора
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }


    // Функция для обновления адреса реализации
    function upgradeTo(address _newImplementation) external onlyAdmin {
        require(_newImplementation != address(0), "Invalid implementation address");
        implementation = _newImplementation;
    }

   //Функция резервного копирования,возвращает любое значение, которое возвращает вызов реализации
    fallback() external payable {
        _delegate(implementation);
    }

  
    receive() external payable {
        _delegate(implementation);
    }


    function _delegate(address _implementation) internal virtual {
        assembly {
            // Получаем полный контроль над памятью в этом блоке

            //Загрузка и освобождение памяти
            let ptr := mload(0x40)
           
            //Копируем сигнатуру функции и аргументы из данных вызова в нулевой позиции
            calldatacopy(ptr, 0x0, calldatasize())

            // Возвращаемое значение — количество байтов, возвращенных вызовом делегата
            let result := delegatecall(
              gas(), // Используем весь доступный газ
              _implementation, // адрес реализации
              ptr, // Ввод данных осуществлялся путем копирования информации в память
              calldatasize(), // Размер данных, скопированных в память
              0x0,
              0 // Возвращает смещение и длину данных
            )

            // Получаем размер возвращаемых данных
            let size := returndatasize()

            // Копируем полученные данные
            returndatacopy(ptr, 0x0, size)

            switch result
              case 0 {
                // Отмена транзакцию, если вызов делегата завершился неудачей
                revert(ptr, size)
              }
              default {
                // Возвращает данные из вызова делегата
                return(ptr, size)
              }
        }
    }
}
