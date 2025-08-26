# Visão Geral do Uso

Esta visão geral fornece uma introdução rápida ao uso dos principais componentes da biblioteca **AppState** dentro de uma `View` do SwiftUI. Cada seção inclui exemplos simples que se encaixam no escopo de uma estrutura de visualização do SwiftUI.

## Definindo Valores na Extensão da Aplicação

Para definir o estado ou as dependências de toda a aplicação, você deve estender o objeto `Application`. Isso permite que você centralize todo o estado da sua aplicação em um só lugar. Aqui está um exemplo de como estender `Application` para criar vários estados e dependências:

```swift
import AppState

extension Application {
    var user: State<User> {
        state(initial: User(name: "Guest", isLoggedIn: false))
    }

    var userPreferences: StoredState<String> {
        storedState(initial: "Default Preferences", id: "userPreferences")
    }

    var darkModeEnabled: SyncState<Bool> {
        syncState(initial: false, id: "darkModeEnabled")
    }

    var userToken: SecureState {
        secureState(id: "userToken")
    }

    @MainActor
    var largeDataset: FileState<[String]> {
        fileState(initial: [], filename: "largeDataset")
    }
}
```

## State

`State` permite que você defina um estado de toda a aplicação que pode ser acessado e modificado em qualquer lugar da sua aplicação.

### Exemplo

```swift
import AppState
import SwiftUI

struct ContentView: View {
    @AppState(\.user) var user: User

    var body: some View {
        VStack {
            Text("Olá, \(user.name)!")
            Button("Fazer login") {
                user.isLoggedIn.toggle()
            }
        }
    }
}
```

## StoredState

`StoredState` persiste o estado usando `UserDefaults` para garantir que os valores sejam salvos entre os lançamentos da aplicação.

### Exemplo

```swift
import AppState
import SwiftUI

struct PreferencesView: View {
    @StoredState(\.userPreferences) var userPreferences: String

    var body: some View {
        VStack {
            Text("Preferências: \(userPreferences)")
            Button("Atualizar Preferências") {
                userPreferences = "Updated Preferences"
            }
        }
    }
}
```

## SyncState

`SyncState` sincroniza o estado da aplicação em múltiplos dispositivos usando o iCloud.

### Exemplo

```swift
import AppState
import SwiftUI

struct SyncSettingsView: View {
    @SyncState(\.darkModeEnabled) var isDarkModeEnabled: Bool

    var body: some View {
        VStack {
            Toggle("Modo Escuro", isOn: $isDarkModeEnabled)
        }
    }
}
```

## FileState

`FileState` é usado para armazenar dados maiores ou mais complexos de forma persistente usando o sistema de arquivos, tornando-o ideal para cache ou para salvar dados que não se encaixam nas limitações do `UserDefaults`.

### Exemplo

```swift
import AppState
import SwiftUI

struct LargeDataView: View {
    @FileState(\.largeDataset) var largeDataset: [String]

    var body: some View {
        List(largeDataset, id: \.self) { item in
            Text(item)
        }
    }
}
```

## SecureState

`SecureState` armazena dados sensíveis de forma segura no Keychain.

### Exemplo

```swift
import AppState
import SwiftUI

struct SecureView: View {
    @SecureState(\.userToken) var userToken: String?

    var body: some View {
        VStack {
            if let token = userToken {
                Text("Token do usuário: \(token)")
            } else {
                Text("Nenhum token encontrado.")
            }
            Button("Definir Token") {
                userToken = "secure_token_value"
            }
        }
    }
}
```

## Constant

`Constant` fornece acesso imutável e somente leitura a valores dentro do estado da sua aplicação, garantindo a segurança ao acessar valores que não devem ser modificados.

### Exemplo

```swift
import AppState
import SwiftUI

struct ExampleView: View {
    @Constant(\.user, \.name) var name: String

    var body: some View {
        Text("Nome de usuário: \(name)")
    }
}
```

## Fatiando o Estado

`Slice` e `OptionalSlice` permitem que você acesse partes específicas do estado da sua aplicação.

### Exemplo

```swift
import AppState
import SwiftUI

struct SlicingView: View {
    @Slice(\.user, \.name) var name: String

    var body: some View {
        VStack {
            Text("Nome de usuário: \(name)")
            Button("Atualizar Nome de Usuário") {
                name = "NewUsername"
            }
        }
    }
}
```

## Melhores Práticas

- **Use `AppState` em Visualizações SwiftUI**: Os property wrappers como `@AppState`, `@StoredState`, `@FileState`, `@SecureState` e outros são projetados para serem usados no escopo das visualizações SwiftUI.
- **Defina o Estado na Extensão da Aplicação**: Centralize o gerenciamento de estado estendendo `Application` para definir o estado e as dependências da sua aplicação.
- **Atualizações Reativas**: O SwiftUI atualiza automaticamente as visualizações quando o estado muda, então você não precisa atualizar manualmente a interface do usuário.
- **[Guia de Melhores Práticas](best-practices.md)**: Para uma análise detalhada das melhores práticas ao usar o AppState.

## Próximos Passos

Depois de se familiarizar com o uso básico, você pode explorar tópicos mais avançados:

- Explore o uso de **FileState** para persistir grandes quantidades de dados em arquivos no [Guia de Uso do FileState](usage-filestate.md).
- Aprenda sobre **Constantes** e como usá-las para valores imutáveis no estado da sua aplicação no [Guia de Uso de Constantes](usage-constant.md).
- Investigue como a **Dependência** é usada no AppState para lidar com serviços compartilhados e veja exemplos no [Guia de Uso de Dependência de Estado](usage-state-dependency.md).
- Aprofunde-se em técnicas avançadas de **SwiftUI**, como o uso de `ObservedDependency` para gerenciar dependências observáveis em visualizações, no [Guia de Uso de ObservedDependency](usage-observeddependency.md).
- Para técnicas de uso mais avançadas, como criação Just-In-Time e pré-carregamento de dependências, consulte o [Guia de Uso Avançado](advanced-usage.md).

---
Esta tradução foi gerada automaticamente e pode conter erros. Se você é um falante nativo, agradecemos suas contribuições com correções por meio de um Pull Request.
