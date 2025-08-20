# Uso do StoredState

`StoredState` é um componente da biblioteca **AppState** que permite armazenar e persistir pequenas quantidades de dados usando `UserDefaults`. É ideal para armazenar dados leves e não sensíveis que devem persistir entre os lançamentos do aplicativo.

## Visão Geral

- **StoredState** é construído sobre `UserDefaults`, o que significa que é rápido e eficiente para armazenar pequenas quantidades de dados (como preferências do usuário ou configurações do aplicativo).
- Os dados salvos em **StoredState** persistem entre as sessões do aplicativo, permitindo que você restaure o estado da aplicação no lançamento.

### Principais Características

- **Armazenamento Persistente**: Os dados salvos em `StoredState` permanecem disponíveis entre os lançamentos do aplicativo.
- **Manuseio de Dados Pequenos**: Melhor usado para dados leves como preferências, alternâncias ou pequenas configurações.
- **Seguro para Threads**: `StoredState` garante que o acesso aos dados permaneça seguro em ambientes concorrentes.

## Exemplo de Uso

### Definindo um StoredState

Você pode definir um **StoredState** estendendo o objeto `Application` e declarando a propriedade de estado:

```swift
import AppState

extension Application {
    var userPreferences: StoredState<String> {
        storedState(initial: "Default Preferences", id: "userPreferences")
    }
}
```

### Acessando e Modificando o StoredState em uma Visualização

Você pode acessar e modificar os valores de **StoredState** dentro das visualizações SwiftUI usando o property wrapper `@StoredState`:

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

## Lidando com a Migração de Dados

À medida que seu aplicativo evolui, você pode atualizar os modelos que são persistidos via **StoredState**. Ao atualizar seu modelo de dados, garanta a compatibilidade com versões anteriores. Por exemplo, você pode adicionar novos campos ou versionar seu modelo para lidar com a migração.

Para mais informações, consulte o [Guia de Considerações sobre Migração](migration-considerations.md).

### Considerações sobre Migração

- **Adicionando Novos Campos Não Opcionais**: Certifique-se de que os novos campos sejam opcionais ou tenham valores padrão para manter a compatibilidade com versões anteriores.
- **Versionando Modelos**: Se o seu modelo de dados mudar ao longo do tempo, inclua um campo `version` para gerenciar diferentes versões dos seus dados persistidos.

## Melhores Práticas

- **Use para Dados Pequenos**: Armazene dados leves e não sensíveis que precisam persistir entre os lançamentos do aplicativo, como as preferências do usuário.
- **Considere Alternativas para Dados Maiores**: Se você precisar armazenar grandes quantidades de dados, considere usar **FileState** em vez disso.

## Conclusão

**StoredState** é uma maneira simples e eficiente de persistir pequenas porções de dados usando `UserDefaults`. É ideal para salvar preferências e outras pequenas configurações entre os lançamentos do aplicativo, ao mesmo tempo que fornece acesso seguro e fácil integração com o SwiftUI. Para necessidades de persistência mais complexas, explore outras funcionalidades do **AppState**, como [FileState](usage-filestate.md) ou [SyncState](usage-syncstate.md).

---
Isso foi gerado usando [Jules](https://jules.google), erros podem acontecer. Por favor, faça um Pull Request com quaisquer correções que devam acontecer se você for um falante nativo.
