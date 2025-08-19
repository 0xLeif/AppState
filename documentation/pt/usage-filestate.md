# Uso do FileState

`FileState` é um componente da biblioteca **AppState** que permite armazenar e recuperar dados persistentes usando o sistema de arquivos. É útil para armazenar dados grandes ou objetos complexos que precisam ser salvos entre os lançamentos do aplicativo e restaurados quando necessário.

## Principais Características

- **Armazenamento Persistente**: Os dados armazenados usando `FileState` persistem entre os lançamentos do aplicativo.
- **Manuseio de Dados Grandes**: Ao contrário de `StoredState`, `FileState` é ideal para lidar com dados maiores ou mais complexos.
- **Seguro para Threads**: Assim como outros componentes do AppState, `FileState` garante o acesso seguro aos dados em ambientes concorrentes.

## Exemplo de Uso

### Armazenando e Recuperando Dados com FileState

Veja como definir um `FileState` na extensão `Application` para armazenar e recuperar um objeto grande:

```swift
import AppState
import SwiftUI

struct UserProfile: Codable {
    var name: String
    var age: Int
}

extension Application {
    @MainActor
    var userProfile: FileState<UserProfile> {
        fileState(initial: UserProfile(name: "Guest", age: 25), filename: "userProfile")
    }
}

struct FileStateExampleView: View {
    @FileState(\.userProfile) var userProfile: UserProfile

    var body: some View {
        VStack {
            Text("Nome: \(userProfile.name), Idade: \(userProfile.age)")
            Button("Atualizar Perfil") {
                userProfile = UserProfile(name: "UpdatedName", age: 30)
            }
        }
    }
}
```

### Lidando com Dados Grandes com FileState

Quando você precisa lidar com conjuntos de dados ou objetos maiores, `FileState` garante que os dados sejam armazenados de forma eficiente no sistema de arquivos do aplicativo. Isso é útil para cenários como cache ou armazenamento offline.

```swift
import AppState
import SwiftUI

extension Application {
    @MainActor
    var largeDataset: FileState<[String]> {
        fileState(initial: [], filename: "largeDataset")
    }
}

struct LargeDataView: View {
    @FileState(\.largeDataset) var largeDataset: [String]

    var body: some View {
        List(largeDataset, id: \.self) { item in
            Text(item)
        }
    }
}
```

### Considerações sobre Migração

Ao atualizar seu modelo de dados, é importante levar em conta os possíveis desafios de migração, especialmente ao trabalhar com dados persistentes usando **StoredState**, **FileState** ou **SyncState**. Sem o tratamento adequado da migração, alterações como adicionar novos campos ou modificar formatos de dados podem causar problemas ao carregar dados mais antigos.

Aqui estão alguns pontos-chave a serem lembrados:
- **Adicionando Novos Campos Não Opcionais**: Certifique-se de que os novos campos sejam opcionais ou tenham valores padrão para manter a compatibilidade com versões anteriores.
- **Lidando com Alterações no Formato de Dados**: Se a estrutura do seu modelo mudar, implemente uma lógica de decodificação personalizada para suportar formatos antigos.
- **Versionando Seus Modelos**: Use um campo `version` em seus modelos para ajudar nas migrações e aplicar a lógica com base na versão dos dados.

Para saber mais sobre como gerenciar migrações e evitar possíveis problemas, consulte o [Guia de Considerações sobre Migração](migration-considerations.md).


## Melhores Práticas

- **Use para Dados Grandes ou Complexos**: Se você estiver armazenando dados grandes ou objetos complexos, `FileState` é ideal em vez de `StoredState`.
- **Acesso Seguro para Threads**: Assim como outros componentes do **AppState**, `FileState` garante que os dados sejam acessados com segurança, mesmo quando várias tarefas interagem com os dados armazenados.
- **Combine com Codable**: Ao trabalhar com tipos de dados personalizados, certifique-se de que eles estejam em conformidade com `Codable` para simplificar a codificação e decodificação de e para o sistema de arquivos.

## Conclusão

`FileState` é uma ferramenta poderosa para lidar com dados persistentes em seu aplicativo, permitindo que você armazene e recupere objetos maiores ou mais complexos de maneira segura para threads e persistente. Ele funciona perfeitamente com o protocolo `Codable` do Swift, garantindo que seus dados possam ser facilmente serializados e desserializados para armazenamento a longo prazo.
