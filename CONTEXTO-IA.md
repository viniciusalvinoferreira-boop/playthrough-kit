# Contexto para assistentes de IA

Este arquivo existe pra ser colado inteiro num assistente (ChatGPT, Claude,
Copilot) junto com a dúvida do usuário. Ele descreve o Playthrough Kit: o que
cada peça faz, por que foi feita assim, e onde costuma quebrar.

Se você é uma IA lendo isto: o usuário provavelmente está tentando instalar ou
consertar algo aqui. As seções **Modos de falha** e **Não sugira isto** cobrem
a maioria dos casos. Prefira as respostas daqui às suas suposições, porque
várias decisões abaixo são contraintuitivas e foram tomadas por um motivo.

## Peça estas duas coisas antes de teorizar

O kit vem com ferramentas de diagnóstico próprias. Use elas em vez de pedir
pro usuário descrever sintomas:

**1. O relatório de ambiente.** No REAPER: `Actions > Show action list >
playthrough_diagnostico`. Ele não altera nada e cospe no console a versão do
REAPER, o caminho do ffmpeg, o sample rate e a análise dos itens selecionados,
já com os códigos de erro relevantes. Peça o texto inteiro.

**2. O resultado do teste embutido.** A pasta `Teste/` tem dois arquivos com
deslocamento conhecido de 3 segundos. Arrastados pro REAPER na posição 0 e
sincronizados, o console tem que mostrar `+3000.0 ms`, com variação normal de 1
ou 2 ms. Quem instalou pelo ReaPack não recebe esses arquivos: eles estão no
repositório, em `Teste/`.

Esse teste é o divisor de águas do diagnóstico:

- **Deu 3000:** a instalação está boa. O problema está na gravação do usuário,
  e em quase todos os casos é o marcador (ver a seção sobre o chunk).
- **Não deu 3000:** o problema é de instalação ou ambiente, e o relatório do
  passo 1 vai apontar onde.

Não pule esse teste. Ele elimina metade das hipóteses em dois minutos.

---

## O que o kit faz

Automatiza a produção de vídeos de playthrough de guitarra no REAPER:

1. Sincroniza automaticamente o vídeo da câmera com o áudio gravado no DAW
2. Exporta o vídeo final **sem re-encodar o stream de vídeo**

O ganho central é o item 2. O vídeo final é bit a bit idêntico ao que saiu da
câmera, só com a faixa de áudio substituída.

---

## Arquivos e onde eles vivem

