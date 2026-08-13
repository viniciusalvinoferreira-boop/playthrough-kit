# Playthrough Kit

Grave vídeo tocando guitarra sem sincronizar áudio na mão, e sem perder
qualidade na exportação.

Dois scripts pro REAPER: um alinha o vídeo da câmera com o áudio do DAW
sozinho, o outro exporta o vídeo final **sem recodificar a imagem**.

---

## Por que existe

Quem grava playthrough escolhe entre dois caminhos ruins.

**Gravar tudo junto pelo OBS** com o celular como webcam evita sincronizar, mas
o vídeo passa por um app que recomprime, e o que chega no PC é uma sombra do
que o sensor capturou. Nenhuma configuração conserta isso.

**Gravar separado** mantém a qualidade da câmera, mas custa meia hora alinhando
forma de onda no olho, a cada take.

Este kit fica com a qualidade do segundo e a agilidade do primeiro.

## O diferencial

Na hora de exportar, o kit não passa o vídeo por nenhum encoder. Ele usa
`ffmpeg -c:v copy`, que **copia o stream de vídeo bit a bit** e só troca a faixa
de áudio.

O arquivo final é literalmente o vídeo original da câmera com outro som. Dá pra
provar comparando o hash dos dois streams:

```
md5 do vídeo ORIGINAL : 5210348026f6e3a4402fee23708a0208
md5 do vídeo FINAL    : 5210348026f6e3a4402fee23708a0208
```

DaVinci Resolve, Premiere e o render do próprio REAPER recodificam o vídeo.
Aqui ele não é tocado, e não existe "melhor" que não tocar no arquivo.

## Instalação

O jeito recomendado é pelo [ReaPack](https://reapack.com), que instala e
atualiza sozinho. Em `Extensions → ReaPack → Import repositories`, cole:

```
https://raw.githubusercontent.com/viniciusalvinoferreira-boop/playthrough-kit/main/index.xml
```

Depois é `Browse packages`, filtrar por `playthrough` e instalar. As ações já
ficam registradas, sem precisar carregar script na mão.

Sem ReaPack, baixe o repositório e rode o `INSTALAR.bat`.

Em qualquer um dos dois casos você também precisa do ffmpeg:

```
winget install Gyan.FFmpeg
```

## Antes do primeiro take: o golpe nas cordas

É a única coisa que costuma dar errado, e não é bug.

O sync procura **o mesmo som nos dois arquivos**. O vídeo tem o áudio do
microfone da câmera; o REAPER tem o áudio do captador. Pro alinhamento ter em
que se ancorar, o evento precisa existir dos dois lados.

**Palma não serve.** Ela entra no microfone da câmera, mas não passa pelo
captador da guitarra.

**Serve** um golpe seco nas cordas abafadas, aquele "chunk". Ele sai pelo
captador e sai pelo ar ao mesmo tempo.

Ritual de cada take: REC na câmera, REC no REAPER, chunk forte, espera dois
segundos, toca.

## Como usar

1. Abra `File → Project templates → Playthrough`
2. Grave o take, com o chunk no começo
3. Passe o arquivo da câmera pro PC **por cabo** (WhatsApp e Telegram
   recomprimem e jogam fora tudo que você economizou)
4. Arraste o vídeo pra track VIDEO
5. Selecione os **dois** itens e rode o **sync**
6. Selecione **só** o vídeo e rode o **export**

## Documentação

| Arquivo | Pra quê |
|---|---|
| [LEIA-ME.md](LEIA-ME.md) | manual completo e tabela dos códigos de erro |
| [TO COM PROBLEMA.txt](TO%20COM%20PROBLEMA.txt) | roteiro de 4 passos quando algo trava |
| [CONTEXTO-IA.md](CONTEXTO-IA.md) | cole numa IA junto com sua dúvida |
| [CHANGELOG.md](CHANGELOG.md) | o que mudou em cada versão |
| [Teste/](Teste/) | dois arquivos pra validar a instalação sem gravar nada |

Travou em alguma coisa? Rode o script `playthrough_diagnostico`, que escreve um
relatório do seu ambiente, e leve esse relatório junto com o `CONTEXTO-IA.md`
pra qualquer assistente de IA. Essa combinação resolve a maioria dos casos sem
precisar de mais ninguém.

## Requisitos

- REAPER 7, Windows (testado no 7.73)
- ffmpeg
- Qualquer câmera que grave vídeo com som, celular serve
- Qualquer jeito de fazer a guitarra chegar no REAPER: modelador, pedaleira,
  amplificador com microfone, ou DI com plugin. O kit não depende de
  equipamento nenhum em particular

## Apoie

O kit é gratuito e continua sendo. Se ele te economizou tempo, você pode me
pagar um café por Pix:

```
5d7b2734-c80e-48d4-90f8-b7d6e798b6ea
```

Vinicius Alvino. Chave aleatória, sem obrigação nenhuma. Reportar um bug ou
contar que funcionou também ajuda bastante.
