// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

// Contrato de 'Transaccion' inteligente, cuyo fin es controlar la transferencia de los fondos
// dandole todo el poder de desicion al remitente de la transaccion, lo que le permite confirmar,
// rechazar o expirar la transaccion
contract SmartTransaction {
    address payable public sender; // Direccion del remitente
    address payable public receiver; // Direccion del destinatario
    uint public transactionValue; // Variable para alojar el valor de la transaccion
    PossibleStatus public status; // Estado de la transaccion
    enum PossibleStatus{Pending, Confirmed, Rejected, Expired} // Posibles estados de la transaccion
    bool public balanceReceived = false; // Fondos recibidos desde el remitente
    uint public expirationTime; // Tiempo de expiracion en segundos

    /**
    Constructor del contrato
    _sender: direccion del remitente
    _receiver: direccion del destinatario
    _expectedValue: valor espereado que debe recibir la transaccion
    _timeToExpire: tiempo en segundos para que expire la transaccion
     */
    constructor(address _sender, address _receiver,uint _expectedValue, uint _timeToExpire){
        sender = payable(_sender);
        receiver = payable(_receiver);
        transactionValue = _expectedValue;
        expirationTime = block.timestamp + _timeToExpire;
        status = PossibleStatus.Pending;
    }

    // Modificador para que restringe acceso solo al remitente
    modifier onlySender(){
        require(msg.sender == sender, "Solo el remitente de la transaccion puede ejecutar esta funcion");
        _;
    }

    // Modificador que verifica que la transaccion haya expirado, si expira cambia el estado de la transaccion
    // a expirado y reembolsa los fondos al remitente
    modifier checkExpiration(){
        if(block.timestamp > expirationTime){
            status = PossibleStatus.Expired;
            sender.transfer(transactionValue);  
        }
        _;
    }

    // Modificador que verifica que la transaccion no haya sido resuelta
    modifier needsResolve(){
        require(status == PossibleStatus.Pending, "La transaccion ya fue definida");
        _;
    }


    /**
    Funcion para confirmar la transaccion, cambia el estado de la transaccion a 'Confirmada'
    y transfiere los fondos al destinatario
     */
    function confirm() onlySender checkExpiration needsResolve public{
        status = PossibleStatus.Confirmed;
        receiver.transfer(transactionValue);
    }

    /**
    Funcion para rechazar la transaccion, cambia el estado de la transaccion a 'Rechazado'
    y reembolsa los fondos al remitente
     */
    function reject() onlySender checkExpiration needsResolve public{
        status = PossibleStatus.Rejected;
        sender.transfer(transactionValue);
    } 

    /**
    Funcion para recibir los fondos desde el remitente
     */
    function receiveValue() onlySender checkExpiration needsResolve payable public {
        require(balanceReceived == false, "Ya se recibio el dinero previamente");
        require(msg.value == transactionValue , "No es el valor esperado");
        balanceReceived = true;             
    }
}

// Tipo Producto
struct Product {
    string name;
    uint price; // Precio en Wei
    bool exists; // Variable de control para verificación de existencia
}

contract SimpleStore {
    
    mapping(string => Product) private products; // Mapa de productos
    SmartTransaction[] private transactions; // La información de las compras de los clientes es confidencial
    address internal owner; // Variable para guardar la dirección del owner del contrato

    // Modificador para verificar el dueño de la tienda 
    modifier onlyOwner{
        require(msg.sender == owner, "Solo el owner de la tienda puede utilizar esta funcion");
        _;
    }

    // Constructor
    constructor(){
        owner = msg.sender; 
    }



    /**
    * Función para realizar la compra de un producto, puede ser llamada por cualquiera, requiere que el
    * el cliente esté registrado y no tenga deudas, se debe enviar el dinero en la llamada
    * _producto Nombre del producto a comprar
    **/
    function buy(string memory _product) public payable returns(address) {
        Product memory product = products[_product];
        // Verificar restricciones del producto
        require(product.exists, "El producto no existe");
            
        require(product.price == msg.value, "El valor enviado es diferente al del producto"); 
        
        // Crear la transaccion inteligente y dar la direccion de este contrato al comprador
        SmartTransaction transaction = new SmartTransaction(msg.sender, owner, product.price,86400);

        transactions.push(transaction);

        return address(transaction);
    }


    /**
    * Función para obtener las ganancias totales de la tienda
    **/
    function getEarnings() public view returns (uint) {
        uint earnings = 0;
        
        // Iterar sobre todas las compras guardadas
        for(uint i = 0; i < transactions.length; i++){
            if (transactions[i].status() == SmartTransaction.PossibleStatus.Confirmed){
                earnings += transactions[i].transactionValue();
            }
        }

        return earnings;
    }

    /**
    * Función para obtener los datos actuales del producto, solo puede ser llamada por el dueño del contrato
    * _nombre: Nombre del producto
    **/
    function getProduct(string memory _name) external view onlyOwner returns (Product memory){
        Product memory product = products[_name];
        return product;
    }

    /**
    * Función para crear un nuevo producto, solo puede ser llamada por el owner del Contrato
    * _nombre
    * _precio
    * _cantidad
    * _promocion
    **/
    function createProduct(string memory _name, uint _price) external onlyOwner returns(bool){
        Product memory existenProduct = products[_name];
        require(!(existenProduct.exists), "Ya existe un producto con este nombre");
        // Crear el producto
        Product memory product = Product({
            name:_name,
            price:_price,
            exists: true
        });

        // Agregarlo al mapa de productos
        products[_name] = product;
        return true; // Operación exitosa

    }

    /**
    * Función para destruir el contrato y enviar los fondos al owner, solo puede ser llamada por el owner
    * debe ser llamada al menos 'maxIntentos' veces para que tenga efecto
    **/
    function destroy() external onlyOwner returns (string memory){
        selfdestruct(payable(owner)); // Destruir y enviar fondos al owner
        return "Contrato destruido";
    }
}