Para utilizar o SyncState, você primeiro precisará configurar os recursos e direitos do iCloud em seu projeto do Xcode. Aqui está uma introdução para guiá-lo através do processo:

### Configurando os recursos do iCloud:

1. Abra seu projeto do Xcode e ajuste os identificadores de pacote para os destinos macOS e iOS para corresponderem aos seus.
2. Em seguida, você precisa adicionar o recurso iCloud ao seu projeto. Para fazer isso, selecione seu projeto no Navegador de projetos e, em seguida, selecione seu destino. Na barra de guias na parte superior da área do editor, clique em "Signing & Capabilities".
3. No painel Recursos, ative o iCloud clicando no botão na linha do iCloud. Você deve ver o botão mudar para a posição Ligado.
4. Depois de habilitar o iCloud, você precisa habilitar o armazenamento de valor-chave. Você pode fazer isso marcando a caixa de seleção "Armazenamento de valor-chave".

### Atualizando os direitos:

1. Agora você precisará atualizar seu arquivo de direitos. Abra o arquivo de direitos para o seu destino.
2. Certifique-se de que o valor do Repositório de Valor-Chave do iCloud corresponda ao seu ID de repositório de valor-chave exclusivo. Seu ID exclusivo deve seguir o formato `$(TeamIdentifierPrefix)<your key-value store ID>`. O valor padrão deve ser algo como, `$(TeamIdentifierPrefix)$(CFBundleIdentifier)`. Isso é bom para aplicativos de plataforma única, mas se seu aplicativo estiver em vários sistemas operacionais da Apple, é importante que as partes do ID do repositório de valor-chave sejam as mesmas para ambos os destinos.

### Configurando os dispositivos:

Além de configurar o projeto em si, você também precisa preparar os dispositivos que executarão o projeto.

- Certifique-se de que o iCloud Drive esteja habilitado nos dispositivos iOS e macOS.
- Faça login em ambos os dispositivos usando a mesma conta do iCloud.

Se você tiver alguma dúvida ou encontrar algum problema, sinta-se à vontade para entrar em contato ou enviar um problema.

---
Esta tradução foi gerada automaticamente e pode conter erros. Se você é um falante nativo, agradecemos suas contribuições com correções por meio de um Pull Request.
