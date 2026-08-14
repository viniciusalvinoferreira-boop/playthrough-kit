*[Manual in English](MANUAL-en.md)*

# Playthrough Kit v1.7

Gravar vídeo tocando guitarra sem sincronizar áudio na mão, e sem perder
qualidade na exportação.

Funciona no **REAPER 7 / Windows**.

---

## O problema

Quem grava playthrough normalmente escolhe entre dois caminhos ruins:

**Caminho 1, OBS.** Você joga o celular como webcam, grava tudo junto e não
precisa sincronizar. Só que o celular passa por um app de webcam que recomprime
o vídeo, e o que chega no PC é uma sombra do que o sensor capturou. Não existe
configuração de OBS que conserte isso, é um teto do caminho.

**Caminho 2, gravar separado.** A câmera grava em qualidade cheia, o REAPER
grava o áudio bom, e aí você passa meia hora alinhando forma de onda no olho,
por take.

Este kit fica com a qualidade do caminho 2 e a agilidade do caminho 1.

---

## O que ele faz

**1. Sincroniza sozinho.** Um script acha o mesmo transiente nos dois arquivos
e move o vídeo pra posição certa. Leva um segundo.

**2. Exporta sem re-encodar o vídeo.** Aqui está a parte que importa. O script
renderiza só o áudio e usa o ffmpeg em modo `-c:v copy`, que copia o stream de
vídeo **bit a bit**, sem decodificar nem recodificar.

O arquivo final é literalmente o vídeo original da câmera com outra faixa de
áudio. Não é "quase igual", é idêntico: dá pra comparar o hash dos dois streams
e eles batem. Resolve, Premiere e o próprio render do REAPER todos recomprimem
o vídeo. Não tem como ficar melhor que não tocar nele.

---

## Requisitos

- REAPER 7 (testado no 7.73), Windows
- ffmpeg (o instalador oferece instalar pra você)
- Uma câmera qualquer que grave vídeo com áudio, celular serve
- Qualquer jeito de fazer a guitarra chegar no REAPER: modelador, pedaleira,
  amp com microfone na frente, ou DI com plugin de amp. O kit não depende de
  equipamento nenhum em particular

O áudio da câmera não precisa ser bom. Ele serve só como referência de
sincronia e é descartado no export, nunca entra no arquivo final.

---

## Instalação

Rode o **INSTALAR.bat**. Ele copia os arquivos e oferece instalar o ffmpeg.
Mexe só em duas pastas dentro de `%APPDATA%\REAPER`, nada além disso.

Depois, dentro do REAPER, registre os dois scripts:

