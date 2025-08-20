Para utilizar SyncState, primero deberá configurar las capacidades y los derechos de iCloud en su proyecto de Xcode. Aquí hay una introducción para guiarlo a través del proceso:

### Configuración de las capacidades de iCloud:

1. Abra su proyecto de Xcode y ajuste los identificadores de paquete para los destinos de macOS e iOS para que coincidan con los suyos.
2. A continuación, debe agregar la capacidad de iCloud a su proyecto. Para hacer esto, seleccione su proyecto en el Navegador de proyectos, luego seleccione su destino. En la barra de pestañas en la parte superior del área del editor, haga clic en "Capabilities".
3. En el panel Capacidades, active iCloud haciendo clic en el interruptor de la fila de iCloud. Debería ver que el interruptor se mueve a la posición de encendido.
4. Una vez que haya habilitado iCloud, debe habilitar el almacenamiento de clave-valor. Puede hacerlo marcando la casilla de verificación "Key-Value storage".

### Actualización de los derechos:

1. Ahora deberá actualizar su archivo de derechos. Abra el archivo de derechos para su destino.
2. Asegúrese de que el valor del Almacén de clave-valor de iCloud coincida con su ID de almacén de clave-valor único. Su ID único debe seguir el formato `$(TeamIdentifierPrefix)<su_ID_de_almacén_de_clave-valor>`. El valor predeterminado debería ser algo así como `$(TeamIdentifierPrefix)$(CFBundleIdentifier)`. Esto está bien para aplicaciones de una sola plataforma, pero if su aplicación está en varios sistemas operativos de Apple, es importante que las partes de la ID del almacén de clave-valor sean las mismas para ambos destinos.

### Configuración de los dispositivos:

Además de configurar el proyecto en sí, también debe preparar los dispositivos que ejecutarán el proyecto.

- Asegúrese de que iCloud Drive esté habilitado en los dispositivos iOS y macOS.
- Inicie sesión en ambos dispositivos con la misma cuenta de iCloud.

Si tiene alguna pregunta o tiene algún problema, no dude en comunicarse o enviar un problema.
