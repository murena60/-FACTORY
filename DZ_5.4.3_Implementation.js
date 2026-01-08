// scripts/deploy.js
const { ethers } = require("hardhat");

//Скрипт развертывания Развертывает контракт ValueHolder


async function main() {

  //Создаем экземпляр контракта ValueHolder по адресу TransparentProxy, 
  // чтобы можно было вызывать функции ValueHolder через прокси


  const ValueHolder = await ethers.getContractFactory("ValueHolder");
  const valueHolder = await ValueHolder.deploy();
  await valueHolder.deployed();

  console.log("ValueHolder Implementation deployed to:", valueHolder.address);

  // Развертывание прокси-контракт
  const TransparentProxy = await ethers.getContractFactory("TransparentProxy");

  // Замена на  адрес администратора
  const [deployer] = await ethers.getSigners();
  const adminAddress = deployer.address;
  const transparentProxy = await TransparentProxy.deploy(valueHolder.address, adminAddress);
  await transparentProxy.deployed();

  console.log("TransparentProxy deployed to:", transparentProxy.address);

  // Проверяем работу функций
  const proxyContract = await ethers.getContractAt("ValueHolder", transparentProxy.address);

  // Отправляем транзакцию через прокси-сервер
  // проверяем, что значение было успешно установлено
  const tx = await proxyContract.setValue(123);
  await tx.wait();

  const retrievedValue = await proxyContract.getValue();
  console.log("Retrieved value: ", retrievedValue.toString());

    // Проверяем реализацию и обновление
  const proxy = await ethers.getContractAt("TransparentProxy",transparentProxy.address)
   console.log("Implementation before upgrade ", await proxy.implementation());
     const ValueHolderV2 = await ethers.getContractFactory("ValueHolder");
     const valueHolderV2 = await ValueHolderV2.deploy();
     await valueHolderV2.deployed()
       console.log("ValueHolder Implementation V2 deployed to:", valueHolderV2.address);
     await proxy.upgradeTo(valueHolderV2.address)

   console.log("Implementation after upgrade ", await proxy.implementation());

     const proxyContractV2 = await ethers.getContractAt("ValueHolder", transparentProxy.address);
            const version = await proxyContractV2.version()
           console.log("Version  ", version);


}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
