# Considerações sobre Migração

Ao atualizar seu modelo de dados, especialmente para dados persistidos ou sincronizados, você precisa lidar com a compatibilidade retroativa para evitar possíveis problemas ao carregar dados mais antigos. Aqui estão alguns pontos importantes a serem lembrados:

## 1. Adicionando Campos Não Opcionais
Se você adicionar novos campos não opcionais ao seu modelo, a decodificação de dados antigos (que não conterão esses campos) pode falhar. Para evitar isso:
- Considere dar valores padrão aos novos campos.
- Torne os novos campos opcionais para garantir a compatibilidade com versões mais antigas do seu aplicativo.

### Exemplo:
```swift
struct Settings: Codable {
    var text: String
    var isDarkMode: Bool
    var newField: String? // Novo campo é opcional
}
```

## 2. Mudanças no Formato dos Dados
Se você modificar a estrutura de um modelo (por exemplo, alterando um tipo de `Int` para `String`), o processo de decodificação pode falhar ao ler dados mais antigos. Planeje uma migração suave:
- Criando uma lógica de migração para converter formatos de dados antigos para a nova estrutura.
- Usando o inicializador personalizado de `Decodable` para lidar com dados antigos e mapeá-los para o seu novo modelo.

### Exemplo:
```swift
struct Settings: Codable {
    var text: String
    var isDarkMode: Bool
    var version: Int

    // Lógica de decodificação personalizada para versões mais antigas
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.text = try container.decode(String.self, forKey: .text)
        self.isDarkMode = try container.decode(Bool.self, forKey: .isDarkMode)
        self.version = (try? container.decode(Int.self, forKey: .version)) ?? 1 // Padrão para dados mais antigos
    }
}
```

## 3. Lidando com Campos Excluídos ou Obsoletos
Se você remover um campo do modelo, certifique-se de que as versões antigas do aplicativo ainda possam decodificar os novos dados sem travar. Você pode:
- Ignorar campos extras ao decodificar.
- Usar decodificadores personalizados para lidar com dados antigos e gerenciar campos obsoletos adequadamente.

## 4. Versionando Seus Modelos

O versionamento de seus modelos permite que você lide com as mudanças em sua estrutura de dados ao longo do tempo. Ao manter um número de versão como parte de seu modelo, você pode implementar facilmente uma lógica de migração para converter formatos de dados antigos em novos. Essa abordagem garante que seu aplicativo possa lidar com estruturas de dados antigas enquanto transita suavemente para novas versões.

- **Por que o Versionamento é Importante**: Quando os usuários atualizam seu aplicativo, eles ainda podem ter dados mais antigos persistidos em seus dispositivos. O versionamento ajuda seu aplicativo a reconhecer o formato dos dados e a aplicar a lógica de migração correta.
- **Como Usar**: Adicione um campo `version` ao seu modelo e verifique-o durante o processo de decodificação para determinar se a migração é necessária.

### Exemplo:
```swift
struct Settings: Codable {
    var version: Int
    var text: String
    var isDarkMode: Bool

    // Lidar com a lógica de decodificação específica da versão
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.version = try container.decode(Int.self, forKey: .version)
        self.text = try container.decode(String.self, forKey: .text)
        self.isDarkMode = try container.decode(Bool.self, forKey: .isDarkMode)

        // Se estiver migrando de uma versão mais antiga, aplique as transformações necessárias aqui
        if version < 2 {
            // Migrar dados mais antigos para o novo formato
        }
    }
}
```

- **Melhor Prática**: Comece com um campo `version` desde o início. Cada vez que você atualizar a estrutura do seu modelo, incremente a versão e lide com a lógica de migração necessária.

## 5. Testando a Migração
Sempre teste sua migração completamente, simulando o carregamento de dados antigos com novas versões do seu modelo para garantir que seu aplicativo se comporte como esperado.

---
Isso foi gerado usando [Jules](https://jules.google), erros podem acontecer. Por favor, faça um Pull Request com quaisquer correções que devam acontecer se você for um falante nativo.
