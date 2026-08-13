# Mudanças

## v1.4

Duas falhas encontradas no primeiro take real, com música tocando junto.

**O marcador era procurado do jeito errado**

O script achava o pico da janela e pegava o primeiro ponto acima de 50% dele.
Isso funciona no áudio do captador, onde o golpe inicial é o evento mais alto,
e falha no áudio do microfone da câmera, onde a música é muito mais alta que o
golpe. O golpe não chegava perto dos 50%, e o script marcava um ponto qualquer
no meio da música.

Agora a referência é o **silêncio**, não o pico: o marcador é o primeiro evento
que se levanta muito acima do ruído de fundo da sala. Isso vale mesmo quando a
música depois fica dez vezes mais alta que ele.

O piso de ruído sai do percentil 20 do envelope, e não do mínimo, porque um
único bloco de silêncio digital puxaria o mínimo pra zero e derrubaria o limiar.

**Vídeo que precisava começar antes do zero**

Quem aperta REC na câmera antes de apertar no REAPER (ou seja, todo mundo)
acaba com um vídeo que precisaria ser posicionado em tempo negativo pra
alinhar. O REAPER não aceita isso: ele trava o item em 0 e o alinhamento sai
errado em silêncio.

Agora, quando isso acontece, o vídeo vai pra 0 e todos os outros itens andam
pra frente na mesma medida. O alinhamento entre as tracks de áudio é
preservado, porque todas se movem juntas.

## v1.3

**PT-06 disparava alarme falso**

Os scripts liam `PROJECT_SRATE` e tratavam o valor como se fosse a taxa em que
o áudio estava rodando. Não é.

`PROJECT_SRATE` só tem efeito quando `PROJECT_SRATE_USE` está ligado. Com a
flag desligada, aquele número fica guardado no projeto sem valer nada, e quem
manda é a interface de áudio. Resultado: quem tinha a interface corretamente em
48 kHz e um projeto qualquer aberto levava um PT-06 sem ter problema nenhum.

Agora os três scripts leem a taxa real pelo `GetAudioDeviceInfo("SRATE")` e só
usam a do projeto quando ela está de fato cravada. O relatório mostra as duas
separadas, deixando claro qual está valendo.

A mensagem de conserto também estava errada, mandando pro `Project Settings`
quando o lugar certo é `Preferences > Audio > Device`, marcando a caixa
`Request sample rate`. A caixa é o que importa, não o número ao lado dela.

## v1.2

Correções encontradas no primeiro teste real de instalação via ReaPack.

**Compensação do priming do AAC**

Encoders AAC inserem 1024 samples de silêncio no início do stream, o que dá
21,33 ms a 48 kHz. O REAPER não descarta esse bloco ao entregar o áudio pelo
audio accessor, então o áudio do vídeo chegava ~21 ms atrasado em relação à
imagem, e o alinhamento herdava o erro.

Na prática são menos de um frame a 30 fps, e o erro caía na direção tolerável
(imagem levemente à frente do som). Mas corrigir devolve ao teste embutido a
propriedade de dar um número exato, que é o que faz dele um verificador útil.

Configurável em `VIDEO_AUDIO_OFFSET_MS`, no topo do script de sync.

**Falso "NAO ENCONTRADO" no diagnóstico**

O diagnóstico procurava os scripts num caminho fixo (`Scripts\`), que é onde o
`INSTALAR.bat` põe. Quem instala pelo ReaPack recebe os arquivos numa subpasta
própria dele, e via três "NAO ENCONTRADO" mesmo com tudo funcionando.

Agora o script pergunta onde ele mesmo está e procura os irmãos ali do lado, o
que funciona nos dois modos de instalação.

**Outros**

- `GetAppVersion()` devolve um valor só. O relatório mostrava um `nil` ao lado
  da versão do REAPER
- O relatório agora aponta a URL do repositório, porque quem instala pelo
  ReaPack não recebe o `CONTEXTO-IA.md`, o `LEIA-ME.md` nem a pasta `Teste/`

## v1.1

Foco em self-service: reduzir o número de casos que precisam de ajuda humana.

**Novo**

- `playthrough_diagnostico.lua`: relatório de ambiente que não altera nada no
  projeto. Checa REAPER, ffmpeg, sample rate, e analisa os itens selecionados
- Pasta `Teste/` com dois arquivos de deslocamento conhecido (3 segundos), pra
  validar a instalação sem precisar gravar
- `TO COM PROBLEMA.txt`: roteiro de 4 passos, do mais barato ao mais caro
- Códigos de erro `[PT-xx]` em todas as mensagens, mapeados numa tabela do
  LEIA-ME

**Motivo dos códigos**

"Não funcionou" não é reportável. "Deu PT-03" é. A pessoa procura o código,
acha a causa, e resolve sozinha na maioria das vezes.

**Motivo dos arquivos de teste**

Separa instalação quebrada de gravação errada antes que a pessoa se frustre.
Se o teste dá +3000 ms, a instalação está boa e o problema está no take.

## v1.0

Versão inicial.

- `playthrough_sync_video.lua`: alinha vídeo e áudio pelo transiente
- `playthrough_export_mux.lua`: renderiza e junta sem re-encodar o vídeo
- Template de projeto
- `LEIA-ME.md` e `CONTEXTO-IA.md`
- `INSTALAR.bat`
