
# Guía para aprendizaje de desarrollo de Contratos Inteligentes en Solidity

## ¿Qué es un contrato inteligente?
Un contrato inteligente es simplemente un **programa** o **procedimiento**, que se ejecuta en la máquina virtual de una red de *blockchain*, para Ethereum, por ejemplo, un contrato inteligente se ejecuta en la [EVM](https://ethereum.org/en/developers/docs/evm/) (Ethereum Virtual Machine). La distinción de un contrato inteligente de un programa convencional viene desde su ejecución de una red de blockchain, esto brinda al programa las cualidades deseables por lo que las redes de blockchain son atractivas; autonomía, inmutabilidad y descentralización.

## ¿Qué es Solidity?
Solidity es un lenguaje de programación, cuyo objetivo es facilitar el desarrollo de contratos inteligentes para ser desplegados en la EVM, Solidity está inspirado en otros lenguajes de alto nivel como C++, Python y JavaScript. El código hecho en Solidity es compilado a código entendible por la EVM. Finalmente, Solidity no es el único lenguaje para desarrollar contratos inteligentes para la EVM, ciertamente existen otros lenguajes como [Vyper](https://vyper.readthedocs.io/en/stable/) y [Yul](https://docs.soliditylang.org/en/latest/yul.html).

## Ethereum Virtual Machine (EVM)
En términos simples, la EVM es una máquina de estados, no es una nube, sino más bien una sola entidad, que es mantenida por miles de computadoras conectadas corriendo un cliente de Ethereum, es decir, la ejecución de las instrucciones en la EVM se reparte entre todos los nodos, o como se conoce comúnmente, *mineros*. 

## Acerca del Gas
El gas es la unidad que mide la cantidad de esfuerzo computacional de realizar una operación en específico en la EVM, esto significa que cada operación realizada en la EVM tiene un **costo** de gas asociado.

El gas en sí no es más que una tarifa que se cobra por ejecutar una operación en la red de Ethereum, tal vez es más sencillo entenderlo realizando una analogía sobre lo que significa la Gasolina para un automóvil, la EVM necesita gas para ejecutar las operaciones así como un automóvil necesita gasolina para andar. Naturalmente, la tarifa de gas es pagada en la moneda nativa de Ethereum, es decir, en ether.

Uno podría preguntarse, ¿por qué existe el gas?, debemos recordar que la fuerza computacional de Ethereum se distribuye en una red de nodos con un cliente de Ethereum, al asociar un costo de ejecución a las operaciones, se garantiza el bienestar de esta red, impidiendo que actores maliciosos sobresaturen la red (ya que deberían pagar un alto costo en ether al hacerlo), también previene que accidentalmente se ejecuten ciclos infinitos u operaciones inesperadamente costosas computacionalmente.

Antes de ejecutar una transacción en la EVM, se debe especificar un **límite máximo de gas** que esta puede gastar y el **precio por unidad de gas a pagar**, lo que finalmente se paga como un costo total de ejecución.

Finalmente la duda más común a la hora de ejecutar una transacción en la EVM es establecer estos dos parámetros, surgen preguntas como:

> ¿Cómo puedo saber cuánto gas consumirá mi transacción?

Existe una gran diversidad de herramientas de desarrollo (algunas veremos en esta guía), para estimar el costo de Gas de código hecho en Solidity, aún así es recomendable siempre especificar un costo más alto de gas del esperado, ya que el precio pagado por gas excedente es reembolsado.

> ¿Cómo puedo saber cuál es el precio por unidad de gas que debo usar?

Para tener una buena idea acerca del precio del gas, se debe tener en cuenta que este también determina que tan rápido se ejecutará la transacción, la ejecución de transacciones en la EVM prioriza aquellas que son mejor pagadas, en consecuencia, las tarifas de gas son reguladas según la demanda de ejecución, sin embargo existen varias [páginas web](https://etherscan.io/gastracker) que otorgan un aproximado respecto al tiempo de espera para la ejecución que se quiere.
> ¿Qué pasa si mi transacción consume más o menos gas del especificado?

En el caso en que se consuma menos gas, el valor pagado del gas excedente será reembolsado.

En el caso en que se consuma más gas, la transacción será rechazada y todos lo cambios hechos por la misma serán revertidos (ya que no hubo gas suficiente para ejecutar la transacción), ningún costo en gas es reembolsado ya que efectivamente se consumió todo el gas, pero no fue suficiente para terminar la ejecución de la transacción.


## Estructura Básica de un Archivo en Solidity
Un archivo básico de Solidity luce así:

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.4.16 <0.9.0;
    
    contract SimpleStorage {
        uint storedData;
    
        function set(uint x) public {
            storedData = x;
        }
    
        function get() public view returns (uint) {
            return storedData;
        }
    }
> Tomado de https://docs.soliditylang.org/en/v0.8.2/introduction-to-smart-contracts.html#simple-smart-contract

La primera línea se refiere al la licencia del código, en este caso es GPL versión 3.0, esta especificación de la licencia es obligatoria y debe existir para poder compilar el contrato.

La siguiente línea especifica que el código fue escrito para Solidity bajo las versiones de compilador desde la 0.4.16 hasta la 0.9.0 (exclusivo).

Finalmente está la declaración del contrato, a modo simple un contrato consiste en una colección de funciones y una definición de estado, que es alterado o visualizado por estas mismas funciones. En el ejemplo en cuestión está la variable de estado `storeData`, la cual puede ser modificada y leída mediante las funciones `set` y `get` respectivamente.

## Tipos de Memoria

En la EVM existen tres áreas en las que se pueden guardar las variables, conocidas como *storage*, *memory* y *stack*.

### Storage
Esta memoria es persistente entre llamadas de funciones y transacciones, en comparación con *Memory* tiene un gran costo en gas al leer, inicializar y modificar una variable alojada en ella, usualmente se recomienda minimizar el uso de *Storage* a lo que sea estrictamente necesario.

Las variables de estado y variables locales de estructuras de datos o arreglos siempre son guardados en *Storage* por defecto. Se debe tener en cuenta que los tipos *string* y *bytes* son arreglos.

### Memory
Es una memoria linear que no es persistente entre llamadas, su costo en gas incrementa mientras más se usa de ella.

Los argumentos de una función, así como las variables locales de tipos nativos siempre se guardan en *Memory* por defecto.

### Stack
La EVM no es una máquina de registros sino un máquina de pila, es decir que los cómputos se almacenan y se ejecutan en una estructura de pila, es posible acceder a la pila desde Solidity e incluso modificarla (con sus limitaciones), esto sale del enfoque de esta guía ya que es muy poco común acceder a la pila.

Adicionalmente se debe tener en cuenta que al asignar una variable como una estructura o un arreglo declarada como memory una instancia de una variable storage, esta realiza una copia de la variable en vez de sostener un puntero a la instancia de storage. Los siguientes diagramas muestran esto de mejor manera.

![](https://media.geeksforgeeks.org/wp-content/uploads/20200805174204/Screenshot20200805at54037PM.png)

![](https://media.geeksforgeeks.org/wp-content/uploads/20200805174213/Screenshot20200805at54148PM.png)

Tomado de [GeeksForGeeks](https://www.geeksforgeeks.org/storage-vs-memory-in-solidity/)

Un ejemplo para demostrar esta temática de memoria puede ser encontrado en el [repositorio de ejemplos](https://github.com/saarboledaz/guia_solidity/blob/main/Ejemplos/memory.sol).

## Tipos de Variable

A continuación se exponen en el siguiente [ejemplo](https://github.com/saarboledaz/guia_solidity/blob/main/Ejemplos/variables.sol) los tipos de variables más comunes en Solidity.

## Variables y Funciones Globales de Interés
Solidity cuenta con una gran variedad de funciones y variables nativas para brindar diferentes utilidades frente al desarrollo de contratos inteligentes en Solidity, entre varios usos, generalmente nos permiten codificar y decodificar, encriptar y desencriptar, obtener datos de las transacciones o llamadas y obtener información sobre el bloque de ejecución de la instrucción.

A continuación se muestra un contrato de [ejemplo](https://github.com/saarboledaz/guia_solidity/blob/main/Ejemplos/globalVariables.sol) que usa varias funciones y variables globales de interés

## Visibilidad de variables y funciones
Solidity, como la gran mayoría de lenguajes con un alto enfoque orientado a objetos, brinda la posibilidad de establecer la visibilidad de las variables y las funciones, existen 4 tipos de visibilidad.

### Pública (*public*)
Es la visibilidad por defecto que adquieren las variables de estado, para las variables de estado automáticamente genera las funciones *get* y *set* para obtener y modificar su valor. Una variable o función pública puede ser llamada desde:

 - El mismo contrato que contiene la variable.
 - Otros contratos que hereden de este contrato.
 - Otros contratos y cuentas que interactúen con este contrato.

### Privada (*private*)
Esta visibilidad restringe las funciones y variables a ser utilizadas solo desde el mismo contrato que las contengan, se debe aclarar que los contratos que hereden de otro no podrán tener acceso a sus funciones y variables privadas.

### Interna (*internal*)
Esta visibilidad puede verse como una extensión de la visibilidad privada, ya que esta restringe 
las funciones y variables a ser usadas por su mismo contrato y contratos que hereden del mismo.

### Externa (*external*)
La visibilidad externa restringe el uso de las funciones a contratos y cuentas externas al contrato que las contenga, en consecuencia no es posible declarar variables de estado que sean externas ya que no tendrían ningún tipo de uso para el contrato en sí.

Los diferentes tipos de visibilidad pueden contemplarse mejor en el siguiente [ejemplo](https://github.com/saarboledaz/guia_solidity/blob/main/Ejemplos/visibility.sol).

## Modificadores

Los modificadores son condiciones que se pueden agregar a las funciones para restringir su uso y comportamiento, existen dos tipos de modificadores, los nativos y los declarados.

Los modificadores se especifican en la declaración de la función y pueden obtener los mismos argumentos que la función, por ejemplo

    function foo(uint arg1) public  
    <modifier1>  
    <modifier2(arg1)>  ...  
    returns (bool) {
	    ...
	}

Algunos modificadores nativos son:

 - `pure`:restringe la modificación y el acceso al estado del contrato
 - `view`:restringe la modificación del estado.
 - `payable`: permite que la función reciba Ether al ser llamada.
Existen otros modificadores que tienen que ver con herencia, pero se verán en la próxima sección.

Los modificadores declarados permiten aplicar restricciones o disparar comportamientos personalizados, y su sintaxis es la siguiente:

    // Controla que solo se permita ejecución desde el Creador
    modifier soloCreador{ // Declaración
	    // Restricciones y comportamientos
    	require(msg.sender == creador,  "Solo para el creador"); 
    	_; // Finalización del modificador, indice que desde acá procede el código
	    	// del resto de los modificadores y la funcion.
    }

Un buen ejemplo de aplicación es la implementación de una Tienda simple, que puede ser visualizada [aquí](https://github.com/saarboledaz/guia_solidity/blob/main/Ejemplos/tienda.sol).

## Herencia
Solidity tiene soporte para herencia múltiple y polimorfismo, este tema es bastante extenso y no se explicará a fondo en la guía, sin embargo se proveerá un ejemplo del uso básico de esta que se puede encontrar en el [repositorio](https://github.com/saarboledaz/guia_solidity/blob/main/Ejemplos/auction_inheritance.sol).

## Interacción entre contratos

Solidity permite establecer una interfaz para interactuar e incluso desplegar otros contratos a la red de Ethereum desde el código, para esto es importante recordar que un contrato desplegado en la red es similar a una cuenta, tiene una dirección asociada, es posible enviarles ETH y tienen un balance.

Los contratos son **instanciables** desde el código, esto propone dos comportamientos, instanciar un nuevo contrato con la palabra clave `new`, u obtener una instancia ya desplegada de dicho contrato utilizando la dirección de este, en este caso el código del contrato actúa como una interfaz para interactuar con el contrato ya desplegado.

Por ejemplo, si tengo el código de un contrato `Tienda`:

    Tienda miTienda = new Tienda(); // Desplegar un nuevo contrato
    address(miTienda) // Obtener la dirección del contrato desplegado

o si el contrato ya está desplegado

    // Direccion de ejemplo (NO USAR)
    address direccion = 0X001D3F1EF827552AE1114027BD3ECF1F086BA0F9
    Tienda miTienda = Tienda(direccion); // Obtener la instancia ya desplegada

Un ejemplo de interacción de contratos puede ser encontrado en el [repositorio](https://github.com/saarboledaz/guia_solidity/blob/main/Ejemplos/instantiation.sol).

## Entornos de Desarrollo

En esta sección se explicará como es el proceso de desarrollo y compilación de un contrato de Solidity en diferentes entornos de desarrollo.

### Remix

Remix es un IDE en línea en el que se pueden desarrollar, compilar y finalmente desplegar contratos en Solidity (y otros lenguajes compilados para la EVM). Remix cuenta con una variedad de funcionalidades entre las que permite de manera sencilla elegir la versión de Solidity en la que se va a compilar un contrato, e instalar una gran variedad de plugins de gran ayuda para el desarrollo.

Se recomienda el uso de Remix para el aprendizaje de Solidity y el desarrollo de contratos cortos y sencillos.

#### Ingreso
Dirigirse a la página web de Remix: https://remix.ethereum.org/
#### Creación de un contrato
Para crear un contrato o un archivo .sol, se debe seleccionar el explorador de archivos, allí encontraremos una estructura de carpetas que son un ejemplo de un proyecto en Solidity, en este explorador de archivos podemos crear y subir archivos como lo haríamos con cualquier explorador de archivos. Crearemos un archivo llamado **prueba.sol**.   

![Explorador de archivos](https://raw.githubusercontent.com/saarboledaz/guia_solidity/main/Recursos/remix_fileexp.png)
#### Compilación
Una vez tengamos nuestro contrato de Solidity creado, debemos desplazarnos para la pestaña ‘Solidity Compiler’ en la parte izquierda de la pantalla, hecho esto se desplegaran varias opciones para poder compilar el archivo creado. Debemos seleccionar la versión adecuada de Solidity que queremos compilar según el _**pragma**_ que indique el archivo , finalmente oprimimos el botón de Compilación (o usamos el atajo Ctrl + S), en caso de estar correcto el contrato y no tener errores de sintaxis se compilará , de lo contrario se mostrarán en el editor de texto las líneas que presentan los errores que impiden que se compile el contrato.
![Compilación](https://raw.githubusercontent.com/saarboledaz/guia_solidity/main/Recursos/remix_compiler.png)  
#### Despliegue
Para finalizar, después de haber compilado exitosamente nuestro archivo, podemos desplegar el mismo a diferentes entornos de Ethereum en línea o a la máquina virtual de JavaScript que genera Remix en el navegador, para esto debemos dirigirnos a la pestaña de despliegue y ejecución de transacciones. Esta pestaña presenta varios parámetros de interés:
    

 - Entorno: generalmente para usos de pruebas internas y aprendizaje se debe usar la opción ‘JavaScript VM’, para más información por favor leer la guía de **entornos de despliegue** e interacción de contratos.
 - Cuenta: es la cuenta con la que se va a ejecutar la transacción en cuestión, en este caso el despliegue.        
 - Límite de gas: es el límite de gas máximo que puede consumir la transacción en cuestión        
 - Valor de ETH: el valor en ethereum que se va a enviar con la transacción, el caso de un despliegue debe ser 0.
 - Contrato: el contrato a desplegar, en nuestro caso es **prueba.sol**

![Despliegue](https://raw.githubusercontent.com/saarboledaz/guia_solidity/main/Recursos/remix_deploy.png)  

#### Interacción
Para poder interactuar con el contrato desplegado podemos usar la interfaz dispuesta por Remix, ubicada en la sección de contratos desplegados.
![Interaccion](https://raw.githubusercontent.com/saarboledaz/guia_solidity/main/Recursos/remix_testing.png)
### Visual Studio Code
También es posible desarrollar y compilar contratos de manera local con el uso de Visual Studio Code y el compilador de Solidity. Para esto debemos instalar la extensión con id **juanblanco.solidity** y la instalamos, posteriormente vamos a necesitar recargar el programa.
![Extension](https://github.com/saarboledaz/guia_solidity/blob/main/Recursos/vs_solidity.png?raw=true)  
Una vez instalada la extensión podemos remitirnos a la configuración de la misma, accediendo con el comando ‘Ctrl + ,’ o mediante la siguiente ruta, y luego escribimos en el buscador ‘Solidity’.
![Preferencias](https://github.com/saarboledaz/guia_solidity/blob/main/Recursos/vs_preferences.png?raw=true)  
En esta sección podemos configurar varias varibles de interés, para nuestro caso fijaremos la vista en las opciones de _**Compile Using Local Version**_ y _**Compile Using Remote Version**_**,** estas opciones permiten decidir sobre qué compilador se usará para los archivos de Solidity, en la primera pondríamos la ruta en nuestro equipo en la que se encuentra el programa compilador **solc** (este compilador se puede obtener a través de la página de [Github de Ethereum](https://github.com/ethereum/solc-bin/)) también podemos optar por dejar vacía esta opción, en la segunda pondríamos la versión específica del compilador que se quiere usar, la versión especificada se descargará de las fuentes oficiales, para siempre descargar la última versión estable disponible se debe usar el parámetro ‘latest’.
![Preferencias 2](https://github.com/saarboledaz/guia_solidity/blob/main/Recursos/vs_preferences1.png?raw=true)

Ya con la extensión instalada y correctamente configurada, podemos compilar los archivos de Solidity con el comando F5 para compilar solamente el archivo actualmente abierto en el editor, o Ctrl + F5, lo que generará los archivos de salida para el despliegue en la carpeta **bin**.
![Compilados](https://github.com/saarboledaz/guia_solidity/blob/main/Recursos/vs_compiled.PNG?raw=true)


Estos archivos son suficientes para poder desplegar un contrato en la red de ethereum.

> Escrito con [StackEdit](https://stackedit.io/).

