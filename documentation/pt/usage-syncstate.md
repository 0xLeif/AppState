# Uso do SyncState

`SyncState` é um componente da biblioteca **AppState** que permite sincronizar o estado da aplicação em vários dispositivos usando o iCloud. Isso é especialmente útil para manter as preferências do usuário, configurações ou outros dados importantes consistentes em todos os dispositivos.

## Visão Geral

`SyncState` aproveita o `NSUbiquitousKeyValueStore` do iCloud para manter pequenas quantidades de dados sincronizadas em todos os dispositivos. Isso o torna ideal para sincronizar o estado leve da aplicação, como preferências ou configurações do usuário.

### Principais Características

- **Sincronização com o iCloud**: Sincroniza automaticamente o estado em todos os dispositivos conectados à mesma conta do iCloud.
- **Armazenamento Persistente**: Os dados são armazenados de forma persistente no iCloud, o que significa que eles persistirão mesmo que o aplicativo seja encerrado ou reiniciado.
- **Sincronização Quase em Tempo Real**: As alterações no estado são propagadas para outros dispositivos quase instantaneamente.

> **Nota**: `SyncState` é suportado no watchOS 9.0 e posterior.

## Exemplo de Uso

### Modelo de Dados

Suponha que temos uma estrutura chamada `Settings` que se conforma com `Codable`:

```swift
struct Settings: Codable {
    var text: String
    var isShowingSheet: Bool
    var isDarkMode: Bool
}
```

### Definindo um SyncState

Você pode definir um `SyncState` estendendo o objeto `Application` e declarando as propriedades de estado que devem ser sincronizadas:

```swift
extension Application {
    var settings: SyncState<Settings> {
        syncState(
            initial: Settings(
                text: "Hello, World!",
                isShowingSheet: false,
                isDarkMode: false
            ),
            id: "settings"
        )
    }
}
```

### Lidando com Alterações Externas

Para garantir que o aplicativo responda a alterações externas do iCloud, substitua a função `didChangeExternally` criando uma subclasse personalizada de `Application`:

```swift
class CustomApplication: Application {
    override func didChangeExternally(notification: Notification) {
        super.didChangeExternally(notification: notification)

        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
}
```

### Criando Visualizações para Modificar e Sincronizar o Estado

No exemplo a seguir, temos duas visualizações: `ContentView` e `ContentViewInnerView`. Essas visualizações compartilham e sincronizam o estado de `Settings` entre elas. `ContentView` permite que o usuário modifique o `text` e alterne `isDarkMode`, enquanto `ContentViewInnerView` exibe o mesmo texto e o atualiza quando tocado.

```swift
struct ContentView: View {
    @SyncState(\.settings) private var settings: Settings

    var body: some View {
        VStack {
            TextField("", text: $settings.text)

            Button(settings.isDarkMode ? "Light" : "Dark") {
                settings.isDarkMode.toggle()
            }

            Button("Show") { settings.isShowingSheet = true }
        }
        .preferredColorScheme(settings.isDarkMode ? .dark : .light)
        .sheet(isPresented: $settings.isShowingSheet, content: ContentViewInnerView.init)
    }
}

struct ContentViewInnerView: View {
    @Slice(\.settings, \.text) private var text: String

    var body: some View {
        Text("\(text)")
            .onTapGesture {
                text = Date().formatted()
            }
    }
}
```

### Configurando o Aplicativo

Finalmente, configure o aplicativo na estrutura `@main`. Na inicialização, promova o aplicativo personalizado, habilite o registro e carregue a dependência do armazenamento do iCloud para sincronização:

```swift
@main
struct SyncStateExampleApp: App {
    init() {
        Application
            .promote(to: CustomApplication.self)
            .logging(isEnabled: true)
            .load(dependency: \.icloudStore)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### Habilitando o Armazenamento de Chave-Valor do iCloud

Para habilitar a sincronização do iCloud, certifique-se de seguir este guia para habilitar a capacidade de Armazenamento de Chave-Valor do iCloud: [Começando a usar o SyncState](starting-to-use-syncstate.md).

### SyncState: Notas sobre o Armazenamento do iCloud

Embora o `SyncState` permita uma sincronização fácil, é importante lembrar as limitações do `NSUbiquitousKeyValueStore`:

- **Limite de Armazenamento**: Você pode armazenar até 1 MB de dados no iCloud usando o `NSUbiquitousKeyValueStore`, com um limite de tamanho de valor por chave de 1 MB.

### Considerações sobre Migração

Ao atualizar seu modelo de dados, é importante levar em conta os possíveis desafios de migração, especialmente ao trabalhar com dados persistentes usando **StoredState**, **FileState** ou **SyncState**. Sem o tratamento adequado da migração, alterações como adicionar novos campos ou modificar formatos de dados podem causar problemas ao carregar dados mais antigos.

Aqui estão alguns pontos-chave a serem lembrados:
- **Adicionando Novos Campos Não Opcionais**: Certifique-se de que os novos campos sejam opcionais ou tenham valores padrão para manter a compatibilidade com versões anteriores.
- **Lidando com Alterações no Formato de Dados**: Se a estrutura do seu modelo mudar, implemente uma lógica de decodificação personalizada para suportar formatos antigos.
- **Versionando Seus Modelos**: Use um campo `version` em seus modelos para ajudar nas migrações e aplicar a lógica com base na versão dos dados.

Para saber mais sobre como gerenciar migrações e evitar possíveis problemas, consulte o [Guia de Considerações sobre Migração](migration-considerations.md).

## Guia de Implementação do SyncState

Para obter instruções detalhadas sobre como configurar o iCloud e o SyncState em seu projeto, consulte o [Guia de Implementação do SyncState](syncstate-implementation.md).

## Melhores Práticas

- **Use para Dados Pequenos e Críticos**: `SyncState` é ideal para sincronizar pequenas e importantes peças de estado, como preferências do usuário, configurações ou sinalizadores de recursos.
- **Monitore o Armazenamento do iCloud**: Certifique-se de que seu uso do `SyncState` permaneça dentro dos limites de armazenamento do iCloud para evitar problemas de sincronização de dados.
- **Lide com Atualizações Externas**: Se seu aplicativo precisar responder a alterações de estado iniciadas em outro dispositivo, substitua a função `didChangeExternally` para atualizar o estado do aplicativo em tempo real.

## Conclusão

`SyncState` fornece uma maneira poderosa de sincronizar pequenas quantidades de estado da aplicação em todos os dispositivos via iCloud. É ideal para garantir que as preferências do usuário e outros dados importantes permaneçam consistentes em todos os dispositivos conectados à mesma conta do iCloud. Para casos de uso mais avançados, explore outras funcionalidades do **AppState**, como [SecureState](usage-securestate.md) e [FileState](usage-filestate.md).

---
Isso foi gerado usando [Jules](https://jules.google), erros podem acontecer. Por favor, faça um Pull Request com quaisquer correções que devam acontecer se você for um falante nativo.