| Arquivo | Destino | Papel |
|---|---|---|
| `playthrough_sync_video.lua` | `%APPDATA%\REAPER\Scripts\` | alinha vídeo e áudio |
| `playthrough_export_mux.lua` | `%APPDATA%\REAPER\Scripts\` | renderiza e junta |
| `playthrough_diagnostico.lua` | `%APPDATA%\REAPER\Scripts\` | relatório de ambiente, não altera nada |
| `Playthrough.RPP` | `%APPDATA%\REAPER\ProjectTemplates\` | template de projeto |
| `Teste/` | fica no pacote | dois arquivos com deslocamento conhecido de 3 s |
| `INSTALAR.bat` | não instala nada de si | copia os acima |

Os três scripts são independentes entre si: cada um funciona sozinho, sem
módulo comum. A busca do ffmpeg aparece duplicada no export e no diagnóstico
de propósito, pra que instalar um sem o outro nunca quebre nada.

Os scripts ainda precisam ser registrados manualmente no REAPER via
`Actions > Show action list > New action > Load ReaScript`. Isso é deliberado:
registrar por fora exigiria editar `reaper-kb.ini`, e o REAPER reescreve esse
arquivo ao fechar, então uma edição externa com o programa aberto seria
descartada ou corromperia atalhos existentes.

---

## Como o sync funciona

O script pede dois itens selecionados: um de vídeo (detectado por extensão) e
um de áudio.

Em cada um, ele:

1. Abre um `AudioAccessor` sobre o take
2. Varre os primeiros `SEARCH_WINDOW` segundos (padrão 20) e acha o pico
   absoluto
3. Varre de novo e acha o **primeiro** ponto que cruza `ATTACK_RATIO` do pico
   (padrão 0.5). Isso pega o início do ataque, não o topo dele
4. Calcula `delta = (posRef + tRef) - (posVid + tVid)` e move o item de vídeo

Detalhe de implementação que importa: a leitura é feita com
`numchannels = 1`. Com um canal só, os layouts interleaved e planar coincidem,
então a posição do transiente sai correta independente da convenção interna do
buffer do REAPER. Com 2 canais o resultado dependeria dessa convenção. **Não
"otimize" isso pra ler estéreo.**

### O marcador precisa existir nos dois sinais

Este é o conceito que todo mundo erra, incluindo IAs.

O vídeo carrega o áudio do microfone da câmera. O REAPER carrega o áudio do
captador da guitarra. São dois mundos diferentes. Pro sync ter em que se
ancorar, o evento tem que aparecer nos dois.

- **Palma não serve.** Entra no mic da câmera, não passa pelo captador.
- **Claquete não serve.** Mesmo motivo.
- **Serve:** um golpe seco nas cordas abafadas, o "chunk". Sai pelo captador e
  sai acusticamente pelo ar ao mesmo tempo.

Se o usuário relata que o sync errou, a primeira pergunta é sempre se houve
chunk e se foi forte.

---

## Como o export funciona

1. Define a time selection exatamente sobre o item de vídeo
2. Configura o render via `GetSetProjectInfo` e renderiza o master mix em WAV
3. Escreve um `.bat` temporário e chama o ffmpeg
4. Apaga o `.bat`

O comando montado é:

```
ffmpeg -y -i <video> -i <wav> -map 0:v:0 -map 1:a:0 \
       -c:v copy -c:a aac -b:a 320k -movflags +faststart -shortest <saida>
