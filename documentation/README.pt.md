# AppState

[![macOS Build](https://img.shields.io/github/actions/workflow/status/0xLeif/AppState/macOS.yml?label=macOS&branch=main)](https://github.com/0xLeif/AppState/actions/workflows/macOS.yml)
[![Ubuntu Build](https://img.shields.io/github/actions/workflow/status/0xLeif/AppState/ubuntu.yml?label=Ubuntu&branch=main)](https://github.com/0xLeif/AppState/actions/workflows/ubuntu.yml)
[![Windows Build](https://img.shields.io/github/actions/workflow/status/0xLeif/AppState/windows.yml?label=Windows&branch=main)](https://github.com/0xLeif/AppState/actions/workflows/windows.yml)
[![License](https://img.shields.io/github/license/0xLeif/AppState)](https://github.com/0xLeif/AppState/blob/main/LICENSE)
[![Version](https://img.shields.io/github/v/release/0xLeif/AppState)](https://github.com/0xLeif/AppState/releases)

Leia isto em outros idiomas: [Inglês](../README.md) | [Francês](README.fr.md) | [Alemão](README.de.md) | [Hindi](README.hi.md) | [Russo](README.ru.md) | [Chinês Simplificado](README.zh-CN.md) | [Espanhol](README.es.md)

**AppState** é uma biblioteca Swift 6 para gerenciar o estado da aplicação de uma forma segura para threads, segura para tipos e amigável ao SwiftUI. Centralize e sincronize o estado em toda a sua aplicação; injete dependências em qualquer lugar.

## Requisitos

- **iOS**: 17.0+
- **watchOS**: 10.0+
- **macOS**: 14.0+
- **tvOS**: 17.0+
- **visionOS**: 1.0+
- **Swift**: 6.0+
- **Xcode**: 16.0+

**Suporte a plataformas não-Apple**: Linux e Windows

> 🍎 Recursos marcados com este símbolo são específicos para plataformas Apple, pois dependem de tecnologias da Apple, como iCloud e o Keychain.

## Principais Recursos

**AppState** inclui:

- **State**: Gerenciamento de estado centralizado que permite encapsular e transmitir alterações em todo o aplicativo.
- **StoredState**: Estado persistente usando `UserDefaults`, ideal para salvar pequenas quantidades de dados entre as inicializações do aplicativo.
- **FileState**: Estado persistente armazenado usando `FileManager`, útil para armazenar grandes quantidades de dados com segurança no disco.
- 🍎 **SwiftData (ModelState)**: Gerencie objetos `@Model` do SwiftData através do AppState, injetando um `ModelContainer` compartilhado e lendo/gravando modelos com `ModelState`.
- 🍎 **SyncState**: Sincronize o estado em vários dispositivos usando o iCloud, garantindo a consistência nas preferências e configurações do usuário.
- 🍎 **SecureState**: Armazene dados confidenciais com segurança usando o Keychain, protegendo informações do usuário, como tokens ou senhas.
- **Gerenciamento de Dependências**: Injete dependências como serviços de rede ou clientes de banco de dados em todo o seu aplicativo para melhor modularidade e testes.
- **Slicing**: Acesse partes específicas de um estado ou dependência para controle granular sem a necessidade de gerenciar todo o estado da aplicação.
- **Constants**: Acesse fatias somente leitura do seu estado quando precisar de valores imutáveis.
- **Observed Dependencies**: Observe as dependências `ObservableObject` para que suas visualizações sejam atualizadas quando elas mudarem.

## Começando

Adicione o **AppState** via Swift Package Manager — consulte o [Guia de Instalação](pt/installation.md). Em seguida, confira a [Visão Geral do Uso](pt/usage-overview.md) para uma introdução rápida.

## Exemplo Rápido

```swift
import AppState
import SwiftUI

private extension Application {
    var counter: State<Int> {
        state(initial: 0)
    }
}

struct ContentView: View {
    @AppState(\.counter) var counter: Int

    var body: some View {
        VStack {
            Text("Count: \(counter)")
            Button("Increment") { counter += 1 }
        }
    }
}
```

## Documentação

Aqui está um detalhamento da documentação do **AppState**:

- [Guia de Instalação](pt/installation.md): Como adicionar o **AppState** ao seu projeto usando o Swift Package Manager.
- [Visão Geral do Uso](pt/usage-overview.md): Uma visão geral dos principais recursos com exemplos de implementação.

### Guias de Uso Detalhados:

- [Gerenciamento de Estado e Dependência](pt/usage-state-dependency.md): Centralize o estado e injete dependências em todo o seu aplicativo.
- [Fatiando o Estado](pt/usage-slice.md): Acesse e modifique partes específicas do estado.
- [Guia de Uso do StoredState](pt/usage-storedstate.md): Como persistir dados leves usando `StoredState`.
- [Guia de Uso do FileState](pt/usage-filestate.md): Aprenda a persistir grandes quantidades de dados com segurança no disco.
- 🍎 [Guia de Uso do ModelState](pt/usage-modelstate.md): Gerencie objetos `@Model` do SwiftData através de um `ModelContainer` compartilhado.
- [Uso do SecureState com Keychain](pt/usage-securestate.md): Armazene dados confidenciais com segurança usando o Keychain.
- [Sincronização com iCloud com SyncState](pt/usage-syncstate.md): Mantenha o estado sincronizado em todos os dispositivos usando o iCloud.
- [Atualizando para o AppState 3.0](pt/upgrade-to-v3.md): Alterações que quebram a compatibilidade e como migrar da linha de lançamento 2.x.
- [FAQ](pt/faq.md): Respostas a perguntas comuns ao usar o **AppState**.
- [Guia de Uso de Constantes](pt/usage-constant.md): Acesse valores somente leitura do seu estado.
- [Guia de Uso de ObservedDependency](pt/usage-observeddependency.md): Trabalhe com dependências `ObservableObject` em suas visualizações.
- [Uso Avançado](pt/advanced-usage.md): Técnicas como criação just-in-time e pré-carregamento de dependências.
- [Melhores Práticas](pt/best-practices.md): Dicas para estruturar o estado do seu aplicativo de forma eficaz.
- [Considerações sobre Migração](pt/migration-considerations.md): Orientação ao atualizar modelos persistidos.

## Contribuições

Aceitamos contribuições! Por favor, confira nosso [Guia de Contribuição](pt/contributing.md) para saber como se envolver.

## Próximos Passos

Comece com a [Visão Geral do Uso](pt/usage-overview.md). Para criação Just-In-Time e pré-carregamento, consulte o [Guia de Uso Avançado](pt/advanced-usage.md). Os guias [Constant](pt/usage-constant.md) e [ObservedDependency](pt/usage-observeddependency.md) cobrem recursos adicionais.

---
Esta tradução foi gerada automaticamente e pode conter erros. Se você é um falante nativo, agradecemos suas contribuições com correções por meio de um Pull Request.