1. `Actions` → `Show action list`
2. `New action` → `Load ReaScript...`
3. Escolha os três arquivos em `%APPDATA%\REAPER\Scripts\`:
   - `playthrough_sync_video.lua`
   - `playthrough_export_mux.lua`
   - `playthrough_diagnostico.lua`

Vale colocar atalho nos dois primeiros (na mesma janela, `Add shortcut`).
Sugestão: `Shift+S` pro sync, `Shift+E` pro export.

O template já aparece sozinho em `File` → `Project templates` → `Playthrough`.

## Idioma das mensagens

Na primeira vez que você rodar qualquer script do kit, ele pergunta se você
quer as mensagens em português ou inglês, e guarda a resposta.

Pra trocar depois, rode a ação **`Playthrough Kit: idioma`**.

A escolha fica guardada na configuração do REAPER, e não dentro dos scripts.
Isso importa porque o ReaPack sobrescreve os arquivos ao atualizar: se o idioma
morasse no código, sua preferência seria apagada em toda nova versão.

Os códigos de erro são idênticos nos dois idiomas, então `PT-03` significa a
mesma coisa de qualquer jeito.

---

## Teste a instalação sem gravar nada

Antes do primeiro take de verdade, gaste dois minutos aqui. Isso separa
"instalei errado" de "gravei errado", que são problemas bem diferentes.

Na pasta `Teste/` tem dois arquivos com um deslocamento **conhecido** de
3 segundos entre eles.

1. Arraste `TESTE_video.mp4` e `TESTE_guitarra.wav` pro REAPER
2. Deixe os dois começando na posição **0**
3. Selecione os dois
4. Rode o `playthrough_sync_video`

O console tem que mostrar:

```
video deslocado      : +3000.0 ms
```

Uma variação de 1 ou 2 ms pra mais ou pra menos é normal. O que não pode é dar
um número longe disso.

**Deu 3000:** instalação redonda. Se der problema depois, é na gravação, e
quase sempre é o golpe nas cordas.

**Não deu:** o problema é de instalação ou ambiente. Rode o
`playthrough_diagnostico` e leia o `TO COM PROBLEMA.txt`.

---

## LEIA ISTO: o golpe nas cordas

É a única coisa que costuma dar errado, e não é bug.

Pro sync funcionar, precisa existir **um evento que apareça nos dois sinais ao
mesmo tempo**. O vídeo tem o áudio do mic da câmera. O REAPER tem o áudio do
captador. O script procura o mesmo transiente nos dois.

**Palma não funciona.** A palma entra no mic da câmera, mas não passa pelo
captador da guitarra. Do lado do REAPER não existe nada pra casar.

**O que funciona:** um golpe seco nas cordas abafadas, aquele "chunk". Ele sai
pelo captador (entra no REAPER) e sai acusticamente pelo ar (o mic da câmera
pega). É o único evento que existe nos dois mundos.

Então o ritual de cada take é:

1. REC na câmera
2. REC no REAPER
3. **Chunk**, forte
4. Espera 1 ou 2 segundos
5. Toca

A ordem dos dois primeiros não importa. Se você apertar REC no REAPER depois
da câmera, o vídeo precisaria começar antes do zero da timeline, e o script
resolve isso empurrando os outros itens pra frente. Alinha igual nos dois
casos.

Dê o chunk **logo no início**, nos primeiros segundos. O script procura o
marcador nos primeiros 12 segundos, e quanto mais silêncio houver antes da
música entrar, mais fácil pra ele distinguir o golpe do resto.

---

## Fluxo de trabalho

1. `File` → `Project templates` → `Playthrough`
2. Grave o take (com o chunk no começo)
3. Passe o arquivo da câmera pro PC **por cabo**. Nunca por WhatsApp ou
   Telegram, que recomprimem e jogam fora tudo que você economizou
4. Arraste o arquivo pra track VIDEO
5. Selecione os **dois** itens (vídeo e guitarra) e rode o **sync**
6. Selecione **só** o item de vídeo e rode o **export**

Sai um arquivo `nome_final.mp4` na mesma pasta do vídeo original.

---

## Ajustando pra sua interface

O template vem com a guitarra na **entrada 1/2 em estéreo**, que é o caso mais
comum. Se a sua chega em outras entradas, clique no botão de armar da track e
escolha a entrada certa. Salve como template seu depois, em
`File` → `Project templates` → `Save as project template`.

Se o seu processador é mono (sem delay ou reverb estéreo), use entrada mono e
economize metade do arquivo.

---

## Configuração obrigatória: 48 kHz

Vídeo é sempre 48 kHz. Se o seu projeto ou a sua interface estiverem em 44,1
kHz, o REAPER vai resamplar em silêncio e takes longos podem derivar.

`Options` → `Preferences` → `Audio` → `Device`: **marque a caixa**
`Request sample rate` e deixe **48000** dentro dela. Depois **reinicie o
REAPER**, porque trocar de taxa exige reabrir o driver.

A caixa marcada é o que importa, não o número. Digitar 48000 e deixar a caixa
desmarcada não faz nada: o REAPER continua aceitando a taxa que a interface
estiver usando, e o número fica ali só enfeitando.

Os scripts avisam se o áudio estiver rodando fora de 48 kHz.

---

## Problemas comuns

Toda mensagem de erro do kit vem com um código entre colchetes, tipo `[PT-03]`.
Procure o código aqui:

| Código | O que aconteceu | Causa | Conserto |
|---|---|---|---|
| **PT-01** | Seleção errada | Número de itens selecionados não bate | Sync quer 2 itens (vídeo e guitarra). Export quer 1 (só o vídeo) |
| **PT-02** | Não identifiquei vídeo e áudio | Os dois são vídeo, nenhum é, ou a extensão não é reconhecida | Extensões válidas: mp4, mov, m4v, mkv, avi, webm |
| **PT-03** | Não achei o transiente | Não teve chunk, ou foi fraco demais | Regrave com o golpe nas cordas bem forte no início |
| **PT-04** | Áudio silencioso ou não decodifica | O REAPER não consegue ler o áudio desse arquivo | Instale o LAV Filters, ou grave em H.264 em vez de HEVC |
| **PT-05** | Item cortado ou com playrate alterado | O cálculo assume item inteiro e velocidade normal | Sincronize primeiro, corte depois |
| **PT-06** | Áudio rodando fora de 48 kHz | Vídeo é sempre 48 kHz | `Preferences` → `Audio` → `Device`: **marque** `Request sample rate` com 48000, e reinicie o REAPER |
| **PT-07** | Não encontrei o ffmpeg | Não instalado, ou instalado com o REAPER já aberto | `winget install Gyan.FFmpeg`, depois feche e reabra o REAPER |
| **PT-08** | O render não gerou o WAV | Render em segundo plano ligado | Espere terminar e rode de novo |
| **PT-09** | O ffmpeg falhou no mux | Vários motivos | O erro completo vai pro console: `View` → `Show console output` |
| **PT-10** | Marcador suspeito | Achado no fim da janela de busca, pode ser a primeira nota em vez do chunk | Confira de ouvido. Dê o chunk mais forte e espere mais antes de tocar |

Um sintoma que não gera código: **áudio e vídeo juntos no início e separados no
fim**. Isso é sample rate fora de 48 kHz, ou take longo demais (clock da câmera
e da interface derivam). Grave por música, não por sessão inteira.

Travou em algo que não está aqui? Abra o **TO COM PROBLEMA.txt**, que tem o
roteiro completo, incluindo como pedir ajuda pra uma IA de forma que funcione.

---

## Está usando alguma IA pra te ajudar?

Tem um arquivo **CONTEXTO-IA.md** aqui do lado. Ele explica a arquitetura, os
valores mágicos e os modos de falha conhecidos deste kit.

Cole o conteúdo dele no ChatGPT, Claude ou no que você usar, junto com a sua
dúvida. A IA vai entender o que cada peça faz em vez de chutar, porque as
partes menos óbvias (por que o marcador precisa ser o chunk, por que o script
procura o ffmpeg em vez de só chamar) estão documentadas lá.

---

## Notas

O ffmpeg **não** vem dentro deste pacote, de propósito. O instalador chama o
winget e o binário vem direto da fonte. Assim ninguém está redistribuindo
software de terceiro, e você recebe as atualizações normalmente.

Os scripts são código aberto e comentados. Mexa à vontade, os parâmetros de
ajuste estão todos no topo de cada arquivo.