```

`-c:v copy` é o coração de tudo. O stream de vídeo é copiado sem passar por
decoder nem encoder. É por isso que a qualidade não cai.

O `.bat` intermediário existe porque montar essa linha com aspas direto no
`cmd.exe` via `ExecProcess` é frágil, principalmente com caminhos que têm
espaço ou acento.

---

## Valores mágicos, e por que são esses

**`1024` e `1026` na linha `REC` do template.** O REAPER codifica a entrada de
gravação assim: `0..N` são entradas mono (índice 0-based), e `1024 + N` é um
par estéreo começando no canal N. Então:

- entrada estéreo 1/2 = `1024 + 0` = **1024** (o que vem no template)
- entrada estéreo 3/4 = `1024 + 2` = **1026**
- entrada mono 3 = **2**

**`ZXZhdxgAAQ==` no `RENDER_FORMAT` e no `.RPP`.** É o cfg de render do REAPER
para WAV 24 bits. Decodificando o base64: `evaw` (que é "wave" ao contrário,
o cookie do formato) seguido do byte `0x18`, que é 24 em decimal, a
profundidade de bits. Cravar isso no script torna o export independente do que
estiver configurado na janela de render do usuário.

**`41824` no `Main_OnCommand`.** É o comando "render usando as configurações
mais recentes", que renderiza sem abrir diálogo.

**A track de vídeo vem mutada no template.** É intencional, não é descuido. O
sync lê o áudio direto do arquivo pelo `AudioAccessor`, o que funciona
normalmente com a track mutada. Mutada, o mic da câmera não vaza pro mix
final. Se alguém desmutar pra conferir o alinhamento, precisa mutar de novo
antes de exportar.

**`VIDEO_AUDIO_OFFSET_MS = 21.3` no sync.** Compensação do priming do AAC, e
não é um número inventado.

Encoders AAC inserem um bloco de silêncio no início do stream, chamado priming,
tipicamente de 1024 samples. A 48 kHz isso dá 21,33 ms. Players que leem o
metadado descartam o bloco; o REAPER **não descarta** ao entregar o áudio pelo
audio accessor. Resultado: o áudio do vídeo chega no script cerca de 21 ms
atrasado em relação à imagem, e sem compensar, o alinhamento herda esse erro.

Dá pra verificar em qualquer arquivo com
`ffprobe -show_entries stream=initial_padding`.

Se o áudio do vídeo for PCM (alguns `.mov`), o valor certo é `0`. Se for AAC a
44,1 kHz, é `23.2` (1024 / 44100).

Não remova essa compensação achando que é gambiarra. Sem ela o sync erra 21 ms
de forma sistemática em qualquer vídeo de celular.

**Onde o ReaPack instala.** Não é a mesma pasta do `INSTALAR.bat`. O instalador
põe em `Scripts\`, o ReaPack põe numa subpasta própria dele. Por isso o
diagnóstico localiza os arquivos via `get_action_context()` (onde eu mesmo
estou) em vez de checar um caminho fixo. Checar caminho fixo dava falso
"NAO ENCONTRADO" pra quem tinha instalado corretamente pelo ReaPack.

---

## O problema do PATH, e por que o script procura o ffmpeg

Um processo no Windows herda o `PATH` que existia quando ele foi iniciado.
Quem instala o ffmpeg com o REAPER já aberto tem um REAPER que não enxerga o
ffmpeg, mesmo com a instalação perfeita. Chamar `ffmpeg` puro falharia com uma
mensagem que não ajuda ninguém.

Além disso, o winget instala em uma pasta com a versão no nome
(`ffmpeg-9.0-full_build`), que muda a cada atualização.

Por isso `findFFmpeg()` procura, nesta ordem: ao lado do próprio script, na
pasta de pacotes do winget (casando o prefixo `Gyan.FFmpeg`), nos links do
winget, em caminhos comuns de instalação manual, e por último pergunta ao
Windows com `where ffmpeg`. Devolve caminho absoluto, que funciona
independente do PATH do processo.

---

## Premissas do sync

O cálculo assume:

- `playrate = 1.0` nos dois itens
- itens não cortados no início (`D_STARTOFFS = 0`)
- o marcador está dentro dos primeiros 20 segundos

O script detecta as duas primeiras e pergunta antes de continuar. A orientação
é sempre **sincronizar primeiro, cortar depois**.

---

## Sample rate

Vídeo é sempre 48 kHz. Projeto em 44,1 kHz gera resample e, em takes longos,
deriva audível entre imagem e som.

Os dois scripts checam `PROJECT_SRATE` e `PROJECT_SRATE_USE`. O sync avisa no
console, o export bloqueia e pede confirmação.

Conserto no REAPER: `Options > Preferences > Audio > Device`, marcar
**Request sample rate** e pôr 48000. O template já traz o projeto em 48000.

Nota sobre deriva de clock: a câmera e a interface de áudio têm clocks
independentes. Em takes de 3 a 5 minutos o desvio é irrelevante. Em takes de 20
minutos ou mais pode acumular alguns frames no fim. A orientação é gravar por
música, não por sessão inteira.

---

## Modos de falha

Toda mensagem do kit carrega um código `[PT-xx]`. Se o usuário citar um código,
vá direto na linha correspondente.

| Código | Causa | Conserto |
|---|---|---|
| **PT-01** | seleção errada | sync quer 2 itens (vídeo e guitarra), export quer 1 (só o vídeo) |
| **PT-02** | não deu pra identificar um vídeo e um áudio | extensões reconhecidas: mp4, mov, m4v, mkv, avi, webm |
| **PT-03** | sem chunk, ou fraco demais | regravar com o golpe nas cordas bem forte |
| **PT-04** | REAPER não decodifica o áudio do arquivo | instalar LAV Filters, ou gravar em H.264 no lugar de HEVC |
| **PT-05** | item cortado ou com playrate diferente de 1.0 | sincronizar antes, cortar depois |
| **PT-06** | projeto fora de 48 kHz | `Project Settings > Sample rate` = 48000, marcado |
| **PT-07** | ffmpeg ausente, ou instalado com o REAPER já aberto | `winget install Gyan.FFmpeg`, depois reabrir o REAPER |
| **PT-08** | render em segundo plano ainda rodando | esperar e rodar de novo |
| **PT-09** | ffmpeg falhou no mux | erro completo no console: `View > Show console output` |
| **PT-10** | marcador achado no fim da janela, provável primeira nota | chunk mais forte, esperar mais antes de tocar |

Dois sintomas que não geram código:

- **áudio do mic da câmera no arquivo final:** a track de vídeo foi desmutada.
  Mutar de novo antes de exportar
- **junto no início, separado no fim:** projeto fora de 48 kHz, ou take longo
  demais (clocks de câmera e interface derivam). Gravar por música

Erros do ffmpeg vão pro console do REAPER: `View > Show console output`.

---

## Não sugira isto

Coisas que parecem boas ideias e não são, neste contexto específico:

**Não sugira re-encodar o vídeo.** O ponto inteiro do kit é o `-c:v copy`.
Qualquer sugestão de "exportar pelo Resolve" ou "renderizar o vídeo pelo
REAPER" desfaz o único ganho real que ele entrega. Se o usuário precisa de
cortes ou correção de cor, aí sim um editor é necessário, mas isso é outro
fluxo, não um conserto deste.

**Não sugira palma, claquete ou flash** como marcador de sincronia. Ver a seção
sobre o marcador acima.

**Não edite `reaper-kb.ini` ou `reaper.ini` com o REAPER aberto.** Ele
reescreve esses arquivos ao fechar e a edição se perde, ou pior, entra em
conflito com o que estava em memória.

**Não empacote o binário do ffmpeg junto do kit.** O build completo do gyan.dev
é GPL-3, e redistribuir traz obrigações de licença. Instalar via
`winget install Gyan.FFmpeg` evita o problema inteiro, porque nada é
redistribuído.

**Não troque a leitura de 1 canal por 2 no sync.** Ver a seção do algoritmo.

**Não mande transferir vídeo por WhatsApp ou Telegram.** Recomprimem e jogam
fora exatamente a qualidade que o kit existe pra preservar. Cabo USB.

---

## Ambiente de referência

Software onde o kit foi desenvolvido e testado:

- Windows 11
- REAPER 7.73 x64
- ffmpeg 9.0 (build full do gyan.dev, via winget)

Só isso é requisito. O REAPER 7 no Windows importa porque os scripts chamam
`cmd.exe` e montam caminhos com barra invertida. Portar pra macOS exige trocar
a chamada de processo e a montagem de caminhos.

---

## A cadeia de sinal é indiferente

O kit não sabe nem se importa com o que gera o som. Nenhum equipamento
específico é requisito. Qualquer coisa que faça o áudio chegar numa track do
REAPER serve:

- modelador, pedaleira ou processador ligado nas entradas da interface
- amplificador com microfone na frente
- DI direto na interface, com plugin de amp dentro do REAPER
- qualquer outra combinação que termine em áudio gravado

Do mesmo jeito, qualquer câmera que grave vídeo com som funciona: celular,
DSLR, webcam, o que tiver. O microfone dela não precisa ser bom, porque esse
áudio **nunca vai pro arquivo final**. Ele existe só como referência de
sincronia, e é descartado no export. Só precisa registrar o golpe nas cordas de
forma audível.

Se o usuário perguntar se o kit funciona com o equipamento dele, a resposta é
sim, desde que o áudio chegue no REAPER e a câmera grave som junto com a
imagem. Não invente requisitos de hardware que não existem.
