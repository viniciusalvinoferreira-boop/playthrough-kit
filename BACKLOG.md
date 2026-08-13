# Backlog

O que está na fila, e o porquê de cada coisa. Arquivo de trabalho, não é
documentação pra quem usa o kit.

---

## Próxima leva: MIDI e generalização

### Template MIDI

Tracks: VIDEO (mutada), REFERENCIA SYNC (armada, mono, mutada), INSTRUMENTO
MIDI (armada, entrada 4096, sem plugin) e BACKING TRACK.

A track de referência é o coração disso. Com MIDI não existe som no ar: o
instrumento é silencioso e o áudio mora dentro do plugin, no fone. Um
microfone qualquer resolve, e a qualidade não importa, porque esse áudio nunca
vai pro arquivo final. Vem mutada, e mute não impede gravação.

A track MIDI vai **sem plugin**. Não dá pra assumir que a pessoa tem EZdrummer
ou Superior, e template que abre com plugin faltando dá erro feio de cara.

### Sync aceitando item MIDI

Ler a posição da primeira nota do take MIDI e usar como marcador, em vez de
rejeitar MIDI como hoje. Resolve o lado do REAPER sem exigir congelar track.

Não resolve o lado da câmera: ela ainda precisa captar alguma coisa. Se o pad
for silencioso e a pessoa estiver de fone, a resposta continua sendo a track de
referência.

### Nomes genéricos no template atual

`GUITARRA (entrada 1-2)` vira `INSTRUMENTO (entrada 1-2)`. Tirar "cordas" e
"captador" das notas do template.

### Track de CLICK, e a regra das tracks de apoio

Adicionar a track é a parte fácil. O problema é que o export renderiza o master
mix inteiro, então click audível entra no vídeo publicado. E a track não pode
vir mutada de fábrica, porque é justamente durante a gravação que ela precisa
soar.

**Decisão: o script cobra a regra, não o usuário.**

Documentação depende de lembrar, e quem esquece só descobre depois de postar.
Então o export passa a verificar sozinho.

O que ele faz, antes de renderizar:

1. Procura tracks de apoio que estejam audíveis. Reconhece pelo nome:
   `VIDEO`, `CLICK`, `REFERENCIA` e `REF`
2. Se achar alguma, mostra quais são e pergunta se pode silenciar
3. Muta, renderiza, e **devolve o estado original** ao terminar

Devolver o estado importa: a pessoa aperta play depois do export e o click
continua lá, do jeito que ela deixou. O script não bagunça o projeto pra
resolver um problema dele.

Isso generaliza pra além do click. A regra real do kit é **track de apoio não
entra no mix**, e ela já vale hoje pra track de vídeo, que alguém pode desmutar
pra conferir o alinhamento e esquecer de mutar de novo.

Implementar junto com a leva do MIDI, já que o export vai ser mexido e a track
de referência do template MIDI cai exatamente na mesma regra.

### Template multitrack

VIDEO, IN 1 a IN 4 (mono, entradas 1 a 4) e BACKING TRACK. Nomes neutros: o
baterista renomeia pra bumbo, caixa e overheads, quem grava amp com dois mics
usa duas.

Documentar que o sync quer **uma** track de referência, não todas. A caixa é a
melhor escolha, por ter o transiente mais limpo. Bumbo é pior, o ataque é lento
e o script pode marcar dentro do golpe.

---

## Lançamento

### Renumerar pra 1.0

Nada disso foi público, então pro mundo o lançamento é o primeiro. Numerar como
1.6 levantaria a pergunta "o que eu perdi antes?".

Ao publicar: versão 1.0 nos dois catálogos, CHANGELOG reescrito começando do
1.0 e descrevendo o que o kit faz, não correções que ninguém viu. O histórico
técnico continua no `git log`.

**Detalhe do ReaPack:** ele compara números, e 1.0 é menor que a versão
instalada. Não vai oferecer atualização. Precisa remover o repositório e
importar de novo, o que de quebra serve como teste de instalação limpa.

---

## Ideias sem data

- **Divulgação:** vídeo curto mostrando os dois hashes idênticos lado a lado.
  É o argumento mais forte e é verificável
- **Monetização:** o kit fica grátis. O que se vende é o que não pode ser
  copiado: curso, atendimento, comunidade. O repositório público inviabiliza
  vender o arquivo, e essa é a escolha certa
- **macOS:** exigiria trocar a chamada de `cmd.exe` e a montagem de caminhos.
  Só faz sentido com alguém de Mac pra testar
- **Multicâmera:** aí sim seria outro kit, porque a lógica é diferente
  (sincronizar N vídeos entre si)
