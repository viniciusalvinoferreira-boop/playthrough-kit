# Fluxo de trabalho

Este arquivo é pra quem mexe no kit, não pra quem usa. Se você só quer gravar
vídeo, o arquivo certo é o `LEIA-ME.md`.

## As duas branches

| Branch | Papel | Quem consome |
|---|---|---|
| `main` | produção | qualquer pessoa que instalou o kit |
| `dev` | testes | só você, antes de promover |

Regra única: **nada chega na `main` sem ter rodado na `dev` primeiro.**

Isso não era verdade nas versões 1.1, 1.2 e 1.3, que foram publicadas direto na
`main`. Deu certo porque ninguém além do autor usava. A partir do momento em que
existe gente do outro lado, publicar sem testar significa quebrar a instalação
de estranhos, e eles não têm como voltar atrás sozinhos.

## Os dois catálogos

Existem dois arquivos de índice, e eles vivem nas duas branches:

| Arquivo | Aponta pra | URL pro ReaPack |
|---|---|---|
| `index.xml` | `main` | `.../playthrough-kit/main/index.xml` |
| `index-dev.xml` | `dev` | `.../playthrough-kit/dev/index-dev.xml` |

Ter dois arquivos em vez de um índice diferente por branch é de propósito:
assim os arquivos são idênticos nas duas branches, e o merge de `dev` pra `main`
nunca dá conflito no catálogo. Se cada branch tivesse a sua versão do
`index.xml`, todo merge viraria uma resolução manual.

**Não deixe os dois repositórios importados no mesmo REAPER.** Os pacotes
instalam nos mesmos caminhos e brigam. Ou você usa um de cada vez, ou instala o
de dev numa cópia portable do REAPER, que é o ideal se você for testar bastante.

## Ciclo de uma correção

```
git checkout dev
   ... edita os scripts ...
   ... sobe a versão em index-dev.xml ...
git commit -am "descreve o que muda"
git push origin dev
```

Testa instalando pelo `index-dev.xml`. Se estiver bom:

```
git checkout main
git merge dev
   ... sobe a mesma versão em index.xml ...
   ... escreve a entrada no CHANGELOG.md ...
git commit -am "vX.Y: resumo"
git push origin main
```

A versão precisa subir nos dois índices porque o ReaPack só oferece atualização
quando o número muda. Se você editar um script sem subir a versão, ninguém
recebe nada.

## O que testar antes de promover

O mínimo, sempre:

1. Rodar o `playthrough_diagnostico` e ver se o relatório sai limpo
2. Rodar o teste de 3 segundos da pasta `Teste/` e conferir se dá +3000,0 ms
3. Se mexeu no export, fazer um mux de verdade e conferir se o vídeo saiu intacto

O passo 2 pega quase tudo que quebra em silêncio. É barato e vale sempre.

## Nunca suba versão com busca e troca global

Já aconteceu: um `replace_all` de `1.3` para `1.4` nos arquivos atingiu também a
constante `VIDEO_AUDIO_OFFSET_MS = 21.3`, que virou `21.4`. No bump seguinte
virou `21.5`. O erro era de 0,2 ms, invisível na prática, e sobreviveu a duas
versões sem ninguém notar.

Ao subir a versão, edite **as linhas específicas**: o cabeçalho `@version`, o
título do bloco de comentário, e os índices. Números soltos no meio do código
não são versão, e nenhum deles deve mudar quando a versão muda.

## Versionamento

Números pequenos, sem cerimônia:

- **X.Y** onde Y sobe a cada correção ou ajuste
- X sobe se o fluxo de uso mudar a ponto de invalidar o que está no `LEIA-ME.md`

Toda mudança publicada ganha uma entrada no `CHANGELOG.md`, e a entrada explica
**por que** a mudança existe, não só o que mudou. O "por que" é o que salva você
daqui a seis meses, quando não lembrar do motivo de um valor estranho estar ali.
