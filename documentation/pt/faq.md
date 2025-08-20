# Perguntas Frequentes

Este breve FAQ aborda questões comuns que os desenvolvedores podem ter ao usar o **AppState**.

## Como eu redefino um valor de estado?

Para estados persistentes como `StoredState`, `FileState` e `SyncState`, você pode redefini-los para seus valores iniciais usando as funções estáticas `reset` no tipo `Application`.

Por exemplo, para redefinir um `StoredState<Bool>`:
```swift
extension Application {
    var hasCompletedOnboarding: StoredState<Bool> { storedState(initial: false, id: "onboarding_complete") }
}

// Em algum lugar do seu código
Application.reset(storedState: \.hasCompletedOnboarding)
```
Isso redefinirá o valor no `UserDefaults` de volta para `false`. Funções `reset` semelhantes existem para `FileState`, `SyncState` e `SecureState`.

Para um `State` não persistente, você pode redefini-lo da mesma forma que os estados persistentes:
```swift
extension Application {
    var counter: State<Int> { state(initial: 0) }
}

// Em algum lugar do seu código
Application.reset(\.counter)
```

## Posso usar o AppState com tarefas assíncronas?

Sim. Os valores de `State` e de dependência são thread-safe e funcionam perfeitamente com o Swift Concurrency. Você pode acessá-los e modificá-los dentro de funções `async` sem bloqueio adicional.

## Onde devo definir os estados e as dependências?

Mantenha todos os seus estados e dependências em extensões de `Application`. Isso garante uma única fonte de verdade e facilita a descoberta de todos os valores disponíveis.

## O AppState é compatível com o Combine?

Você pode usar o AppState junto com o Combine, fazendo a ponte entre as alterações de `State` e os publishers. Observe um valor de `State` e envie atualizações através de um `PassthroughSubject` ou outro publisher do Combine, se necessário.

---
Isso foi gerado usando [Jules](https://jules.google), erros podem acontecer. Por favor, faça um Pull Request com quaisquer correções que devam acontecer se você for um falante nativo.
