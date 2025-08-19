# Uso do SecureState

`SecureState` é um componente da biblioteca **AppState** que permite armazenar dados confidenciais de forma segura no Keychain. É mais adequado para armazenar pequenas porções de dados como tokens ou senhas que precisam ser criptografados com segurança.

## Principais Características

- **Armazenamento Seguro**: Os dados armazenados usando `SecureState` são criptografados e salvos com segurança no Keychain.
- **Persistência**: Os dados permanecem persistentes entre os lançamentos do aplicativo, permitindo a recuperação segura de valores confidenciais.

## Limitações do Keychain

Embora o `SecureState` seja muito seguro, ele possui certas limitações:

- **Tamanho de Armazenamento Limitado**: O Keychain é projetado para pequenas porções de dados. Não é adequado para armazenar arquivos grandes ou conjuntos de dados.
- **Desempenho**: O acesso ao Keychain é mais lento do que o acesso ao `UserDefaults`, portanto, use-o apenas quando necessário para armazenar dados confidenciais com segurança.

## Exemplo de Uso

### Armazenando um Token Seguro

```swift
import AppState
import SwiftUI

extension Application {
    var userToken: SecureState {
        secureState(id: "userToken")
    }
}

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

### Lidando com a Ausência de Dados Seguros

Ao acessar o Keychain pela primeira vez, ou se não houver valor armazenado, `SecureState` retornará `nil`. Certifique-se de lidar com este cenário adequadamente:

```swift
if let token = userToken {
    print("Token: \(token)")
} else {
    print("Nenhum token disponível.")
}
```

## Melhores Práticas

- **Use para Dados Pequenos**: O Keychain deve ser usado para armazenar pequenas porções de informações confidenciais como tokens, senhas e chaves.
- **Evite Grandes Conjuntos de Dados**: Se você precisar armazenar grandes conjuntos de dados com segurança, considere usar criptografia baseada em arquivos ou outros métodos, pois o Keychain não é projetado para armazenamento de grandes dados.
- **Lide com nulo**: Sempre lide com os casos em que o Keychain retorna `nil` quando nenhum valor está presente.
