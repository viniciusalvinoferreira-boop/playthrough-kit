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

### Track de CLICK

**Cuidado de design, não é só adicionar a track.** O export renderiza o master
mix inteiro, então uma track de click audível entra no vídeo final. E se ela
vier mutada, a pessoa não escuta enquanto grava, que é justamente pra isso que
ela existe.

Três caminhos, decidir na hora de implementar:

1. **Metrônomo nativo do REAPER.** Ele tem chave própria pra entrar ou não no
   render, então dá pra ouvir gravando sem vazar no arquivo. Mais limpo, mas
   não é uma track e não aparece no arranjo
2. **Track de click com aviso.** A pessoa põe o arquivo dela e muta antes de
   exportar. Simples, mas depende de lembrar, e esquecer significa click no
   vídeo publicado
3. **Track de click com verificação no export.** O script detecta uma track
   chamada CLICK audível e avisa antes de renderizar. Mais trabalho, mas não
   dá pra errar

O caminho 3 é o único que não depende da memória do usuário. Vale considerar
enquanto o export já vai ser mexido.

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
