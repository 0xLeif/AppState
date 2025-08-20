# Guia de Instalação

Este guia irá orientá-lo através do processo de instalação do **AppState** no seu projeto Swift usando o Swift Package Manager.

## Swift Package Manager

O **AppState** pode ser facilmente integrado ao seu projeto usando o Swift Package Manager. Siga os passos abaixo para adicionar o **AppState** como uma dependência.

### Passo 1: Atualize o seu Arquivo `Package.swift`

Adicione o **AppState** à seção `dependencies` do seu arquivo `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/0xLeif/AppState.git", from: "2.2.0")
]
```

### Passo 2: Adicione o AppState ao seu Alvo

Inclua o AppState nas dependências do seu alvo:

```swift
.target(
    name: "YourTarget",
    dependencies: ["AppState"]
)
```

### Passo 3: Compile o seu Projeto

Depois de adicionar o AppState ao seu arquivo `Package.swift`, compile o seu projeto para buscar a dependência e integrá-la ao seu código-base.

```
swift build
```

### Passo 4: Importe o AppState no seu Código

Agora, você pode começar a usar o AppState no seu projeto importando-o no topo dos seus arquivos Swift:

```swift
import AppState
```

## Xcode

Se você preferir adicionar o **AppState** diretamente através do Xcode, siga estes passos:

### Passo 1: Abra o seu Projeto Xcode

Abra o seu projeto ou workspace do Xcode.

### Passo 2: Adicione uma Dependência de Pacote Swift

1. Navegue até o navegador de projetos e selecione o arquivo do seu projeto.
2. No editor de projetos, selecione o seu alvo e, em seguida, vá para a guia "Swift Packages".
3. Clique no botão "+" para adicionar uma dependência de pacote.

### Passo 3: Insira a URL do Repositório

Na caixa de diálogo "Choose Package Repository", insira a seguinte URL: `https://github.com/0xLeif/AppState.git`

Em seguida, clique em "Next".

### Passo 4: Especifique a Versão

Escolha a versão que deseja usar. Recomenda-se selecionar a opção "Up to Next Major Version" e especificar `2.0.0` como o limite inferior. Em seguida, clique em "Next".

### Passo 5: Adicione o Pacote

O Xcode buscará o pacote e apresentará opções para adicionar o **AppState** ao seu alvo. Certifique-se de selecionar o alvo correto e clique em "Finish".

### Passo 6: Importe o `AppState` no seu Código

Agora você pode importar o **AppState** no topo dos seus arquivos Swift:

```swift
import AppState
```

## Próximos Passos

Com o AppState instalado, você pode avançar para a [Visão Geral do Uso](usage-overview.md) para ver como implementar os principais recursos no seu projeto.

---
Isso foi gerado usando Jules, erros podem acontecer. Por favor, faça um Pull Request com quaisquer correções que devam acontecer se você for um falante nativo.
