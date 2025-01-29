# FiveM Race Script (Standalone)

## 📌 Sobre
Este script permite a criação de corridas no FiveM, adicionando checkpoints dinamicamente e funcionando de forma totalmente standalone, sem a necessidade de frameworks como ESX ou QBCore.

## 🚀 Recursos
- 📍 **Criação de Checkpoints**: Adicione checkpoints personalizados para definir o percurso da corrida.
- 🎮 **Standalone**: Funciona sem dependência de frameworks.
- 🏎️ **Corridas Customizáveis**: Defina o percurso da corrida dinamicamente.
- 🔧 **Fácil Configuração**: Configuração simples por meio de comandos e atalhos.

## 🎮 Comandos e Atalhos
| Comando/Tecla         | Descrição |
|-----------------------|------------|
| `F10` (Tecla)        | Adiciona um checkpoint na posição do jogador. |
| `/startRace`         | Inicia a corrida após a configuração dos checkpoints. |
| `/resetRace`         | Reseta a corrida e remove todos os checkpoints. |

## 📦 Instalação
1. Baixe os arquivos do repositório.
2. Extraia o conteúdo na pasta `resources` do seu servidor FiveM.
3. Adicione a linha abaixo ao seu `server.cfg`:
   ```cfg
   ensure race_script
   ```
4. Reinicie o servidor e utilize os comandos para criar suas corridas!

## 🛠 Configuração
Dentro do arquivo `config.lua`, você pode ajustar diversos parâmetros, como:
```lua
Config = {
    CHECKPOINT_PROXIMITY_THRESHOLD = 10.0, -- Distância para considerar o checkpoint concluído
    CHECKPOINT_BLIP_COLOR = 5, -- Cor do blip no mapa
    CHECKPOINT_BLIP_SCALE = 0.8, -- Tamanho do blip no mapa
    CHECKPOINT_BLIP_SPRITE = 1, -- Ícone do blip
    CHECKPOINT_3D_COLOR = {r = 0, g = 255, b = 0, a = 100}, -- Cor do checkpoint 3D
    CHECKPOINT_3D_SIZE = 3.0 -- Tamanho do checkpoint 3D
}
```

## 📜 Como Funciona
1. Utilize a tecla `F10` para adicionar checkpoints no mapa enquanto configura a corrida.
2. Use `/startRace` para iniciar a corrida após a configuração dos checkpoints.
3. O primeiro waypoint será definido automaticamente ao iniciar a corrida.
4. Ao passar por um checkpoint, o próximo será ativado até completar todos os pontos.
5. Se desejar reiniciar a corrida, use `/resetRace`.

## 📜 Licença
Este projeto está sob a licença MIT. Sinta-se livre para modificar e adaptar ao seu servidor!

## 📞 Suporte
Caso tenha dúvidas ou precise de ajuda, entre em contato através do Discord ou abra uma issue no repositório.

---

Divirta-se correndo! 🏁

